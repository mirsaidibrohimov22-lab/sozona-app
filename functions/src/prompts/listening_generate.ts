// functions/src/prompts/listening_generate.ts
// ✅ v3.0: CEFR validatsiya + avtomatik retry (max 2 marta) qo'shildi

import { aiRouter } from '../ai/ai_router';
import { safeParseJson } from '../ai/gemini_client';
import { buildLevelBlock, type CEFRLevel } from './cefr_level_guide';
import { validateListeningLevel, buildRetryNote } from './cefr_validator';

const WPM_BY_LEVEL: Record<CEFRLevel, number> = { A1: 80, A2: 100, B1: 120, B2: 140, C1: 160 };
const MAX_WORDS_BY_LEVEL: Record<CEFRLevel, number> = { A1: 65, A2: 105, B1: 165, B2: 255, C1: 385 };

function buildPrompt(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    maxWords: number;
    questionCount: number;
    grammar: string;
    retryNote?: string;
}): string {
    const { language, level, topic, maxWords, questionCount, grammar, retryNote } = params;
    const languageName = language === 'en' ? 'English' : 'German';
    const levelBlock = buildLevelBlock(level, language);
    const grammarNote = grammar
        ? `\nGrammar to demonstrate: "${grammar}" — use it naturally at least 3 times.`
        : '';
    const retryBlock = retryNote ? `\n\n${retryNote}` : '';

    return `You are creating a ${languageName} listening comprehension exercise.

${levelBlock}

Topic: "${topic}"
Transcript length: EXACTLY around ${maxWords} words (count words carefully)
Questions: ${questionCount}${grammarNote}${retryBlock}

CRITICAL: Every single word in the transcript MUST be within ${level} vocabulary.
Check each word before using it. Dialogue speakers: use simple names (Maria/Tom or Hans/Anna).

Return ONLY valid JSON — no markdown, no backticks:
{
  "title": "Max 4 word title",
  "description": "One simple sentence",
  "transcript": "Maria: Hello!\\nTom: Hi!\\n...",
  "questions": [
    {
      "id": "lq1",
      "question": "Question in ${languageName}?",
      "options": ["A","B","C","D"],
      "correctAnswer": "A",
      "explanation": "From the conversation...",
      "timestamp": 0
    }
  ]
}

Rules:
- Each speaker turn: max ${level === 'A1' ? '1 sentence, 5 words' : level === 'A2' ? '1-2 sentences' : '2-3 sentences'}
- All questions, options, explanations in ${languageName}
- Correct answers must be explicitly stated in the dialogue (no inference for A1/A2)
- Exactly ${questionCount} questions`;
}

export async function generateListening(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    duration?: number;
    questionCount?: number;
    grammar?: string;
    userId?: string;
}): Promise<unknown> {
    const {
        language, level, topic,
        duration = 60, questionCount = 5, grammar = '', userId,
    } = params;

    const wpm = WPM_BY_LEVEL[level];
    const targetWords = Math.floor((duration / 60) * wpm);
    const maxWords = Math.min(targetWords, MAX_WORDS_BY_LEVEL[level]);

    const MAX_RETRIES = 2;
    let lastValidation = null;
    let finalData: Record<string, unknown> = {};
    let cleanQuestions: Record<string, unknown>[] = [];
    let transcript = '';

    // ── Retry loop ──────────────────────────────────────────────
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
        const retryNote = attempt > 0 && lastValidation
            ? buildRetryNote(lastValidation, level)
            : undefined;

        const prompt = buildPrompt({ language, level, topic, maxWords, questionCount, grammar, retryNote });

        const response = await aiRouter({ prompt, maxTokens: 8192, temperature: 0.75, schema: null });
        const data = safeParseJson(response.text || '{}') as Record<string, unknown>;

        transcript = String(data?.['transcript'] || '');
        const questions = data?.['questions'];

        if (!transcript || transcript.length < 30 || !Array.isArray(questions) || questions.length === 0) {
            if (attempt === MAX_RETRIES) throw new Error('AI transcript yoki questions qaytarmadi');
            continue;
        }

        cleanQuestions = (questions as Record<string, unknown>[]).map((q, i) => ({
            id: (q['id'] as string) || `lq${i + 1}`,
            question: (q['question'] as string) || '',
            options: Array.isArray(q['options']) ? q['options'] as string[] : [],
            correctAnswer: (q['correctAnswer'] as string) || '',
            explanation: (q['explanation'] as string) || '',
            timestamp: (q['timestamp'] as number) || 0,
        }));

        finalData = data;

        // ── CEFR validatsiya ────────────────────────────────────
        lastValidation = validateListeningLevel(transcript, cleanQuestions, level);
        console.log(`📊 Listening validatsiya (urinish ${attempt + 1}): ${lastValidation.summary}`);

        if (lastValidation.isValid || lastValidation.score >= 70) break;

        if (attempt === MAX_RETRIES) {
            console.warn(`⚠️ Listening ${MAX_RETRIES} urinishdan keyin ham xato: score=${lastValidation.score}`);
            console.warn('Xatolar:', lastValidation.issues.map(i => i.message).join(' | '));
        }
    }

    const wordCount = transcript.split(/\s+/).length;
    const estimatedDuration = Math.max(Math.round((wordCount / wpm) * 60), 20);

    // ── Firestore ga saqlash ────────────────────────────────────
    if (userId !== undefined) {
        try {
            const admin = await import('firebase-admin');
            const db = admin.default.firestore();
            await db.collection('listening_exercises').add({
                title: (finalData['title'] as string) || `${topic} — Listening`,
                description: (finalData['description'] as string) || `${level} listening: ${topic}`,
                audioUrl: '', useTts: true, transcript,
                duration: estimatedDuration, language, level, topic, grammar,
                isActive: true, isTeacherCreated: false,
                createdBy: userId || 'ai',
                questions: cleanQuestions,
                cefrScore: lastValidation?.score ?? 100,
                createdAt: admin.default.firestore.FieldValue.serverTimestamp(),
            });
        } catch (e) { console.warn('⚠️ Firestore saqlash xatosi:', e); }
    }

    return {
        title: (finalData['title'] as string) || `${topic} — Listening`,
        description: (finalData['description'] as string) || `${level} listening: ${topic}`,
        transcript,
        audioDuration: estimatedDuration,
        questions: cleanQuestions,
        metadata: { language, level, topic, grammar, wordCount, estimatedDuration, generatedAt: new Date().toISOString() },
        audioUrl: null,
        useTts: true,
        cefrValidation: lastValidation ? { score: lastValidation.score, summary: lastValidation.summary } : null,
    };
}