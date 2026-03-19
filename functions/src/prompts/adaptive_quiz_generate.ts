// functions/src/prompts/adaptive_quiz_generate.ts
// SO'ZONA — Adaptive Quiz Generator
// ✅ Prompt talabi: 60% xato qiladigan topic, 20% review, 20% yangi topic
// Quiz random emas — foydalanuvchi profiliga qarab tuziladi

import { aiRouter } from '../ai/ai_router';
import { validateWithSchema } from '../schemas/schema_validator';
import quizSchema from '../schemas/quiz_schema.json';
import { getUserProfile, getRecentActivities } from '../trackers/user_activity_tracker';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

interface AdaptiveQuizParams {
    userId: string;
    language: 'en' | 'de';
    level: string;
    questionCount: number;
}

interface QuizDistribution {
    weakCount: number;      // 60% — xato qiladigan mavzular
    reviewCount: number;    // 20% — oldin o'rganilganlar
    newCount: number;       // 20% — yangi mavzular
    weakTopics: string[];
    reviewTopics: string[];
    newTopics: string[];
}

// ═══════════════════════════════════════════════════════════════
// MAVZULAR BAZASI — daraja bo'yicha
// ═══════════════════════════════════════════════════════════════

const TOPIC_POOL: Record<string, Record<string, string[]>> = {
    en: {
        A1: [
            'greetings', 'numbers', 'colors', 'family', 'food', 'animals',
            'body_parts', 'clothes', 'days_of_week', 'weather', 'home',
            'present_simple', 'to_be', 'pronouns', 'articles',
        ],
        A2: [
            'past_simple', 'present_continuous', 'comparatives', 'superlatives',
            'prepositions', 'countable_uncountable', 'modal_verbs', 'hobbies',
            'travel', 'health', 'shopping', 'directions',
        ],
        B1: [
            'present_perfect', 'past_continuous', 'conditionals_1', 'passive_voice',
            'reported_speech', 'relative_clauses', 'phrasal_verbs', 'idioms',
            'environment', 'technology', 'education', 'work',
        ],
        B2: [
            'conditionals_2_3', 'perfect_tenses', 'subjunctive', 'inversion',
            'advanced_passive', 'collocations', 'formal_writing', 'debate',
        ],
    },
    de: {
        A1: [
            'begruessungen', 'zahlen', 'farben', 'familie', 'essen', 'tiere',
            'der_die_das', 'konjugation_praesens', 'pronomen', 'verneinung',
            'akkusativ', 'wochentage', 'uhrzeit',
        ],
        A2: [
            'dativ', 'praeteritum', 'perfekt', 'modalverben', 'adjektivdeklination',
            'wechselpraepositionen', 'konjunktionen', 'einkaufen', 'reisen',
            'reflexive_verben', 'komparativ_superlativ',
        ],
        B1: [
            'passiv', 'konjunktiv_2', 'relativsaetze', 'indirekte_rede',
            'nebensaetze', 'genitiv', 'nomen_verb_verbindungen',
            'umwelt', 'beruf', 'medien',
        ],
        B2: [
            'konjunktiv_1', 'partizip_konstruktionen', 'nominalisierung',
            'erweiterte_adjektivdeklination', 'wissenschaft', 'politik',
        ],
    },
};

// ═══════════════════════════════════════════════════════════════
// ADAPTIVE QUIZ YARATISH
// ═══════════════════════════════════════════════════════════════

/**
 * Foydalanuvchi profiliga qarab adaptive quiz yaratish.
 * 
 * Taqsimot:
 * - 60% → foydalanuvchi xato qiladigan mavzular
 * - 20% → oldin o'rganilgan, takrorlash kerak
 * - 20% → yangi mavzular
 */
export async function generateAdaptiveQuiz(params: AdaptiveQuizParams): Promise<unknown> {
    const { userId, language, level, questionCount } = params;

    // 1. Foydalanuvchi profilini olish
    const profile = await getUserProfile(userId);
    const recentActivities = await getRecentActivities(userId, 'quiz', 30);

    // 2. Savol taqsimotini hisoblash
    const distribution = calculateDistribution(
        questionCount,
        profile?.weakTopics ?? [],
        profile?.strongTopics ?? [],
        recentActivities.map(a => a.topic),
        language,
        level,
    );

    // 3. AI ga prompt yaratish
    const prompt = buildAdaptivePrompt(distribution, language, level, questionCount);

    try {
        const response = await aiRouter({
            prompt,
            maxTokens: 3000,
            temperature: 0.7,
            schema: quizSchema,
        });

        const text = (response.text ?? '').replace(/```json|```/g, '').trim();
        const parsed = JSON.parse(text);

        const validated = validateWithSchema(parsed, quizSchema);
        if (!validated.isValid) {
            throw new Error(`Schema validation xatosi: ${validated.errors.join(', ')}`);
        }

        const data = validated.data as Record<string, unknown>;
        const questions = data.questions as Array<Record<string, unknown>>;

        // 4. Har bir savolga category biriktirish
        const taggedQuestions = tagQuestions(questions, distribution);

        const totalPoints = taggedQuestions.reduce(
            (sum, q) => sum + ((q.points as number) || 10), 0
        );

        return {
            questions: taggedQuestions,
            totalPoints,
            passingScore: Math.ceil(totalPoints * 0.6),
            timeLimit: taggedQuestions.reduce(
                (sum, q) => sum + ((q.timeLimit as number) || 30), 0
            ),
            distribution: {
                weakQuestions: distribution.weakCount,
                reviewQuestions: distribution.reviewCount,
                newQuestions: distribution.newCount,
                weakTopics: distribution.weakTopics,
                reviewTopics: distribution.reviewTopics,
                newTopics: distribution.newTopics,
            },
            metadata: {
                language,
                level,
                isAdaptive: true,
                userId,
                generatedAt: new Date().toISOString(),
                aiModel: response.model || 'gemini-2.0-flash',
            },
        };
    } catch (error: unknown) {
        console.error('Adaptive quiz xatosi:', error);
        throw new Error(`Adaptive quiz yaratib bo'lmadi: ${error instanceof Error ? error.message : String(error)}`);
    }
}

// ═══════════════════════════════════════════════════════════════
// TAQSIMOT HISOBLASH (60/20/20)
// ═══════════════════════════════════════════════════════════════

function calculateDistribution(
    totalQuestions: number,
    weakTopics: string[],
    strongTopics: string[],
    recentTopics: string[],
    language: string,
    level: string,
): QuizDistribution {
    // 60/20/20 taqsimot
    const weakCount = Math.round(totalQuestions * 0.6);
    const reviewCount = Math.round(totalQuestions * 0.2);
    const newCount = totalQuestions - weakCount - reviewCount;

    // Mavzular bazasidan olish
    const lang = language as 'en' | 'de';
    const allTopics = TOPIC_POOL[lang]?.[level] ?? TOPIC_POOL[lang]?.A1 ?? [];

    // Zaif mavzular — profildagi weak + oldin ko'p xato qilingan
    const weakSet = new Set(weakTopics);
    const weak = allTopics.filter(t => weakSet.has(t));
    // Agar zaif mavzular yetarli bo'lmasa, random qo'shish
    while (weak.length < 3 && allTopics.length > weak.length) {
        const random = allTopics[Math.floor(Math.random() * allTopics.length)];
        if (!weak.includes(random)) weak.push(random);
    }

    // Review mavzular — oldin o'rganilgan va kuchli bo'lganlar
    const recentSet = new Set(recentTopics);
    const strongSet = new Set(strongTopics);
    const review = allTopics.filter(t =>
        (recentSet.has(t) || strongSet.has(t)) && !weakSet.has(t)
    );
    while (review.length < 2 && allTopics.length > review.length + weak.length) {
        const random = allTopics[Math.floor(Math.random() * allTopics.length)];
        if (!review.includes(random) && !weak.includes(random)) review.push(random);
    }

    // Yangi mavzular — hali o'rganilmagan
    const usedSet = new Set([...weak, ...review, ...recentTopics]);
    const newTopics = allTopics.filter(t => !usedSet.has(t));
    while (newTopics.length < 2) {
        const random = allTopics[Math.floor(Math.random() * allTopics.length)];
        if (!newTopics.includes(random)) newTopics.push(random);
    }

    return {
        weakCount,
        reviewCount,
        newCount,
        weakTopics: weak.slice(0, 5),
        reviewTopics: review.slice(0, 3),
        newTopics: newTopics.slice(0, 3),
    };
}

// ═══════════════════════════════════════════════════════════════
// PROMPT YARATISH
// ═══════════════════════════════════════════════════════════════

function buildAdaptivePrompt(
    dist: QuizDistribution,
    language: string,
    level: string,
    totalQuestions: number,
): string {
    const langName = language === 'en' ? 'ingliz' : 'nemis';

    return `Siz tajribali ${langName} tili o'qituvchisisiz. Adaptive quiz yarating.
Daraja: ${level}

MUHIM: Savollar quyidagi TAQSIMOTDA bo'lsin:

1. ZAIF MAVZULAR (${dist.weakCount} ta savol):
   Mavzular: ${dist.weakTopics.join(', ')}
   Bu mavzularda o'quvchi ko'p xato qiladi. Oson va o'rtacha qiyinlikda savollar bering.

2. TAKRORLASH (${dist.reviewCount} ta savol):
   Mavzular: ${dist.reviewTopics.join(', ')}
   Bu mavzularni oldin o'rgangan. O'rtacha qiyinlikda tekshiring.

3. YANGI MAVZULAR (${dist.newCount} ta savol):
   Mavzular: ${dist.newTopics.join(', ')}
   Yangi mavzular — oson darajada tanishtiring.

Jami: ${totalQuestions} ta savol

Faqat quyidagi JSON formatida javob bering:
{
  "questions": [
    {
      "id": "q1",
      "type": "mcq",
      "question": "Savol matni",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": "A",
      "explanation": "Tushuntirish",
      "points": 10,
      "timeLimit": 30,
      "category": "weak|review|new",
      "topic": "mavzu_nomi"
    }
  ]
}

type qiymatlari: mcq, true_false, fill_blank
category: "weak" yoki "review" yoki "new"
Hech qanday izoh yoki markdown qo'shmang. Faqat JSON.`;
}

// ═══════════════════════════════════════════════════════════════
// SAVOLLARNI BELGILASH
// ═══════════════════════════════════════════════════════════════

function tagQuestions(
    questions: Array<Record<string, unknown>>,
    distribution: QuizDistribution,
): Array<Record<string, unknown>> {
    return questions.map((q, i) => {
        // Agar AI category qo'ymagan bo'lsa, taqsimotga qarab belgilash
        if (!q.category) {
            if (i < distribution.weakCount) {
                q.category = 'weak';
            } else if (i < distribution.weakCount + distribution.reviewCount) {
                q.category = 'review';
            } else {
                q.category = 'new';
            }
        }
        return q;
    });
}