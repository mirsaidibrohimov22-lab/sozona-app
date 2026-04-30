// functions/src/prompts/premium_coach.ts
// SO'ZONA — Premium AI Murabbiy v3
//
// Yangilanishlar:
//   - Real-time activities collectiondan o'qiydi (eski snapshot emas)
//   - Kunlik / Haftalik / Oylik / Yillik statistika
//   - Har bir skill: quiz, listening, speaking, flashcard alohida
//   - Qaysi mavzuda, qaysi grammatikada xato — aniq ko'rsatadi
//   - Voice assistant uchun ham ishlatiladi
//   - OpenAI_API_KEY → OPENAI_KEY fix

import * as admin from 'firebase-admin';
import { aiRouter, openAiRouter } from '../ai/ai_router';
import { buildLevelBlock } from './cefr_level_guide';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

export interface PremiumCoachRequest {
    userId: string;
    studentName: string;
    language: 'en' | 'de';
    level: string;
    trigger: 'after_lesson' | 'daily_check' | 'weak_area' | 'motivation';
    skillType?: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    lastScore?: number;
    dailyGoalMinutes?: number;
    // ✅ YANGI: Hozirgi mashq sessiyasi ma'lumotlari
    sessionData?: {
        topic?: string;
        totalQuestions?: number;
        correctCount?: number;
        wrongCount?: number;
        wrongAnswers?: Array<{ question?: string; userAnswer?: string; correctAnswer?: string }>;
        transcribedText?: string;   // Speaking uchun
        grammarErrors?: string[];   // Speaking uchun
        ieltsBand?: string;         // Speaking uchun
        missedWords?: string[];     // Flashcard/Listening uchun
    };
}

export interface SkillStats {
    count: number;           // Bajarilgan mashqlar soni
    avgScore: number;        // O'rtacha ball (%)
    bestScore: number;       // Eng yuqori ball
    worstScore: number;      // Eng past ball
    weakTopics: string[];    // Zaif mavzular
    weakGrammar: string[];   // Zaif grammatika (quiz uchun)
    trend: 'yaxshilanmoqda' | 'pasaymoqda' | 'barqaror'; // So'nggi trend
}

export interface PeriodStats {
    daily: SkillStats;
    weekly: SkillStats;
    monthly: SkillStats;
    yearly: SkillStats;
}

export interface FullStats {
    quiz: PeriodStats;
    listening: PeriodStats;
    speaking: PeriodStats;
    flashcard: PeriodStats;
    overall: {
        daily: number;
        weekly: number;
        monthly: number;
        yearly: number;
        totalSessions: number;
        streakDays: number;
    };
}

export interface PremiumCoachResponse {
    personalAnalysis: string;
    weakPoints: string[];
    scientificMethod: string;
    motivation: string;
    weeklyPlan: string;
    stats: FullStats;
    exercises: GeneratedExercise[];
}

export interface GeneratedExercise {
    type: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    topic: string;
    title: string;
    description: string;
    duration: number;
    difficulty: 'easy' | 'medium' | 'hard';
    content: Record<string, unknown>;
    source: string;
}

// ═══════════════════════════════════════════════════════════════
// STATISTIKA HISOBLASH — activities collectiondan real-time
// ═══════════════════════════════════════════════════════════════

function emptySkillStats(): SkillStats {
    return {
        count: 0,
        avgScore: 0,
        bestScore: 0,
        worstScore: 100,
        weakTopics: [],
        weakGrammar: [],
        trend: 'barqaror',
    };
}

function calcSkillStats(docs: admin.firestore.QueryDocumentSnapshot[]): SkillStats {
    if (docs.length === 0) return emptySkillStats();

    const scores = docs.map(d => (d.data()['scorePercent'] as number) ?? 0);
    const avgScore = scores.reduce((a, b) => a + b, 0) / scores.length;
    const bestScore = Math.max(...scores);
    const worstScore = Math.min(...scores);

    // Zaif mavzular — 60% dan past natija bo'lgan mavzular
    const topicMap: Record<string, number[]> = {};
    const grammarMap: Record<string, number> = {};

    for (const doc of docs) {
        const data = doc.data();
        const topic = (data['topic'] as string) ?? '';
        const score = (data['scorePercent'] as number) ?? 0;
        const grammarErrors = (data['grammarErrors'] as string[]) ?? [];
        const weakItems = (data['weakItems'] as string[]) ?? [];

        if (topic) {
            if (!topicMap[topic]) topicMap[topic] = [];
            topicMap[topic].push(score);
        }
        for (const g of grammarErrors) {
            grammarMap[g] = (grammarMap[g] ?? 0) + 1;
        }
        for (const w of weakItems) {
            grammarMap[w] = (grammarMap[w] ?? 0) + 1;
        }
    }

    const weakTopics = Object.entries(topicMap)
        .filter(([, s]) => s.reduce((a, b) => a + b, 0) / s.length < 60)
        .sort(([, a], [, b]) => {
            const avgA = a.reduce((x, y) => x + y, 0) / a.length;
            const avgB = b.reduce((x, y) => x + y, 0) / b.length;
            return avgA - avgB;
        })
        .slice(0, 5)
        .map(([t]) => t);

    const weakGrammar = Object.entries(grammarMap)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 4)
        .map(([g]) => g);

    // Trend: oxirgi yarmi vs birinchi yarmi
    const half = Math.floor(docs.length / 2);
    const firstHalf = scores.slice(half);
    const secondHalf = scores.slice(0, half);
    const firstAvg = firstHalf.length > 0
        ? firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length : avgScore;
    const secondAvg = secondHalf.length > 0
        ? secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length : avgScore;

    const trend: SkillStats['trend'] = secondAvg > firstAvg + 5 ? 'yaxshilanmoqda'
        : secondAvg < firstAvg - 5 ? 'pasaymoqda' : 'barqaror';

    return {
        count: docs.length,
        avgScore: Math.round(avgScore),
        bestScore: Math.round(bestScore),
        worstScore: Math.round(worstScore),
        weakTopics,
        weakGrammar,
        trend,
    };
}

async function fetchFullStats(userId: string): Promise<FullStats> {
    const db = admin.firestore();
    const now = new Date();

    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const yearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);

    const skills: Array<'quiz' | 'listening' | 'speaking' | 'flashcard'> =
        ['quiz', 'listening', 'speaking', 'flashcard'];

    // Barcha faoliyatlarni bir marta yuklash (yil davomida)
    const allSnap = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yearAgo))
        .orderBy('timestamp', 'desc')
        .limit(500)
        .get();

    const allDocs = allSnap.docs;

    // Vaqt bo'yicha filter qiluvchi helper
    const filterByTime = (since: Date) =>
        allDocs.filter(d => {
            const ts = d.data()['timestamp'] as admin.firestore.Timestamp;
            return ts && ts.toDate() >= since;
        });

    const dayDocs = filterByTime(dayAgo);
    const weekDocs = filterByTime(weekAgo);
    const monthDocs = filterByTime(monthAgo);
    const yearDocs = allDocs;

    // Skill bo'yicha filterlash
    const filterBySkill = (docs: admin.firestore.QueryDocumentSnapshot[], skill: string) =>
        docs.filter(d => d.data()['skillType'] === skill);

    const result: Partial<FullStats> & { overall: FullStats['overall'] } = {
        overall: {
            daily: calcAvg(dayDocs),
            weekly: calcAvg(weekDocs),
            monthly: calcAvg(monthDocs),
            yearly: calcAvg(yearDocs),
            totalSessions: allDocs.length,
            streakDays: await getStreakDays(userId),
        },
    } as FullStats;

    for (const skill of skills) {
        (result as Record<string, unknown>)[skill] = {
            daily: calcSkillStats(filterBySkill(dayDocs, skill)),
            weekly: calcSkillStats(filterBySkill(weekDocs, skill)),
            monthly: calcSkillStats(filterBySkill(monthDocs, skill)),
            yearly: calcSkillStats(filterBySkill(yearDocs, skill)),
        };
    }

    return result as FullStats;
}

function calcAvg(docs: admin.firestore.QueryDocumentSnapshot[]): number {
    if (docs.length === 0) return 0;
    const scores = docs.map(d => (d.data()['scorePercent'] as number) ?? 0);
    return Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
}

async function getStreakDays(userId: string): Promise<number> {
    try {
        const db = admin.firestore();
        const doc = await db.collection('progress').doc(userId).get();
        return (doc.data()?.['currentStreak'] as number) ?? 0;
    } catch {
        return 0;
    }
}

// ═══════════════════════════════════════════════════════════════
// MASHQ YARATISH (avvalgidek, o'zgarmagan)
// ═══════════════════════════════════════════════════════════════

async function generateExercise(params: {
    type: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    topic: string;
    duration: number;
    difficulty: 'easy' | 'medium' | 'hard';
    language: 'en' | 'de';
    level: string;
    weakItems: string[];
}): Promise<GeneratedExercise> {
    const { type, topic, duration, difficulty, language, level, weakItems } = params;
    const langName = language === 'en' ? 'English' : 'German';
    const levelBlock = buildLevelBlock(level as 'A1' | 'A2' | 'B1' | 'B2' | 'C1', language);
    const weakNote = weakItems.length > 0
        ? `Student's weak points: ${weakItems.slice(0, 3).join(', ')}. Focus on these.`
        : '';
    const qCount = duration <= 5 ? 4 : duration <= 8 ? 6 : 8;

    const prompts: Record<string, string> = {
        quiz: `You are an expert ${langName} teacher. ${levelBlock}\nTopic: "${topic}"\nDifficulty: ${difficulty}\n${weakNote}\nReturn ONLY JSON: {"title":"...","description":"...","source":"...","questions":[{"id":"q1","question":"...","options":["A","B","C","D"],"correctAnswer":"A","explanation":"..."}]} with ${qCount} questions.`,
        flashcard: `You are an expert ${langName} vocabulary teacher. ${levelBlock}\nTopic: "${topic}"\n${weakNote}\nReturn ONLY JSON: {"title":"...","description":"...","source":"...","cards":[{"id":"fc1","front":"word","back":"tarjima","example":"...","pronunciation":"..."}]} with ${Math.min(qCount + 4, 14)} cards.`,
        listening: `You are creating a ${langName} listening exercise. ${levelBlock}\nTopic: "${topic}"\n${weakNote}\nReturn ONLY JSON: {"title":"...","description":"...","source":"...","transcript":"dialogue...","questions":[{"id":"lq1","question":"...","options":["A","B","C","D"],"correctAnswer":"A","explanation":"..."}]} with ${qCount} questions.`,
        speaking: `You are a ${langName} speaking coach. ${levelBlock}\nTopic: "${topic}"\nDuration: ${duration} min\n${weakNote}\nReturn ONLY JSON: {"title":"...","description":"...","source":"...","taskType":"describe","prompt":"vazifa (o'zbekcha)","exampleAnswer":"...","keyPhrases":["..."],"grammarFocus":"..."}`,
    };

    try {
        const response = await openAiRouter({ prompt: prompts[type], maxTokens: 2000, temperature: 0.7 });
        const parsed = JSON.parse(response.text.replace(/```json|```/g, '').trim()) as Record<string, unknown>;
        return {
            type, topic,
            title: (parsed['title'] as string) ?? `${topic} ${type}`,
            description: (parsed['description'] as string) ?? '',
            duration, difficulty,
            content: parsed,
            source: (parsed['source'] as string) ?? 'Oxford Language Research',
        };
    } catch (e) {
        console.error(`⚠️ Mashq yaratish xatosi (${type}):`, e);
        return {
            type, topic,
            title: `${topic} — ${type}`,
            description: `${langName} ${level} ${topic}`,
            duration, difficulty,
            content: {},
            source: 'Oxford Language Research',
        };
    }
}

// ═══════════════════════════════════════════════════════════════
// VOICE ASSISTANT UCHUN — qisqa statistika matni
// ═══════════════════════════════════════════════════════════════

export async function getVoiceCoachSummary(userId: string, studentName: string): Promise<string> {
    try {
        const stats = await fetchFullStats(userId);
        const w = stats.overall.weekly;
        const m = stats.overall.monthly;

        const parts: string[] = [];

        // Haftalik umumiy
        if (stats.quiz.weekly.count > 0) {
            parts.push(`Bu hafta quiz: ${stats.quiz.weekly.count} ta, o'rtacha ${stats.quiz.weekly.avgScore}%`);
        }
        if (stats.listening.weekly.count > 0) {
            parts.push(`Listening: ${stats.listening.weekly.count} ta, ${stats.listening.weekly.avgScore}%`);
        }
        if (stats.speaking.weekly.count > 0) {
            parts.push(`Speaking: ${stats.speaking.weekly.count} ta, ${stats.speaking.weekly.avgScore}%`);
        }
        if (stats.flashcard.weekly.count > 0) {
            parts.push(`Flashcard: ${stats.flashcard.weekly.count} ta`);
        }

        // Zaif tomonlar
        const weakSkills: string[] = [];
        if (stats.quiz.weekly.avgScore < 60 && stats.quiz.weekly.count > 0)
            weakSkills.push(`quiz (${stats.quiz.weekly.avgScore}%)`);
        if (stats.listening.weekly.avgScore < 60 && stats.listening.weekly.count > 0)
            weakSkills.push(`listening (${stats.listening.weekly.avgScore}%)`);
        if (stats.speaking.weekly.avgScore < 60 && stats.speaking.weekly.count > 0)
            weakSkills.push(`speaking (${stats.speaking.weekly.avgScore}%)`);

        // Streak
        const streak = stats.overall.streakDays;

        let summary = `${studentName}, mana haftalik ko'rsatkichlaringiz. `;
        if (parts.length > 0) {
            summary += parts.join('. ') + '. ';
        } else {
            summary += 'Bu hafta hali mashq bajarmagansiz. ';
        }

        if (weakSkills.length > 0) {
            summary += `Kuchaytirish kerak: ${weakSkills.join(', ')}. `;
        }

        if (w > 0) summary += `Haftalik o'rtacha: ${w}%. `;
        if (m > 0) summary += `Oylik o'rtacha: ${m}%. `;
        if (streak > 0) summary += `Streak: ${streak} kun ketma-ket!`;

        return summary;
    } catch (e) {
        console.error('getVoiceCoachSummary xato:', e);
        return `${studentName}, natijalarni yuklashda xato yuz berdi. Keyinroq urinib ko'ring.`;
    }
}

// ═══════════════════════════════════════════════════════════════
// ASOSIY FUNKSIYA
// ═══════════════════════════════════════════════════════════════

export async function getPremiumCoachAdvice(
    params: PremiumCoachRequest
): Promise<PremiumCoachResponse> {
    const { userId, studentName, language, level, trigger, lastScore, dailyGoalMinutes, sessionData } = params;

    // 1. Real statistikani yuklash
    const stats = await fetchFullStats(userId);

    // 2. Zaif skillni aniqlash (haftalik)
    const skillAvgs = {
        quiz: stats.quiz.weekly.count > 0 ? stats.quiz.weekly.avgScore : 100,
        listening: stats.listening.weekly.count > 0 ? stats.listening.weekly.avgScore : 100,
        speaking: stats.speaking.weekly.count > 0 ? stats.speaking.weekly.avgScore : 100,
        flashcard: stats.flashcard.weekly.count > 0 ? stats.flashcard.weekly.avgScore : 100,
    };

    const sortedSkills = Object.entries(skillAvgs).sort(([, a], [, b]) => a - b);
    const weakestSkill = sortedSkills[0][0] as 'quiz' | 'listening' | 'speaking' | 'flashcard';
    const weakestScore = sortedSkills[0][1];

    // Zaif mavzular (haftadan)
    const weeklySkillStats = stats[weakestSkill].weekly;
    const weakTopics = weeklySkillStats.weakTopics.length > 0
        ? weeklySkillStats.weakTopics
        : stats[weakestSkill].monthly.weakTopics;

    const langName = language === 'en' ? 'ingliz' : 'nemis';
    const totalMinutes = dailyGoalMinutes ?? 15;

    // 3. Mashqlar rejasi
    const exercisePlan: Array<{
        type: 'quiz' | 'flashcard' | 'listening' | 'speaking';
        topic: string;
        duration: number;
        difficulty: 'easy' | 'medium' | 'hard';
    }> = [];

    let remaining = totalMinutes;
    const topic1 = weakTopics[0] ?? 'general vocabulary';
    const topic2 = weakTopics[1] ?? topic1;

    if (remaining >= 5) {
        const dur = Math.min(remaining, totalMinutes <= 15 ? 5 : 8);
        exercisePlan.push({ type: weakestSkill, topic: topic1, duration: dur, difficulty: 'easy' });
        remaining -= dur;
    }
    if (remaining >= 4) {
        const dur = Math.min(remaining, 6);
        exercisePlan.push({ type: 'quiz', topic: topic2, duration: dur, difficulty: 'easy' });
        remaining -= dur;
    }
    if (remaining >= 4) {
        const altType = weakestSkill === 'quiz' ? 'flashcard'
            : weakestSkill === 'flashcard' ? 'quiz'
                : weakestSkill === 'listening' ? 'speaking' : 'listening';
        exercisePlan.push({ type: altType, topic: topic1, duration: remaining, difficulty: 'medium' });
    }

    // 4. Mashqlarni parallel yaratish
    const generatedExercises = await Promise.all(
        exercisePlan.map(p => generateExercise({
            ...p,
            language,
            level,
            weakItems: weeklySkillStats.weakGrammar,
        }))
    );

    // 5. AI Tahlil (Gemini)
    const statsText = `
Quiz (hafta): ${stats.quiz.weekly.count} ta, ${stats.quiz.weekly.avgScore}%, trend: ${stats.quiz.weekly.trend}
Listening (hafta): ${stats.listening.weekly.count} ta, ${stats.listening.weekly.avgScore}%, trend: ${stats.listening.weekly.trend}
Speaking (hafta): ${stats.speaking.weekly.count} ta, ${stats.speaking.weekly.avgScore}%, trend: ${stats.speaking.weekly.trend}
Flashcard (hafta): ${stats.flashcard.weekly.count} ta
Quiz (oy): ${stats.quiz.monthly.avgScore}% | Listening (oy): ${stats.listening.monthly.avgScore}%
Speaking (oy): ${stats.speaking.monthly.avgScore}% | Umumiy (oy): ${stats.overall.monthly}%
Zaif mavzular: ${weakTopics.slice(0, 4).join(', ') || 'aniqlanmagan'}
Zaif grammatika: ${weeklySkillStats.weakGrammar.slice(0, 3).join(', ') || 'aniqlanmagan'}
Streak: ${stats.overall.streakDays} kun`.trim();

    const analysisPrompt = `Sen So'zona premium AI murabbiyisan. O'zbek tilida javob ber.

O'QUVCHI: ${studentName}, ${langName} tili, ${level} daraja
Trigger: ${trigger}, Kunlik vaqt: ${totalMinutes} daqiqa
${lastScore !== undefined ? `Oxirgi mashq natijasi: ${lastScore}%` : ''}

${sessionData ? `HOZIRGI SESSIYA MA'LUMOTLARI (ENG MUHIM — shu asosida tahlil qil):
Mavzu: ${sessionData.topic ?? 'Noma\'lum'}
Jami savollar: ${sessionData.totalQuestions ?? '—'}
To'g'ri javoblar: ${sessionData.correctCount ?? '—'}
Noto'g'ri javoblar: ${sessionData.wrongCount ?? '—'}
${sessionData.wrongAnswers && sessionData.wrongAnswers.length > 0
                ? `Noto'g'ri javoblar tafsiloti:\n${sessionData.wrongAnswers.slice(0, 5).map((w, i) =>
                    `  ${i + 1}. Savol: "${w.question ?? '?'}" | Berilgan: "${w.userAnswer ?? '?'}" | To'g'ri: "${w.correctAnswer ?? '?'}"`
                ).join('\n')}`
                : ''}
${sessionData.transcribedText ? `O'quvchi gapirgan matn: "${sessionData.transcribedText}"` : ''}
${sessionData.grammarErrors && sessionData.grammarErrors.length > 0 ? `Grammatika xatolari: ${sessionData.grammarErrors.join(', ')}` : ''}
${sessionData.ieltsBand ? `IELTS bandi: ${sessionData.ieltsBand}` : ''}
${sessionData.missedWords && sessionData.missedWords.length > 0 ? `O'rganilmagan so'zlar: ${sessionData.missedWords.join(', ')}` : ''}
` : ''}
UMUMIY STATISTIKA (qo'shimcha kontekst):
${statsText}

Eng zaif ko'nikma: ${weakestSkill} (${weakestScore}%)

Faqat JSON qaytargil (o'zbekcha):
{
  "personalAnalysis": "3-4 gap: ismi bilan, aniq raqamlar bilan shaxsiy tahlil. Qaysi ko'nikma past, qaysi mavzuda xato ko'p.",
  "weakPoints": [
    "Quiz: qaysi mavzuda necha % natija",
    "Listening: qaysi mavzuda muammo",
    "Speaking/Flashcard: aniq muammo",
    "Grammatika: qaysi qoidada xato ko'p"
  ],
  "scientificMethod": "Oxford/Cambridge/Harvard usuli 2-3 gap, nima qilish kerak aniq.",
  "motivation": "1-2 gap jonli motivatsiya emoji bilan",
  "weeklyPlan": "Du: ..., Se: ..., Ch: ..., Pa: ..., Sh: ... (qisqa, aniq)"
}`;

    let analysis = {
        personalAnalysis: `${studentName}, ${langName} tilida haftalik o'rtacha ${stats.overall.weekly}% natija ko'rsatyapsiz.`,
        weakPoints: [
            `Quiz: haftalik ${stats.quiz.weekly.avgScore}% (${stats.quiz.weekly.count} ta mashq)`,
            `Listening: ${stats.listening.weekly.avgScore}%`,
            `Speaking: ${stats.speaking.weekly.avgScore}%`,
            weakTopics[0] ? `"${weakTopics[0]}" mavzusida ko'p xato` : 'Barcha mavzularni takrorlang',
        ],
        scientificMethod: 'Cambridge tadqiqotlariga ko\'ra, kuniga 20-30 daqiqa muntazam mashq samaraliroq.',
        motivation: `${studentName}, har bir qadam muvaffaqiyatga yaqinlashtiradi! 💪`,
        weeklyPlan: 'Du: Quiz, Se: Listening, Ch: Flashcard, Pa: Speaking, Sh: Takrorlash',
    };

    try {
        const resp = await aiRouter({ prompt: analysisPrompt, maxTokens: 900, temperature: 0.75 });
        const parsed = JSON.parse(resp.text.replace(/```json|```/g, '').trim()) as typeof analysis;
        analysis = {
            personalAnalysis: parsed.personalAnalysis ?? analysis.personalAnalysis,
            weakPoints: (parsed.weakPoints ?? analysis.weakPoints).slice(0, 5),
            scientificMethod: parsed.scientificMethod ?? analysis.scientificMethod,
            motivation: parsed.motivation ?? analysis.motivation,
            weeklyPlan: parsed.weeklyPlan ?? analysis.weeklyPlan,
        };
    } catch (e) {
        console.error('⚠️ AI tahlil xatosi:', e);
    }

    return {
        personalAnalysis: analysis.personalAnalysis,
        weakPoints: analysis.weakPoints,
        scientificMethod: analysis.scientificMethod,
        motivation: analysis.motivation,
        weeklyPlan: analysis.weeklyPlan,
        stats,
        exercises: generatedExercises,
    };
}

// ═══════════════════════════════════════════════════════════════
// O'ZBEKISTON ANIQLOVCHI (o'zgarmadi)
// ═══════════════════════════════════════════════════════════════

export async function detectUzbekUser(params: {
    deviceLocale: string;
    ipCountry?: string;
}): Promise<{ isUzbek: boolean; reason: string }> {
    const { deviceLocale, ipCountry } = params;
    const isUzbekLocale = deviceLocale.toLowerCase().startsWith('uz');
    const isUzbekIp = ipCountry === 'UZ';
    const isUzbek = isUzbekLocale || isUzbekIp;
    return {
        isUzbek,
        reason: isUzbekIp ? 'IP manzil O\'zbekiston'
            : isUzbekLocale ? 'Qurilma tili o\'zbek'
                : 'O\'zbekiston aniqlanmadi',
    };
}