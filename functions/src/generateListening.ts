// functions/src/generateListening.ts
// SO'ZONA — Listening mashq yaratish Cloud Function
// ✅ FIX: Gemini ```json...``` markdown fences olib tashlanadi
// ✅ YANGI: grammar, topic, level, duration, questionCount parametrlari
// ✅ YANGI: Suhbat formati — do'stlar, uchrashuv, har xil scenario

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';

// ─── Gemini API ───
function getGenAI(): GoogleGenerativeAI {
    const key =
        process.env.GEMINI_API_KEY ||
        (functions.config().gemini && functions.config().gemini.key) ||
        '';
    if (!key) throw new Error('GEMINI_API_KEY konfiguratsiyasi topilmadi');
    return new GoogleGenerativeAI(key);
}

// ─── ASOSIY FIX: Gemini markdown tozalash ───
function cleanJsonResponse(text: string): string {
    let s = text.trim();
    if (s.startsWith('```json')) s = s.slice(7);
    else if (s.startsWith('```')) s = s.slice(3);
    if (s.endsWith('```')) s = s.slice(0, -3);
    return s.trim();
}

function safeParseJson(text: string): Record<string, unknown> {
    try {
        return JSON.parse(cleanJsonResponse(text)) as Record<string, unknown>;
    } catch {
        const match = text.match(/\{[\s\S]*\}/);
        if (match) {
            try {
                return JSON.parse(match[0]) as Record<string, unknown>;
            } catch {
                // davom etadi
            }
        }
        throw new Error('AI javobidan JSON ajratib olish imkonsiz');
    }
}

// ─── Listening prompt ───
function buildListeningPrompt(params: {
    langName: string;
    level: string;
    topic: string;
    grammar: string;
    questionCount: number;
    duration: number;
}): string {
    const { langName, level, topic, grammar, questionCount, duration } = params;
    const durationMinutes = Math.ceil(duration / 60);
    const grammarNote = grammar
        ? `\nThe conversation should naturally demonstrate: ${grammar}`
        : '';
    const wordCount = durationMinutes * 100; // taxminiy so'z soni

    return `You are creating a ${langName} listening comprehension exercise for ${level} level learners.
Topic: "${topic}"${grammarNote}

Create a realistic conversation (about ${wordCount} words, ${durationMinutes} minute audio).
The conversation should be between 2-3 people in a natural, everyday situation.

Then create ${questionCount} multiple-choice questions testing comprehension.
Questions should include distractors (plausible but wrong options).

CRITICAL: Return ONLY a valid JSON object. No markdown, no code blocks.

Required format:
{
  "title": "Descriptive title of the conversation",
  "description": "One sentence describing the situation",
  "scenario": "Brief setup: who is talking, where, why",
  "transcript": "Full conversation text here. Person A: Hello! ... Person B: Hi! ...",
  "duration": ${duration},
  "questions": [
    {
      "id": "lq1",
      "question": "Comprehension question about the audio?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option A",
      "explanation": "According to the conversation...",
      "timeToAnswer": 20
    }
  ],
  "metadata": {
    "level": "${level}",
    "topic": "${topic}",
    "grammar": "${grammar || ''}",
    "speakerCount": 2,
    "scenarioType": "conversation"
  }
}

Make questions genuinely challenging with misleading distractors.
Example question types:
- "Where does Person A suggest going?"
- "Why did Person B decline the invitation?"
- "What time did they agree to meet?"
- "What is Person A's opinion about...?"`;
}

// ─── Cloud Function ───
export const generateListening = functions
    .runWith({ timeoutSeconds: 90, memory: '512MB' })
    .https.onCall(async (data: Record<string, unknown>) => {
        const language = (data['language'] as string) || 'en';
        const level = (data['level'] as string) || 'A1';
        const topic = (data['topic'] as string) || 'Daily Life';
        const grammar = (data['grammar'] as string) || '';
        const questionCount = Math.min(
            Math.max((data['questionCount'] as number) || 5, 2),
            10,
        );
        const duration = Math.min(
            Math.max((data['duration'] as number) || 60, 30),
            300,
        );
        const userId = data['userId'] as string;

        const langName = language === 'de' ? 'German' : 'English';

        console.log(
            `🎧 Listening yaratish: ${langName} | ${level} | ${topic} | ${questionCount} savol | ${duration}s`,
        );

        try {
            const genAI = getGenAI();
            const model = genAI.getGenerativeModel({
                model: 'gemini-1.5-flash',
                generationConfig: {
                    temperature: 0.8,
                    topP: 0.9,
                    maxOutputTokens: 8192,
                },
            });

            const prompt = buildListeningPrompt({
                langName,
                level,
                topic,
                grammar,
                questionCount,
                duration,
            });

            const result = await model.generateContent(prompt);
            const rawText = result.response.text();

            console.log(
                '🤖 Gemini raw response (first 200 chars):',
                rawText.slice(0, 200),
            );

            // ✅ ASOSIY FIX: JSON tozalash
            const parsed = safeParseJson(rawText);

            // Validatsiya
            const transcript = parsed['transcript'] as string;
            const questions = parsed['questions'];

            if (!transcript || typeof transcript !== 'string') {
                throw new Error("AI 'transcript' qaytarmadi");
            }
            if (!questions || !Array.isArray(questions) || questions.length === 0) {
                throw new Error("AI 'questions' qaytarmadi");
            }

            // So'z soniga qarab davomiylikni hisoblash (taxminiy)
            const wordCount = transcript.split(/\s+/).length;
            const estimatedDuration = Math.max(
                Math.round((wordCount / 130) * 60), // 130 so'z/daqiqa o'rtacha
                30,
            );

            // Questions ni tozalash
            const cleanQuestions = (questions as Record<string, unknown>[]).map(
                (q, i) => ({
                    id: (q['id'] as string) || `lq${i + 1}`,
                    question: (q['question'] as string) || '',
                    options: Array.isArray(q['options'])
                        ? (q['options'] as string[])
                        : [],
                    correctAnswer: (q['correctAnswer'] as string) || '',
                    explanation: (q['explanation'] as string) || '',
                    timeToAnswer: (q['timeToAnswer'] as number) || 20,
                }),
            );

            const exerciseData = {
                title:
                    (parsed['title'] as string) ||
                    `${topic} — Listening Exercise`,
                description:
                    (parsed['description'] as string) ||
                    `${level} darajasida ${topic} mavzusida listening mashq`,
                scenario: (parsed['scenario'] as string) || '',
                transcript,
                duration: estimatedDuration,
                language,
                level,
                topic,
                grammar,
                questions: cleanQuestions,
                metadata: parsed['metadata'] || {
                    level,
                    topic,
                    grammar,
                    speakerCount: 2,
                    scenarioType: 'conversation',
                },
            };

            // Firestore ga saqlash
            if (userId !== undefined) {
                try {
                    const db = admin.firestore();
                    await db.collection('listening_exercises').add({
                        title: exerciseData.title,
                        description: exerciseData.description,
                        audioUrl: '',
                        useTts: true,
                        transcript: exerciseData.transcript,
                        duration: exerciseData.duration,
                        language,
                        level,
                        topic,
                        grammar,
                        isActive: true,
                        isTeacherCreated: false,
                        createdBy: userId || 'ai',
                        questions: cleanQuestions,
                        scenario: exerciseData.scenario,
                        metadata: exerciseData.metadata,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log('✅ Listening Firestore ga saqlandi');
                } catch (saveError) {
                    console.warn('⚠️ Firestore saqlash xatosi:', saveError);
                }
            }

            console.log(
                `✅ Listening yaratildi: ${cleanQuestions.length} savol | ${estimatedDuration}s`,
            );
            return exerciseData;
        } catch (error: unknown) {
            const msg = error instanceof Error ? error.message : String(error);
            console.error('❌ generateListening xatosi:', msg);
            throw new functions.https.HttpsError(
                'internal',
                `Listening yaratishda xatolik: ${msg}`,
            );
        }
    });
