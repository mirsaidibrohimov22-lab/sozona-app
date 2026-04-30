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

// ✅ Quiz turlari:
// 1. grammar_only  — faqat grammatika fill_blank
// 2. topic_grammar — mavzu + grammatika aralash (default)
// 3. passage       — matn beriladi, shu matnga asoslangan savollar

function buildPrompt(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    questionCount: number;
    difficulty: Difficulty;
    grammar: string;
    weakItems: string[];
    quizMode?: 'grammar_only' | 'topic_grammar' | 'passage';
    retryNote?: string;
}): string {
    const { language, level, topic, questionCount, difficulty, grammar, weakItems, quizMode = 'topic_grammar', retryNote } = params;
    const languageName = language === 'en' ? 'English' : 'German';
    const levelBlock = buildLevelBlock(level, language);
    const difficultyNote = buildDifficultyNote(difficulty, level);
    const weakNote = weakItems.length > 0
        ? `\nFocus on student weak areas: ${weakItems.slice(0, 5).join(', ')}`
        : '';
    const retryBlock = retryNote ? `\n\n${retryNote}` : '';

    // 1. GRAMMAR ONLY — faqat grammatika fill_blank
    if (quizMode === 'grammar_only') {
        const grammarFocus = grammar || 'present simple';
        return `You are an expert ${languageName} grammar teacher.

${levelBlock}

Grammar focus: "${grammarFocus}"
Number of questions: ${questionCount}
Difficulty: ${difficulty} — ${difficultyNote}${weakNote}${retryBlock}

Create ONLY fill_blank questions testing "${grammarFocus}" grammar rule.
Each sentence has ONE blank (___) where the correct verb form goes.
Mix different sentence structures. Explanation in Uzbek.

Return ONLY valid JSON:
{
  "questions": [
    {
      "id": "q1",
      "type": "fill_blank",
      "question": "She ___ (go) to school every day.",
      "options": ["goes", "go", "going", "went"],
      "correctAnswer": "goes",
      "explanation": "She - 3-shaxs birlik, present simple da -s qo'shiladi",
      "points": 10,
      "timeLimit": 40
    }
  ]
}

Rules:
- ALWAYS fill_blank type
- options: 4 ta — biri to'g'ri, 3 tasi xato forma
- Show infinitive in bracket: ___ (verb)
- explanation: O'zbek tilida grammatika tushuntiring`;
    }

    // 2. PASSAGE — matn asosida savollar
    if (quizMode === 'passage') {
        return `You are an expert ${languageName} reading teacher.

${levelBlock}

Topic: "${topic}"
Number of questions: ${questionCount}
Difficulty: ${difficulty} — ${difficultyNote}${weakNote}${retryBlock}

STEP 1: Write a reading passage (80-150 words) about "${topic}" at ${level} level.
STEP 2: Create ${questionCount} questions ONLY based on that passage.

Return ONLY valid JSON:
{
  "passage": "Full reading text here (80-150 words in ${languageName})",
  "questions": [
    {
      "id": "q1",
      "type": "mcq",
      "question": "According to the text, what...?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": "A",
      "explanation": "Matnda aytilgan: '...'",
      "points": 10,
      "timeLimit": 35
    }
  ]
}

Rules:
- passage: written first, all questions based ONLY on it
- mix mcq and true_false
- true_false: options ["True", "False"]
- explanations reference specific part of passage`;
    }

    // 3. TOPIC + GRAMMAR — aralash (default)
    const grammarNote = grammar
        ? `\nGrammar focus: "${grammar}" — 40% of questions must be fill_blank testing this grammar.`
        : '';

    return `You are an expert ${languageName} language teacher creating a quiz.

${levelBlock}

Topic: "${topic}"
Number of questions: ${questionCount}
Difficulty: ${difficulty} — ${difficultyNote}${grammarNote}${weakNote}${retryBlock}

Mix these types:
- mcq (4 options): vocabulary and comprehension
- true_false ["True","False"]: grammar or vocabulary in context
- fill_blank (___): grammar in context, 4 verb form options

Return ONLY valid JSON:
{
  "questions": [
    {
      "id": "q1",
      "type": "mcq",
      "question": "Question in ${languageName}?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": "A",
      "explanation": "Tushuntirish o'zbek tilida",
      "points": 10,
      "timeLimit": 30
    },
    {
      "id": "q2",
      "type": "fill_blank",
      "question": "She ___ (be) a teacher.",
      "options": ["is", "are", "am", "was"],
      "correctAnswer": "is",
      "explanation": "She - 3-shaxs birlik, to be: is ishlatiladi",
      "points": 10,
      "timeLimit": 40
    }
  ]
}

STRICT QUALITY RULES — violating these makes the quiz worthless:

MCQ OPTIONS RULE:
- All 4 options MUST belong to the same semantic category as the correct answer.
- If the answer is a food item → all 4 options must be food items (NOT verbs, actions, or unrelated words).
- If the answer is a color → all 4 options must be colors.
- FORBIDDEN example: Q:"What do you eat?" options: [eggs, bread, sleep, run] ← "sleep" and "run" are NOT food → WRONG.
- CORRECT example: Q:"What do you eat for breakfast?" options: [eggs, bread, soup, fish] ← all are food → CORRECT.

TRUE/FALSE RULE:
- true_false questions MUST test LANGUAGE SKILL (vocabulary meaning or grammar), NOT general world knowledge.
- FORBIDDEN: "Cats can fly. True or False?" — this tests biology, not language.
- FORBIDDEN: "Milk is white. True or False?" — any child knows this; it tests nothing linguistic.
- FORBIDDEN: "The sun is a star. True or False?" — world knowledge, not language.
- CORRECT: "She go to school every day. Is this sentence correct?" — tests grammar (subject-verb agreement).
- CORRECT: A short sentence in ${languageName} with a vocabulary word used correctly or incorrectly — student must judge.
- CORRECT: "In ${languageName}, 'Hund' means 'cat'. True or False?" — tests vocabulary knowledge.

A1 SPECIFIC RULE:
- NEVER ask obvious fact questions where the answer requires zero ${languageName} knowledge.
- Every question must require knowing a ${languageName} word, phrase, or grammar rule to answer correctly.

Rules:
- mcq: exactly 4 options
- true_false: options ["True","False"]
- fill_blank: 4 options (verb forms), ___ for blank, () for infinitive
- Explanations in Uzbek`;
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
    quizMode?: 'grammar_only' | 'topic_grammar' | 'passage'; // ✅ YANGI
}): Promise<unknown> {
    const {
        language, level, topic, questionCount,
        difficulty = 'medium', grammar = '', weakItems = [], userId,
        quizMode = 'topic_grammar',
    } = params;

    const MAX_RETRIES = 2;
    let lastValidation = null;
    let cleanQuestions: Record<string, unknown>[] = [];
    let passageText = ''; // ✅ passage mode uchun

    // ── Retry loop ──────────────────────────────────────────────
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
        const retryNote = attempt > 0 && lastValidation
            ? buildRetryNote(lastValidation, level)
            : undefined;

        const prompt = buildPrompt({
            language, level, topic, questionCount,
            difficulty, grammar, weakItems, quizMode, retryNote,
        });

        const response = await aiRouter({ prompt, maxTokens: 4096, temperature: 0.7, schema: null });
        const data = safeParseJson(response.text || '{}') as Record<string, unknown>;

        const questions = data?.['questions'];
        if (!questions || !Array.isArray(questions) || questions.length === 0) {
            if (attempt === MAX_RETRIES) throw new Error("AI questions massivini qaytarmadi");
            continue;
        }

        // passage mode da matnni saqlaymiz
        if (quizMode === 'passage' && data['passage']) {
            passageText = (data['passage'] as string);
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
        quizMode,
        passage: (quizMode === 'passage') ? passageText : null, // ✅ matn qaytariladi
        cefrValidation: lastValidation ? { score: lastValidation.score, summary: lastValidation.summary } : null,
    };
}