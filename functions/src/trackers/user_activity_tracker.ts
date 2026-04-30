// functions/src/trackers/user_activity_tracker.ts
// SO'ZONA — Foydalanuvchi faoliyat tracker
// ✅ FIX v2.0: progress/{userId} da currentStreak va lastActiveDate yangilanadi
//    Endi daraxt animatsiyasi va streak ish bo'yicha to'g'ri ko'rsatiladi

import * as admin from 'firebase-admin';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

export type SkillType = 'speaking' | 'listening' | 'quiz' | 'flashcard';
export type DifficultyLevel = 'easy' | 'medium' | 'hard';

export interface ActivityRecord {
    userId: string;
    skillType: SkillType;
    topic: string;
    difficulty: DifficultyLevel;
    correctAnswers: number;
    wrongAnswers: number;
    responseTime: number;
    vocabularyUsed: string[];
    grammarErrors: string[];
    language: 'en' | 'de';
    level: string;
    timestamp: FirebaseFirestore.Timestamp;
    sessionId?: string;
    contentId?: string;
    scorePercent: number;
    weakItems: string[];
    strongItems: string[];
    classId?: string; // ✅ YANGI: Teacher analytics uchun
}

export interface UserProfile {
    userId: string;
    vocabularyLevel: number;
    grammarLevel: number;
    listeningLevel: number;
    speakingLevel: number;
    weakTopics: string[];
    strongTopics: string[];
    overallLevel: string;
    totalActivities: number;
    averageScore: number;
    lastActivityAt: FirebaseFirestore.Timestamp;
    updatedAt: FirebaseFirestore.Timestamp;
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY SAQLASH
// ═══════════════════════════════════════════════════════════════

export async function saveActivity(record: ActivityRecord): Promise<string> {
    const db = admin.firestore();

    // 1. Faoliyatni saqlash
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
    if (record.sessionId) cleanRecord['sessionId'] = record.sessionId;
    if (record.contentId) cleanRecord['contentId'] = record.contentId;
    if (record.classId) cleanRecord['classId'] = record.classId; // ✅ YANGI

    const activityRef = await db.collection('activities').add(cleanRecord);

    // 2. Streak yangilash (progress collection)
    await updateStreak(record.userId);

    // 3. Foydalanuvchi profilini yangilash (userProfiles collection)
    await updateUserProfile(record.userId, record);

    // 4. ✅ YANGI: classId bo'lsa — teacher dashboard uchun members docni yangilash
    if (record.classId) {
        await updateClassMemberStats(record.userId, record.classId);
    }

    console.log(`📊 Faoliyat saqlandi: ${record.skillType} | ${record.userId} | ${record.scorePercent}%`);
    return activityRef.id;
}

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: STREAK YANGILASH LOGIKASI
// ═══════════════════════════════════════════════════════════════

/**
 * Har mashq tugaganda progress/{userId} da streak yangilanadi.
 *
 * Qoidalar:
 * - Bugun birinchi marta kirsa → streak + 1, lastActiveDate = bugun
 * - Kecha kirgan bo'lsa → streak + 1 (ketma-ketlik davom etadi)
 * - 2+ kun bo'lsa → streak = 1 (boshidan)
 * - Bugun allaqachon hisoblangan bo'lsa → o'zgarmaydi
 */
async function updateStreak(userId: string): Promise<void> {
    const db = admin.firestore();
    const progressRef = db.collection('progress').doc(userId);

    try {
        await db.runTransaction(async (tx) => {
            const doc = await tx.get(progressRef);
            const data = doc.exists ? doc.data()! : {};

            const now = new Date();
            const todayStr = toDateStr(now); // "2026-03-20"

            const lastActiveRaw = data['lastActiveDate'] as admin.firestore.Timestamp | undefined;
            const lastDateStr = lastActiveRaw ? toDateStr(lastActiveRaw.toDate()) : null;

            // Bugun allaqachon hisoblangan → hech narsa qilma
            if (lastDateStr === todayStr) {
                console.log(`✅ Streak bugun allaqachon yangilangan: ${userId}`);
                return;
            }

            const currentStreak = (data['currentStreak'] as number) ?? 0;
            const longestStreak = (data['longestStreak'] as number) ?? 0;

            let newStreak: number;

            if (lastDateStr === null) {
                // Birinchi marta
                newStreak = 1;
            } else {
                const yesterdayStr = toDateStr(new Date(now.getTime() - 86400000));
                if (lastDateStr === yesterdayStr) {
                    // Kecha kelgan → ketma-ketlik davom etadi
                    newStreak = currentStreak + 1;
                } else {
                    // 2+ kun bo'ldi → boshidan
                    newStreak = 1;
                }
            }

            const newLongest = Math.max(longestStreak, newStreak);

            tx.set(progressRef, {
                currentStreak: newStreak,
                longestStreak: newLongest,
                lastActiveDate: admin.firestore.Timestamp.fromDate(now),
            }, { merge: true });

            console.log(`🔥 Streak yangilandi: ${userId} | ${currentStreak} → ${newStreak} kun`);
        });
    } catch (e) {
        // Streak xatosi asosiy oqimni buzmaydi
        console.error(`⚠️ Streak yangilash xatosi (${userId}):`, e);
    }
}

/** Date ni "YYYY-MM-DD" formatiga o'tkazish */
function toDateStr(date: Date): string {
    return date.toISOString().slice(0, 10);
}

// ═══════════════════════════════════════════════════════════════
// PROFIL HISOBLASH
// ═══════════════════════════════════════════════════════════════

async function updateUserProfile(userId: string, latestActivity: ActivityRecord): Promise<void> {
    const db = admin.firestore();

    const activitiesSnap = await db
        .collection('activities')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();

    const activities = activitiesSnap.docs.map(doc => doc.data() as ActivityRecord);

    const skillScores = calculateSkillScores(activities);
    const { weakTopics, strongTopics } = analyzeTopics(activities);
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

function calculateSkillScores(activities: ActivityRecord[]): SkillScoresResult {
    const skillMap: Record<string, number[]> = {
        vocabulary: [],
        grammar: [],
        listening: [],
        speaking: [],
    };

    for (const a of activities) {
        if (a.skillType === 'flashcard') {
            skillMap.vocabulary.push(a.scorePercent);
        } else if (a.skillType === 'quiz') {
            skillMap.vocabulary.push(a.scorePercent * 0.4);
            skillMap.grammar.push(a.scorePercent * 0.6);
        } else if (a.skillType === 'listening') {
            skillMap.listening.push(a.scorePercent);
        } else if (a.skillType === 'speaking') {
            skillMap.speaking.push(a.scorePercent);
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

function analyzeTopics(activities: ActivityRecord[]): {
    weakTopics: string[];
    strongTopics: string[];
} {
    const topicScores: Record<string, { total: number; count: number; errors: number }> = {};

    for (const a of activities) {
        if (!topicScores[a.topic]) {
            topicScores[a.topic] = { total: 0, count: 0, errors: 0 };
        }
        topicScores[a.topic].total += a.scorePercent;
        topicScores[a.topic].count += 1;
        topicScores[a.topic].errors += a.wrongAnswers;
    }

    const sorted = Object.entries(topicScores)
        .map(([topic, data]) => ({
            topic,
            avgScore: data.total / data.count,
            errorRate: data.errors / data.count,
        }))
        .sort((a, b) => a.avgScore - b.avgScore);

    const weakTopics = sorted.slice(0, 5).map(t => t.topic);
    const strongTopics = sorted.slice(-5).reverse().map(t => t.topic);

    return { weakTopics, strongTopics };
}

function scoreToLevel(score: number): string {
    if (score >= 85) return 'B2';
    if (score >= 70) return 'B1';
    if (score >= 55) return 'A2';
    return 'A1';
}

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: TEACHER DASHBOARD — MEMBERS DOC YANGILASH
// ═══════════════════════════════════════════════════════════════

/**
 * O'quvchi mashq bajarganida classes/{classId}/members/{userId} docni
 * yangilaydi — teacher dashboard real vaqtda ko'rsin deb.
 */
async function updateClassMemberStats(userId: string, classId: string): Promise<void> {
    const db = admin.firestore();
    const memberRef = db.collection('classes').doc(classId).collection('members').doc(userId);

    try {
        // Bu o'quvchining so'nggi 50 ta faolligini ol
        const activitiesSnap = await db
            .collection('activities')
            .where('userId', '==', userId)
            .orderBy('timestamp', 'desc')
            .limit(50)
            .get();

        const activities = activitiesSnap.docs.map(d => d.data() as ActivityRecord);
        const totalAttempts = activitiesSnap.size;

        // O'rtacha ball hisoblash (barcha skilllar bo'yicha)
        const avgScore = totalAttempts > 0
            ? Math.round(activities.reduce((sum, a) => sum + (a.scorePercent ?? 0), 0) / totalAttempts)
            : 0;

        // Har bir skill bo'yicha ball
        const skillMap: Record<string, number[]> = { quiz: [], listening: [], speaking: [], flashcard: [] };
        for (const a of activities) {
            if (skillMap[a.skillType]) skillMap[a.skillType].push(a.scorePercent ?? 0);
        }
        const avg = (arr: number[]) => arr.length > 0
            ? Math.round(arr.reduce((a, b) => a + b, 0) / arr.length)
            : 0;
        const skillScores = {
            quiz: avg(skillMap.quiz),
            listening: avg(skillMap.listening),
            speaking: avg(skillMap.speaking),
            flashcard: avg(skillMap.flashcard),
        };

        // Streakni progress collectiondan ol
        const progressDoc = await db.collection('progress').doc(userId).get();
        const currentStreak = progressDoc.exists
            ? ((progressDoc.data()!['currentStreak'] as number) ?? 0)
            : 0;

        await memberRef.set({
            averageScore: avgScore,
            totalAttempts: totalAttempts,
            currentStreak: currentStreak,
            skillScores: skillScores,
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        console.log(`📊 Members doc yangilandi: ${userId} | class: ${classId} | avg: ${avgScore}%`);
    } catch (e) {
        // Members doc yangilanmasa ham asosiy oqim buzilmaydi
        console.error(`⚠️ Members doc yangilash xatosi (${userId}/${classId}):`, e);
    }
}

// ═══════════════════════════════════════════════════════════════
// PROFIL OLISH
// ═══════════════════════════════════════════════════════════════

export async function getUserProfile(userId: string): Promise<UserProfile | null> {
    const db = admin.firestore();
    const doc = await db.collection('userProfiles').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data() as UserProfile;
}

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