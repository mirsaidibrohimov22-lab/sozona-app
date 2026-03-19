// functions/src/trackers/user_activity_tracker.ts
// SO'ZONA — Foydalanuvchi faoliyat tracker
// Har bir mashq natijasini saqlaydi va profil hisoblaydi
// ✅ Prompt talabi: userId, skillType, topic, difficulty, correctAnswers, wrongAnswers,
//    responseTime, vocabularyUsed, grammarErrors

import * as admin from 'firebase-admin';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

export type SkillType = 'speaking' | 'listening' | 'quiz' | 'flashcard';
export type DifficultyLevel = 'easy' | 'medium' | 'hard';

/** Har bir mashq natijasi — Firestore ga saqlanadi */
export interface ActivityRecord {
    userId: string;
    skillType: SkillType;
    topic: string;
    difficulty: DifficultyLevel;
    correctAnswers: number;
    wrongAnswers: number;
    responseTime: number;         // soniyalarda
    vocabularyUsed: string[];     // ishlatilgan so'zlar
    grammarErrors: string[];      // grammatik xatolar
    language: 'en' | 'de';
    level: string;                // A1, A2, B1...
    timestamp: FirebaseFirestore.Timestamp;
    sessionId?: string;
    contentId?: string;
    // AI tahlili uchun qo'shimcha
    scorePercent: number;         // 0-100
    weakItems: string[];          // xato bo'lgan elementlar
    strongItems: string[];        // to'g'ri bo'lgan elementlar
}

/** Foydalanuvchi profili — AI adaptive tizim uchun */
export interface UserProfile {
    userId: string;
    vocabularyLevel: number;      // 0-100
    grammarLevel: number;         // 0-100
    listeningLevel: number;       // 0-100
    speakingLevel: number;        // 0-100
    weakTopics: string[];         // zaif mavzular
    strongTopics: string[];       // kuchli mavzular
    overallLevel: string;         // A1, A2, B1...
    totalActivities: number;
    averageScore: number;
    lastActivityAt: FirebaseFirestore.Timestamp;
    updatedAt: FirebaseFirestore.Timestamp;
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY SAQALASH
// ═══════════════════════════════════════════════════════════════

/**
 * Yangi mashq natijasini Firestore ga saqlash.
 * 
 * Qo'llanishi:
 * - Quiz tugaganda
 * - Flashcard sessiya tugaganda
 * - Listening tugaganda
 * - Speaking tugaganda
 */
export async function saveActivity(record: ActivityRecord): Promise<string> {
    const db = admin.firestore();

    // 1. Faoliyatni saqlash — undefined maydonlarni olib tashlaymiz
    const cleanRecord: Record<string, unknown> = {
        userId: record.userId,
        skillType: record.skillType,
        topic: record.topic,
        difficulty: record.difficulty,
        correctAnswers: record.correctAnswers,
        wrongAnswers: record.wrongAnswers,
        responseTime: record.responseTime,
        vocabularyUsed: record.vocabularyUsed,
        grammarErrors: record.grammarErrors,
        language: record.language,
        level: record.level,
        scorePercent: record.scorePercent,
        weakItems: record.weakItems,
        strongItems: record.strongItems,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
    // Optional maydonlarni faqat mavjud bo'lsa qo'shamiz
    if (record.sessionId) cleanRecord['sessionId'] = record.sessionId;
    if (record.contentId) cleanRecord['contentId'] = record.contentId;

    const activityRef = await db.collection('activities').add(cleanRecord);

    // 2. Foydalanuvchi profilini yangilash
    await updateUserProfile(record.userId, record);

    console.log(`📊 Faoliyat saqlandi: ${record.skillType} | ${record.userId} | ${record.scorePercent}%`);
    return activityRef.id;
}

// ═══════════════════════════════════════════════════════════════
// PROFIL HISOBLASH
// ═══════════════════════════════════════════════════════════════

/**
 * Foydalanuvchi profilini yangilash — oxirgi 50 ta faoliyatga asoslanadi.
 * 
 * Hisoblash:
 * - Har bir skillType bo'yicha o'rtacha ball → vocabularyLevel, grammarLevel, ...
 * - Eng ko'p xato qilinadigan mavzular → weakTopics
 * - Eng yaxshi natijalari → strongTopics
 */
async function updateUserProfile(userId: string, latestActivity: ActivityRecord): Promise<void> {
    const db = admin.firestore();

    // Oxirgi 50 ta faoliyatni olish
    const activitiesSnap = await db
        .collection('activities')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();

    const activities = activitiesSnap.docs.map(doc => doc.data() as ActivityRecord);

    // Skill bo'yicha ball hisoblash
    const skillScores = calculateSkillScores(activities);

    // Zaif va kuchli mavzularni aniqlash
    const { weakTopics, strongTopics } = analyzeTopics(activities);

    // Umumiy darajani hisoblash
    const avgScore = skillScores.overall;
    const overallLevel = scoreToLevel(avgScore);

    const profile: UserProfile = {
        userId,
        vocabularyLevel: skillScores.vocabulary,
        grammarLevel: skillScores.grammar,
        listeningLevel: skillScores.listening,
        speakingLevel: skillScores.speaking,
        weakTopics,
        strongTopics,
        overallLevel,
        totalActivities: activities.length,
        averageScore: avgScore,
        lastActivityAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
    };

    // Profil saqlash (upsert)
    await db.collection('userProfiles').doc(userId).set(profile, { merge: true });

    console.log(`👤 Profil yangilandi: ${userId} | Level: ${overallLevel} | Avg: ${avgScore.toFixed(1)}%`);
}

// ═══════════════════════════════════════════════════════════════
// HISOBLASH YORDAMCHILARI
// ═══════════════════════════════════════════════════════════════

interface SkillScoresResult {
    vocabulary: number;
    grammar: number;
    listening: number;
    speaking: number;
    overall: number;
}

/** Skill bo'yicha o'rtacha ball — 0-100 */
function calculateSkillScores(activities: ActivityRecord[]): SkillScoresResult {
    const skillMap: Record<string, number[]> = {
        vocabulary: [],
        grammar: [],
        listening: [],
        speaking: [],
    };

    for (const a of activities) {
        // Flashcard va Quiz → vocabulary + grammar
        if (a.skillType === 'flashcard') {
            skillMap.vocabulary.push(a.scorePercent);
        } else if (a.skillType === 'quiz') {
            // Quiz grammatika va lug'atni aralash o'lchaydi
            skillMap.vocabulary.push(a.scorePercent * 0.4);
            skillMap.grammar.push(a.scorePercent * 0.6);
        } else if (a.skillType === 'listening') {
            skillMap.listening.push(a.scorePercent);
        } else if (a.skillType === 'speaking') {
            skillMap.speaking.push(a.scorePercent);
            // Speaking grammatikani ham o'lchaydi
            if (a.grammarErrors.length > 0) {
                const grammarScore = Math.max(0, 100 - a.grammarErrors.length * 15);
                skillMap.grammar.push(grammarScore);
            }
        }
    }

    const avg = (arr: number[]) =>
        arr.length > 0 ? arr.reduce((a, b) => a + b, 0) / arr.length : 50;

    const vocabulary = Math.round(avg(skillMap.vocabulary));
    const grammar = Math.round(avg(skillMap.grammar));
    const listening = Math.round(avg(skillMap.listening));
    const speaking = Math.round(avg(skillMap.speaking));
    const overall = Math.round((vocabulary + grammar + listening + speaking) / 4);

    return { vocabulary, grammar, listening, speaking, overall };
}

/** Zaif va kuchli mavzularni aniqlash */
function analyzeTopics(activities: ActivityRecord[]): {
    weakTopics: string[];
    strongTopics: string[];
} {
    // Mavzu bo'yicha balllarni yig'ish
    const topicScores: Record<string, { total: number; count: number; errors: number }> = {};

    for (const a of activities) {
        if (!topicScores[a.topic]) {
            topicScores[a.topic] = { total: 0, count: 0, errors: 0 };
        }
        topicScores[a.topic].total += a.scorePercent;
        topicScores[a.topic].count += 1;
        topicScores[a.topic].errors += a.wrongAnswers;
    }

    // Mavzularni o'rtacha ball bo'yicha saralash
    const sorted = Object.entries(topicScores)
        .map(([topic, data]) => ({
            topic,
            avgScore: data.total / data.count,
            errorRate: data.errors / data.count,
        }))
        .sort((a, b) => a.avgScore - b.avgScore);

    // Eng zaif 5 ta va eng kuchli 5 ta
    const weakTopics = sorted.slice(0, 5).map(t => t.topic);
    const strongTopics = sorted.slice(-5).reverse().map(t => t.topic);

    return { weakTopics, strongTopics };
}

/** Ball asosida CEFR darajasini aniqlash */
function scoreToLevel(score: number): string {
    if (score >= 85) return 'B2';
    if (score >= 70) return 'B1';
    if (score >= 55) return 'A2';
    return 'A1';
}

// ═══════════════════════════════════════════════════════════════
// PROFIL OLISH (Flutter dan chaqiriladi)
// ═══════════════════════════════════════════════════════════════

/** Foydalanuvchi profilini olish */
export async function getUserProfile(userId: string): Promise<UserProfile | null> {
    const db = admin.firestore();
    const doc = await db.collection('userProfiles').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data() as UserProfile;
}

/** Foydalanuvchining oxirgi faoliyatlarini olish */
export async function getRecentActivities(
    userId: string,
    skillType?: SkillType,
    limit = 20
): Promise<ActivityRecord[]> {
    const db = admin.firestore();
    let query = db
        .collection('activities')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(limit);

    if (skillType) {
        query = query.where('skillType', '==', skillType) as typeof query;
    }

    const snap = await query.get();
    return snap.docs.map(d => d.data() as ActivityRecord);
}