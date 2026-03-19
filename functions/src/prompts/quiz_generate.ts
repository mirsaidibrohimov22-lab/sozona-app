// functions/src/prompts/quiz_generate.ts
// ✅ v3.0: CEFR validatsiya + avtomatik retry (max 2 marta) qo'shildi

import { aiRouter } from '../ai/ai_router';
import { safeParseJson } from '../ai/gemini_client';
import { buildLevelBlock, type CEFRLevel } from './cefr_level_guide';
import { validateQuizLevel, buildRetryNote } from './cefr_validator';

type Difficulty = 'easy' | 'medium' | 'hard';

function buildDifficultyNote(difficulty: Difficulty, level: CEFRLevel): string {
    const notes: Record<Difficulty, Record<CEFRLevel, string>> = {
        easy: {
            A1: 'Make questions extremely obvious — single word answers only.',
            A2: 'Use only the most common everyday words. Avoid ambiguity.',
            B1: 'Straightforward factual questions. No inference required.',
            B2: 'Direct comprehension questions. Answer clearly in the text.',
            C1: 'Explicit information questions. Avoid very subtle nuance.',
        },
        medium: {
            A1: 'Mix yes/no and single-choice. One correct answer must be very clear.',
            A2: '1-2 simple inference questions. Distractors clearly wrong.',
            B1: 'Balance factual and inference. Plausible distractors.',
            B2: 'Include attitude/opinion questions. Careful reading needed.',
            C1: 'Mix explicit and implicit meaning questions.',
        },
        hard: {
            A1: 'All question types — but vocabulary MUST stay strictly A1.',
            A2: 'Add some inference. Distractors differ by one small detail.',
            B1: 'Majority inference. Distractors very plausible.',
            B2: 'Focus on implicit meaning. Subtle distractors.',
            C1: 'Evaluation and critical analysis.',
        },
    };
    return notes[difficulty]?.[level] ?? '';
}

function buildPrompt(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    questionCount: number;
    difficulty: Difficulty;
    grammar: string;
    weakItems: string[];
    retryNote?: string;
}): string {
    const { language, level, topic, questionCount, difficulty, grammar, weakItems, retryNote } = params;
    const languageName = language === 'en' ? 'English' : 'German';
    const levelBlock = buildLevelBlock(level, language);
    const difficultyNote = buildDifficultyNote(difficulty, level);
    const grammarNote = grammar
        ? `\nGrammar focus: "${grammar}" — at least 60% of questions must test this.`
        : '';
    const weakNote = weakItems.length > 0
        ? `\nFocus on student weak areas: ${weakItems.slice(0, 5).join(', ')}`
        : '';
    const retryBlock = retryNote ? `\n\n${retryNote}` : '';

    return `You are an expert ${languageName} language teacher creating a quiz.

${levelBlock}

Topic: "${topic}"
Number of questions: ${questionCount}
Difficulty: ${difficulty} — ${difficultyNote}${grammarNote}${weakNote}${retryBlock}

CRITICAL: Every question, option and explanation MUST strictly follow the ${level} level rules above.
Before writing each question ask yourself: "Is every word here within ${level} vocabulary?"

Return ONLY valid JSON — no markdown, no backticks:
{
  "questions": [
    {
      "id": "q1",
      "type": "mcq",
      "question": "Question in ${languageName}?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": "A",
      "explanation": "Brief explanation in ${languageName}",
      "points": 10,
      "timeLimit": 30
    }
  ]
}

Rules:
- mcq: exactly 4 options
- true_false: options ["True","False"]
- fill_blank: options=[], use ___ for blank
- All text in ${languageName}`;
}

export async function generateQuiz(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    questionCount: number;
    difficulty?: Difficulty;
    grammar?: string;
    weakItems?: string[];
    userId?: string;
}): Promise<unknown> {
    const {
        language, level, topic, questionCount,
        difficulty = 'medium', grammar = '', weakItems = [], userId,
    } = params;

    const MAX_RETRIES = 2;
    let lastValidation = null;
    let cleanQuestions: Record<string, unknown>[] = [];

    // ── Retry loop ──────────────────────────────────────────────
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
        const retryNote = attempt > 0 && lastValidation
            ? buildRetryNote(lastValidation, level)
            : undefined;

        const prompt = buildPrompt({
            language, level, topic, questionCount,
            difficulty, grammar, weakItems, retryNote,
        });

        const response = await aiRouter({ prompt, maxTokens: 4096, temperature: 0.7, schema: null });
        const data = safeParseJson(response.text || '{}') as Record<string, unknown>;

        const questions = data?.['questions'];
        if (!questions || !Array.isArray(questions) || questions.length === 0) {
            if (attempt === MAX_RETRIES) throw new Error("AI questions massivini qaytarmadi");
            continue;
        }

        cleanQuestions = (questions as Record<string, unknown>[]).map((q, i) => ({
            id: (q['id'] as string) || `q${i + 1}`,
            type: (q['type'] as string) || 'mcq',
            question: (q['question'] as string) || '',
            options: Array.isArray(q['options']) ? q['options'] : [],
            correctAnswer: (q['correctAnswer'] as string) || '',
            explanation: (q['explanation'] as string) || '',
            points: (q['points'] as number) || 10,
            timeLimit: (q['timeLimit'] as number) || 30,
        }));

        // ── CEFR validatsiya ────────────────────────────────────
        lastValidation = validateQuizLevel(cleanQuestions, level);
        console.log(`📊 Quiz validatsiya (urinish ${attempt + 1}): ${lastValidation.summary}`);

        if (lastValidation.isValid || lastValidation.score >= 70) {
            // Qabul qilinadigan natija — chiqamiz
            break;
        }

        if (attempt === MAX_RETRIES) {
            // Oxirgi urinishda ham xato — log yozib, mavjud natijani qaytaramiz
            console.warn(`⚠️ Quiz ${MAX_RETRIES} urinishdan keyin ham xato: score=${lastValidation.score}`);
            console.warn('Xatolar:', lastValidation.issues.map(i => i.message).join(' | '));
        }
    }

    // ── Firestore ga saqlash ────────────────────────────────────
    if (userId) {
        try {
            const admin = await import('firebase-admin');
            const db = admin.default.firestore();
            const totalPoints = cleanQuestions.length * 10;
            await db.collection('content').add({
                type: 'quiz',
                title: `${topic} Quiz (${level})`,
                language, level, topic, grammar,
                creatorId: userId, creatorType: 'student',
                isPublished: false, generatedByAi: true,
                attemptCount: 0, averageScore: 0,
                tags: [topic, level, grammar].filter(Boolean),
                cefrScore: lastValidation?.score ?? 100,
                createdAt: admin.default.firestore.FieldValue.serverTimestamp(),
                data: { questions: cleanQuestions, totalPoints, passingScore: Math.round(totalPoints * 0.6) },
            });
        } catch (e) { console.warn('⚠️ Firestore saqlash xatosi:', e); }
    }

    const totalPoints = cleanQuestions.length * 10;
    return {
        questions: cleanQuestions,
        totalPoints,
        passingScore: Math.round(totalPoints * 0.6),
        language, level, topic, grammar,
        cefrValidation: lastValidation ? { score: lastValidation.score, summary: lastValidation.summary } : null,
    };
}