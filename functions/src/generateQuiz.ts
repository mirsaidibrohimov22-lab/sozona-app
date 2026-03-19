// functions/src/generateQuiz.ts
// SO'ZONA — Quiz yaratish Cloud Function
// ✅ FIX: Gemini ```json...``` markdown fences olib tashlanadi
// ✅ YANGI: grammar, topic, level, questionCount parametrlari qo'llab-quvvatlanadi
// ✅ YANGI: AI quiz saqlanadi va ro'yxatda ko'rinadi

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Admin SDK allaqachon main index.ts da initialize qilingan bo'lishi kerak
// Agar standalone ishlatilsa:
// if (!admin.apps.length) admin.initializeApp();

// ─── Gemini API ───
function getGenAI(): GoogleGenerativeAI {
    const key =
        process.env.GEMINI_API_KEY ||
        (functions.config().gemini && functions.config().gemini.key) ||
        '';
    if (!key) throw new Error('GEMINI_API_KEY konfiguratsiyasi topilmadi');
    return new GoogleGenerativeAI(key);
}

// ─── ASOSIY FIX: Gemini markdown ```json ... ``` ni tozalash ───
function cleanJsonResponse(text: string): string {
    let s = text.trim();
    // ```json yoki ``` boshida bo'lsa olib tashlash
    if (s.startsWith('```json')) {
        s = s.slice(7);
    } else if (s.startsWith('```')) {
        s = s.slice(3);
    }
    // ``` oxirida bo'lsa olib tashlash
    if (s.endsWith('```')) {
        s = s.slice(0, -3);
    }
    return s.trim();
}

// ─── JSON ni xavfsiz parse qilish ───
function safeParseJson(text: string): Record<string, unknown> {
    // 1-urinish: to'g'ridan-to'g'ri clean + parse
    try {
        return JSON.parse(cleanJsonResponse(text)) as Record<string, unknown>;
    } catch {
        // 2-urinish: matndagi JSON bloklarni qidirish
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

// ─── Quiz prompt yaratish ───
function buildQuizPrompt(params: {
    langName: string;
    level: string;
    topic: string;
    grammar: string;
    questionCount: number;
}): string {
    const { langName, level, topic, grammar, questionCount } = params;
    const grammarNote = grammar
        ? `\nGrammar focus: "${grammar}" grammar rules and patterns.`
        : '';
    const topicNote = topic ? `Topic: "${topic}"` : 'Topic: Daily Life';

    return `You are an expert ${langName} language teacher creating a quiz for language learners.
Level: ${level} (CEFR)
${topicNote}${grammarNote}

Create exactly ${questionCount} multiple choice questions suitable for ${level} level learners.
Each question must have exactly 4 options with one correct answer.

CRITICAL: Return ONLY a valid JSON object. No markdown, no code blocks, no explanations.

Required format:
{
  "title": "Short quiz title related to topic",
  "topic": "${topic || 'Daily Life'}",
  "grammar": "${grammar || ''}",
  "questions": [
    {
      "id": "q1",
      "question": "What is the correct form of...?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option A",
      "explanation": "Option A is correct because...",
      "points": 10,
      "timeLimit": 30
    }
  ],
  "totalPoints": ${questionCount * 10},
  "passingScore": ${Math.round(questionCount * 6)}
}`;
}

// ─── Cloud Function export ───
export const generateQuiz = functions
    .runWith({ timeoutSeconds: 60, memory: '512MB' })
    .https.onCall(async (data: Record<string, unknown>) => {
        const language = (data['language'] as string) || 'en';
        const level = (data['level'] as string) || 'A1';
        const topic = (data['topic'] as string) || 'Daily Life';
        const grammar = (data['grammar'] as string) || '';
        const questionCount = Math.min(
            Math.max((data['questionCount'] as number) || 10, 3),
            20,
        );
        const userId = data['userId'] as string;
        const saveToFirestore = (data['save'] as boolean) ?? true;

        const langName = language === 'de' ? 'German' : 'English';

        console.log(
            `📝 Quiz yaratish: ${langName} | ${level} | ${topic} | ${questionCount} savol`,
        );

        try {
            const genAI = getGenAI();
            const model = genAI.getGenerativeModel({
                model: 'gemini-1.5-flash',
                generationConfig: {
                    temperature: 0.7,
                    topP: 0.9,
                    maxOutputTokens: 4096,
                },
            });

            const prompt = buildQuizPrompt({
                langName,
                level,
                topic,
                grammar,
                questionCount,
            });

            const result = await model.generateContent(prompt);
            const rawText = result.response.text();

            console.log('🤖 Gemini raw response (first 200 chars):', rawText.slice(0, 200));

            // ✅ ASOSIY FIX: JSON ni tozalab parse qilish
            const parsed = safeParseJson(rawText);

            // Validatsiya
            const questions = parsed['questions'];
            if (!questions || !Array.isArray(questions) || questions.length === 0) {
                throw new Error(`AI noto'g'ri format qaytardi. questions yo'q.`);
            }

            // ID va timeLimit ni to'ldirish
            const cleanQuestions = (questions as Record<string, unknown>[]).map(
                (q, i) => ({
                    id: (q['id'] as string) || `q${i + 1}`,
                    question: (q['question'] as string) || '',
                    options: Array.isArray(q['options']) ? q['options'] : [],
                    correctAnswer: (q['correctAnswer'] as string) || '',
                    explanation: (q['explanation'] as string) || '',
                    points: (q['points'] as number) || 10,
                    timeLimit: (q['timeLimit'] as number) || 30,
                }),
            );

            const quizData = {
                title: (parsed['title'] as string) || `${topic} Quiz`,
                topic,
                grammar,
                questions: cleanQuestions,
                totalPoints: questionCount * 10,
                passingScore: Math.round(questionCount * 6),
                language,
                level,
            };

            // Firestore ga saqlash (ixtiyoriy)
            if (saveToFirestore && userId) {
                try {
                    const db = admin.firestore();
                    await db.collection('content').add({
                        type: 'quiz',
                        title: quizData.title,
                        language,
                        level,
                        topic,
                        grammar,
                        creatorId: userId,
                        creatorType: 'student',
                        isPublished: false,
                        generatedByAi: true,
                        attemptCount: 0,
                        averageScore: 0,
                        tags: [topic, grammar, level].filter(Boolean),
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        data: {
                            questions: cleanQuestions,
                            totalPoints: quizData.totalPoints,
                            passingScore: quizData.passingScore,
                        },
                    });
                    console.log('✅ Quiz Firestore ga saqlandi');
                } catch (saveError) {
                    // Saqlash xatosi butun operatsiyani buzmaydi
                    console.warn('⚠️ Firestore ga saqlash imkonsiz:', saveError);
                }
            }

            console.log(`✅ Quiz yaratildi: ${cleanQuestions.length} savol`);
            return quizData;
        } catch (error: unknown) {
            const msg = error instanceof Error ? error.message : String(error);
            console.error('❌ generateQuiz xatosi:', msg);
            throw new functions.https.HttpsError(
                'internal',
                `Quiz yaratishda xatolik: ${msg}`,
            );
        }
    });
