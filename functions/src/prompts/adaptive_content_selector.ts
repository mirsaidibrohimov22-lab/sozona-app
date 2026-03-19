// functions/src/prompts/adaptive_content_selector.ts
// SO'ZONA — Adaptive Content Selector
// ✅ TUZATILGAN: TypeScript type casting xatosi hal qilindi

import { aiRouter } from '../ai/ai_router';
import { getUserProfile, getRecentActivities } from '../trackers/user_activity_tracker';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

export interface ContentSuggestion {
    type: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    topic: string;
    difficulty: 'easy' | 'medium' | 'hard';
    reason: string;
    priority: number;
    estimatedTime: number;
    params: Record<string, unknown>;
}

export interface AdaptivePlanRequest {
    userId: string;
    language: 'en' | 'de';
    sessionDuration?: number;
}

export interface AdaptivePlan {
    suggestions: ContentSuggestion[];
    userSummary: {
        level: string;
        strongSkill: string;
        weakSkill: string;
        weakTopics: string[];
        averageScore: number;
    };
    sessionPlan: SessionPlanItem[];
    motivationNote: string;
}

interface SessionPlanItem {
    order: number;
    type: string;
    topic: string;
    duration: number;
}

// ═══════════════════════════════════════════════════════════════
// ASOSIY FUNKSIYA
// ═══════════════════════════════════════════════════════════════

export async function selectAdaptiveContent(params: AdaptivePlanRequest): Promise<AdaptivePlan> {
    const { userId, language, sessionDuration = 10 } = params;

    const profile = await getUserProfile(userId);
    const recentActivities = await getRecentActivities(userId, undefined, 30);

    const analysis = analyzeProfile(profile, recentActivities);
    const suggestions = generateSuggestions(analysis, language, sessionDuration);
    const sessionPlan = buildSessionPlan(suggestions, sessionDuration);
    const motivationNote = await getSmartMotivation(analysis, language);

    return {
        suggestions,
        userSummary: {
            level: analysis.level,
            strongSkill: analysis.strongSkill,
            weakSkill: analysis.weakSkill,
            weakTopics: analysis.weakTopics,
            averageScore: analysis.averageScore,
        },
        sessionPlan,
        motivationNote,
    };
}

// ═══════════════════════════════════════════════════════════════
// PROFIL TAHLILI
// ═══════════════════════════════════════════════════════════════

interface ProfileAnalysis {
    level: string;
    vocabularyLevel: number;
    grammarLevel: number;
    listeningLevel: number;
    speakingLevel: number;
    strongSkill: string;
    weakSkill: string;
    weakTopics: string[];
    strongTopics: string[];
    averageScore: number;
    recentTrend: 'improving' | 'stable' | 'declining';
    daysSinceLastActivity: number;
    mostPracticedSkill: string;
    leastPracticedSkill: string;
}

/** ✅ TUZATILGAN: Skill ball olish funksiyasi (type cast o'rniga) */
function getSkillLevel(analysis: ProfileAnalysis, skill: string): number {
    switch (skill) {
        case 'vocabulary': return analysis.vocabularyLevel;
        case 'grammar': return analysis.grammarLevel;
        case 'listening': return analysis.listeningLevel;
        case 'speaking': return analysis.speakingLevel;
        default: return 50;
    }
}

function analyzeProfile(
    profile: {
        overallLevel?: string;
        vocabularyLevel?: number;
        grammarLevel?: number;
        listeningLevel?: number;
        speakingLevel?: number;
        weakTopics?: string[];
        strongTopics?: string[];
        averageScore?: number;
        lastActivityAt?: FirebaseFirestore.Timestamp;
    } | null,
    activities: Array<{
        skillType: string;
        scorePercent: number;
        topic: string;
        timestamp?: FirebaseFirestore.Timestamp;
    }>,
): ProfileAnalysis {
    const vocab = profile?.vocabularyLevel ?? 50;
    const grammar = profile?.grammarLevel ?? 50;
    const listening = profile?.listeningLevel ?? 50;
    const speaking = profile?.speakingLevel ?? 50;

    const skills: Record<string, number> = { vocabulary: vocab, grammar, listening, speaking };
    const sorted = Object.entries(skills).sort(([, a], [, b]) => b - a);
    const strongSkill = sorted[0][0];
    const weakSkill = sorted[sorted.length - 1][0];

    const recent10 = activities.slice(0, 10).map(a => a.scorePercent);
    const older10 = activities.slice(10, 20).map(a => a.scorePercent);
    const recentAvg = recent10.length > 0 ? recent10.reduce((a, b) => a + b, 0) / recent10.length : 50;
    const olderAvg = older10.length > 0 ? older10.reduce((a, b) => a + b, 0) / older10.length : 50;

    let recentTrend: 'improving' | 'stable' | 'declining' = 'stable';
    if (recentAvg - olderAvg > 5) recentTrend = 'improving';
    else if (olderAvg - recentAvg > 5) recentTrend = 'declining';

    const lastActivity = profile?.lastActivityAt;
    const daysSince = lastActivity
        ? Math.floor((Date.now() - lastActivity.toMillis()) / (1000 * 60 * 60 * 24))
        : 999;

    const skillCounts: Record<string, number> = { flashcard: 0, quiz: 0, listening: 0, speaking: 0 };
    for (const a of activities) {
        skillCounts[a.skillType] = (skillCounts[a.skillType] ?? 0) + 1;
    }
    const skillSorted = Object.entries(skillCounts).sort(([, a], [, b]) => b - a);
    const mostPracticed = skillSorted[0]?.[0] ?? 'quiz';
    const leastPracticed = skillSorted[skillSorted.length - 1]?.[0] ?? 'speaking';

    return {
        level: profile?.overallLevel ?? 'A1',
        vocabularyLevel: vocab,
        grammarLevel: grammar,
        listeningLevel: listening,
        speakingLevel: speaking,
        strongSkill,
        weakSkill,
        weakTopics: profile?.weakTopics ?? [],
        strongTopics: profile?.strongTopics ?? [],
        averageScore: profile?.averageScore ?? 50,
        recentTrend,
        daysSinceLastActivity: daysSince,
        mostPracticedSkill: mostPracticed,
        leastPracticedSkill: leastPracticed,
    };
}

// ═══════════════════════════════════════════════════════════════
// MASHQLAR TANLASH ALGORITMI
// ═══════════════════════════════════════════════════════════════

function generateSuggestions(
    analysis: ProfileAnalysis,
    language: string,
    _sessionDuration: number,
): ContentSuggestion[] {
    const suggestions: ContentSuggestion[] = [];
    const weakTopic = analysis.weakTopics[0] ?? 'general';
    const secondWeakTopic = analysis.weakTopics[1] ?? 'vocabulary';
    const lang = language as 'en' | 'de';

    // ✅ TUZATILGAN: getSkillLevel funksiyasi ishlatiladi
    const weakSkillLevel = getSkillLevel(analysis, analysis.weakSkill);

    // ─── 1. Zaif skill uchun mashq (eng muhim) ───
    const weakSkillExercise = getExerciseForSkill(
        analysis.weakSkill,
        weakTopic,
        'easy',
        analysis.level,
        lang,
    );
    suggestions.push({
        ...weakSkillExercise,
        priority: 1,
        reason: `${analysis.weakSkill} ko'nikmangiz zaif (${weakSkillLevel}%). "${weakTopic}" mavzusida mashq qiling.`,
    });

    // ─── 2. Zaif mavzu uchun quiz (60/20/20 rule) ───
    suggestions.push({
        type: 'quiz',
        topic: weakTopic,
        difficulty: 'easy',
        reason: `"${weakTopic}" mavzusida ko'p xato qilasiz. Adaptive quiz bilan mustahkamlang.`,
        priority: 2,
        estimatedTime: 4,
        params: {
            language: lang,
            level: analysis.level,
            topic: weakTopic,
            questionCount: 8,
            isAdaptive: true,
        },
    });

    // ─── 3. Kam mashq qilingan skill ───
    if (analysis.leastPracticedSkill !== analysis.weakSkill) {
        const leastExercise = getExerciseForSkill(
            analysis.leastPracticedSkill,
            secondWeakTopic,
            'medium',
            analysis.level,
            lang,
        );
        suggestions.push({
            ...leastExercise,
            priority: 3,
            reason: `${analysis.leastPracticedSkill} ko'p mashq qilinmagan. Balansni saqlash uchun.`,
        });
    }

    // ─── 4. Kuchli skill uchun yangi mavzu ───
    suggestions.push({
        type: skillToExerciseType(analysis.strongSkill),
        topic: 'new_topic',
        difficulty: 'medium',
        reason: `${analysis.strongSkill} kuchli tomoningiz. Yangi mavzu bilan rivojlantiring!`,
        priority: 4,
        estimatedTime: 3,
        params: {
            language: lang,
            level: analysis.level,
            topic: 'new_topic',
        },
    });

    // ─── 5. Flashcard takrorlash ───
    suggestions.push({
        type: 'flashcard',
        topic: weakTopic,
        difficulty: 'easy',
        reason: `So'z boyligini oshirish uchun flashcard takrorlang.`,
        priority: 5,
        estimatedTime: 3,
        params: {
            language: lang,
            level: analysis.level,
            topic: weakTopic,
            cardCount: 10,
        },
    });

    return suggestions.sort((a, b) => a.priority - b.priority);
}

// ═══════════════════════════════════════════════════════════════
// SESSIYA REJASI
// ═══════════════════════════════════════════════════════════════

function buildSessionPlan(
    suggestions: ContentSuggestion[],
    sessionDuration: number,
): SessionPlanItem[] {
    const plan: SessionPlanItem[] = [];
    let remainingTime = sessionDuration;
    let order = 1;

    for (const s of suggestions) {
        if (remainingTime <= 0) break;
        const duration = Math.min(s.estimatedTime, remainingTime);
        plan.push({
            order: order++,
            type: s.type,
            topic: s.topic,
            duration,
        });
        remainingTime -= duration;
    }

    return plan;
}

// ═══════════════════════════════════════════════════════════════
// AI MOTIVATSIYA
// ═══════════════════════════════════════════════════════════════

async function getSmartMotivation(
    analysis: ProfileAnalysis,
    language: string,
): Promise<string> {
    const langName = language === 'en' ? 'ingliz' : 'nemis';

    // ✅ TUZATILGAN: getSkillLevel funksiyasi ishlatiladi
    const strongLevel = getSkillLevel(analysis, analysis.strongSkill);

    const prompt = `O'quvchi ${langName} tilini o'rganmoqda. Qisqa (1-2 gap) motivatsiya xabari yoz.
Daraja: ${analysis.level}
Kuchli: ${analysis.strongSkill} (${Math.round(strongLevel)}%)
Zaif: ${analysis.weakSkill}
Trend: ${analysis.recentTrend === 'improving' ? 'yaxshilanmoqda' : analysis.recentTrend === 'declining' ? 'pasaymoqda' : 'barqaror'}
${analysis.daysSinceLastActivity > 3 ? `${analysis.daysSinceLastActivity} kun mashq qilmagan!` : ''}

O'zbek tilida, rag'batlantiruvchi, emoji bilan. Faqat xabar matnini qaytar.`;

    try {
        const response = await aiRouter({ prompt, maxTokens: 100, temperature: 0.8, schema: null });
        const text = (response.text ?? '').replace(/```/g, '').replace(/"/g, '').trim();
        return text || 'Bugun mashq qilish uchun ajoyib kun! 🚀';
    } catch {
        return analysis.recentTrend === 'improving'
            ? 'Ajoyib natijalar ko\'rsatyapsiz! Davom eting! 🔥'
            : 'Har bir qadam muhim! Bugun ham biroz mashq qilaylik! 💪';
    }
}

// ═══════════════════════════════════════════════════════════════
// YORDAMCHILAR
// ═══════════════════════════════════════════════════════════════

function getExerciseForSkill(
    skill: string,
    topic: string,
    difficulty: 'easy' | 'medium' | 'hard',
    level: string,
    language: 'en' | 'de',
): Omit<ContentSuggestion, 'priority' | 'reason'> {
    switch (skill) {
        case 'vocabulary':
            return {
                type: 'flashcard', topic, difficulty, estimatedTime: 3,
                params: { language, level, topic, cardCount: 10 },
            };
        case 'grammar':
            return {
                type: 'quiz', topic, difficulty, estimatedTime: 4,
                params: { language, level, topic, questionCount: 8 },
            };
        case 'listening':
            return {
                type: 'listening', topic, difficulty, estimatedTime: 4,
                params: { language, level, topic, questionCount: 5 },
            };
        case 'speaking':
            return {
                type: 'speaking', topic, difficulty, estimatedTime: 3,
                params: { language, level, topic },
            };
        default:
            return {
                type: 'quiz', topic, difficulty, estimatedTime: 4,
                params: { language, level, topic },
            };
    }
}

function skillToExerciseType(skill: string): 'quiz' | 'flashcard' | 'listening' | 'speaking' {
    switch (skill) {
        case 'vocabulary': return 'flashcard';
        case 'grammar': return 'quiz';
        case 'listening': return 'listening';
        case 'speaking': return 'speaking';
        default: return 'quiz';
    }
}