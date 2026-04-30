// functions/src/prompts/ai_tutor_engine.ts
// SO'ZONA — AI Murabbiy Engine
// Mavjud content kolleksiyasiga asoslangan aqlli tizim
//
// QANDAY ISHLAYDI:
// 1. O'quvchi quiz/listening/speaking tugatar
// 2. Xatolar mistakes/ ga yoziladi (contentId bilan)
// 3. scheduled_reviews/ da keyingi takrorlash sanaladi (SM-2)
// 4. Adaptive engine content/ dan mos hujjat topadi
// 5. Haftalik analytics/ qo'shiladi (cron job)

import * as admin from 'firebase-admin';

// ═══════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════

export interface MistakeRecord {
    userId: string;
    contentId: string;           // content/{id} hujjat ID si
    contentType: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    skillTag: string;            // 'present_continuous', 'vocabulary', 'listening_detail'
    topic: string;               // 'Travel', 'Daily Life'
    level: string;               // 'A2'
    language: 'en' | 'de';
    errorType: string;           // 'wrong_answer', 'grammar_error', 'pronunciation'
    userAnswer: string;
    correctAnswer: string;
    scorePercent: number;
    timestamp: FirebaseFirestore.Timestamp;
    reviewed: boolean;
}

export interface ScheduledReview {
    userId: string;
    contentId: string;
    contentType: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    topic: string;
    level: string;
    language: 'en' | 'de';
    scheduledFor: FirebaseFirestore.Timestamp;
    intervalDays: number;
    repetitionCount: number;
    lastScore: number;
    reason: 'low_score' | 'regular_review';
    isCompleted: boolean;
}

export interface WeeklyAnalytics {
    userId: string;
    weekId: string;               // '2026-W14'
    lessonsCompleted: number;
    totalMinutes: number;
    avgScore: number;
    skillBreakdown: {
        quiz: { attempts: number; avgScore: number };
        listening: { attempts: number; avgScore: number };
        speaking: { attempts: number; avgScore: number };
        flashcard: { attempts: number; avgScore: number };
    };
    weakContentIds: string[];     // content/ hujjat IDlari
    strongContentIds: string[];
    topMistakeTags: string[];     // 'present_continuous', 'vocabulary'
    generatedAt: FirebaseFirestore.Timestamp;
}

// ═══════════════════════════════════════════════════
// 1. XATO YOZISH
// ═══════════════════════════════════════════════════

export async function saveMistake(params: {
    userId: string;
    contentId: string;
    contentType: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    userAnswer: string;
    correctAnswer: string;
    scorePercent: number;
    language: 'en' | 'de';
}): Promise<void> {
    const db = admin.firestore();
    const { userId, contentId, contentType, userAnswer, correctAnswer, scorePercent, language } = params;

    // content/ dan mavzu va darajani olamiz
    let topic = 'general';
    let level = 'A1';
    let skillTag: string = contentType; // string — grammar mavzu ham bo'lishi mumkin

    try {
        const contentDoc = await db.collection('content').doc(contentId).get();
        if (contentDoc.exists) {
            const d = contentDoc.data()!;
            topic = (d['topic'] as string) ?? 'general';
            level = (d['level'] as string) ?? 'A1';
            skillTag = (d['grammar'] as string) ?? contentType;
        }
    } catch (_) { }

    const mistake: MistakeRecord = {
        userId,
        contentId,
        contentType,
        skillTag,
        topic,
        level,
        language,
        errorType: 'wrong_answer',
        userAnswer,
        correctAnswer,
        scorePercent,
        timestamp: admin.firestore.Timestamp.now(),
        reviewed: false,
    };

    await db.collection('mistakes').add(mistake);

    // Keyingi takrorni rejalashtirish
    await scheduleReview({
        userId, contentId, contentType, topic, level, language, score: scorePercent,
    });

    console.log(`📝 Xato saqlandi: ${userId} | ${contentId} | ${scorePercent}%`);
}

// ═══════════════════════════════════════════════════
// 2. SM-2 SPACED REPETITION
// ═══════════════════════════════════════════════════

export async function scheduleReview(params: {
    userId: string;
    contentId: string;
    contentType: 'quiz' | 'flashcard' | 'listening' | 'speaking';
    topic: string;
    level: string;
    language: 'en' | 'de';
    score: number;
}): Promise<void> {
    const db = admin.firestore();
    const { userId, contentId, score } = params;

    // SM-2 soddalashtirilgan: ball asosida interval
    let intervalDays: number;
    let reason: 'low_score' | 'regular_review';

    if (score >= 85) {
        intervalDays = 7;
        reason = 'regular_review';
    } else if (score >= 70) {
        intervalDays = 3;
        reason = 'regular_review';
    } else if (score >= 50) {
        intervalDays = 1;
        reason = 'low_score';
    } else {
        intervalDays = 0; // darhol — bugun qayta
        reason = 'low_score';
    }

    // Mavjud review bormi?
    const existing = await db.collection('scheduled_reviews')
        .where('userId', '==', userId)
        .where('contentId', '==', contentId)
        .where('isCompleted', '==', false)
        .limit(1)
        .get();

    const scheduledFor = new Date();
    scheduledFor.setDate(scheduledFor.getDate() + intervalDays);

    if (!existing.empty) {
        // Yangilash
        await existing.docs[0].ref.update({
            scheduledFor: admin.firestore.Timestamp.fromDate(scheduledFor),
            intervalDays,
            lastScore: score,
            reason,
            repetitionCount: admin.firestore.FieldValue.increment(1),
        });
    } else {
        // Yangi
        const review: ScheduledReview = {
            userId,
            contentId: params.contentId,
            contentType: params.contentType,
            topic: params.topic,
            level: params.level,
            language: params.language,
            scheduledFor: admin.firestore.Timestamp.fromDate(scheduledFor),
            intervalDays,
            repetitionCount: 1,
            lastScore: score,
            reason,
            isCompleted: false,
        };
        await db.collection('scheduled_reviews').add(review);
    }
}

// ═══════════════════════════════════════════════════
// 3. KEYINGI DARSNI TANLASH
// ═══════════════════════════════════════════════════

export async function getNextRecommendations(params: {
    userId: string;
    language: 'en' | 'de';
    limit?: number;
}): Promise<Array<{
    contentId: string;
    title: string;
    type: string;
    topic: string;
    level: string;
    reason: string;
    reasonUz: string;
    priority: number;
}>> {
    const db = admin.firestore();
    const { userId, language, limit = 5 } = params;
    const recommendations: Array<{
        contentId: string; title: string; type: string;
        topic: string; level: string; reason: string;
        reasonUz: string; priority: number;
    }> = [];

    // A) Muddati o'tgan takrorlar (eng yuqori prioritet)
    const now = admin.firestore.Timestamp.now();
    const dueReviews = await db.collection('scheduled_reviews')
        .where('userId', '==', userId)
        .where('isCompleted', '==', false)
        .where('scheduledFor', '<=', now)
        .orderBy('scheduledFor', 'asc')
        .limit(3)
        .get();

    for (const doc of dueReviews.docs) {
        const d = doc.data() as ScheduledReview;
        const contentDoc = await db.collection('content').doc(d.contentId).get();
        if (!contentDoc.exists) continue;
        const c = contentDoc.data()!;
        recommendations.push({
            contentId: d.contentId,
            title: (c['title'] as string) ?? 'Dars',
            type: (c['type'] as string) ?? 'quiz',
            topic: (c['topic'] as string) ?? '',
            level: (c['level'] as string) ?? '',
            reason: 'spaced_repetition',
            reasonUz: `Takrorlash vaqti keldi — oxirgi ball: ${d.lastScore}%`,
            priority: 100,
        });
    }

    // B) Zaif skill taglarga mos content
    const weakMistakes = await db.collection('mistakes')
        .where('userId', '==', userId)
        .where('reviewed', '==', false)
        .where('language', '==', language)
        .orderBy('timestamp', 'desc')
        .limit(30)
        .get();

    // Skill tag bo'yicha xato soni
    const tagCount: Record<string, number> = {};
    const tagTopics: Record<string, string> = {};
    for (const doc of weakMistakes.docs) {
        const m = doc.data() as MistakeRecord;
        tagCount[m.skillTag] = (tagCount[m.skillTag] ?? 0) + 1;
        tagTopics[m.skillTag] = m.topic;
    }

    // Eng zaif 2 ta tag
    const weakTags = Object.entries(tagCount)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 2)
        .map(([tag]) => tag);

    for (const tag of weakTags) {
        if (recommendations.length >= limit) break;

        // content/ dan shu grammar/tag ga mos hujjat topish
        const contentSnap = await db.collection('content')
            .where('language', '==', language)
            .where('grammar', '==', tag)
            .limit(2)
            .get();

        // Allaqachon tavsiya qilinmagan
        const alreadyIds = recommendations.map(r => r.contentId);
        for (const doc of contentSnap.docs) {
            if (alreadyIds.includes(doc.id)) continue;
            const c = doc.data();
            recommendations.push({
                contentId: doc.id,
                title: (c['title'] as string) ?? 'Dars',
                type: (c['type'] as string) ?? 'quiz',
                topic: (c['topic'] as string) ?? '',
                level: (c['level'] as string) ?? '',
                reason: 'weakness_targeted',
                reasonUz: `Zaif tomoningiz: ${tag} — ${tagCount[tag]} marta xato`,
                priority: 80,
            });
            if (recommendations.length >= limit) break;
        }
    }

    // C) Agar yetarli bo'lmasa — level ga mos yangi content
    if (recommendations.length < limit) {
        // User darajasini olamiz
        const profileDoc = await db.collection('userProfiles').doc(userId).get();
        const userLevel = profileDoc.exists
            ? ((profileDoc.data()!['overallLevel'] as string) ?? 'A1')
            : 'A1';

        const alreadyIds = recommendations.map(r => r.contentId);
        const newContent = await db.collection('content')
            .where('language', '==', language)
            .where('level', '==', userLevel)
            .limit(10)
            .get();

        for (const doc of newContent.docs) {
            if (alreadyIds.includes(doc.id)) continue;
            const c = doc.data();
            recommendations.push({
                contentId: doc.id,
                title: (c['title'] as string) ?? 'Dars',
                type: (c['type'] as string) ?? 'quiz',
                topic: (c['topic'] as string) ?? '',
                level: (c['level'] as string) ?? '',
                reason: 'sequential',
                reasonUz: `${userLevel} darajasiga mos yangi dars`,
                priority: 50,
            });
            if (recommendations.length >= limit) break;
        }
    }

    return recommendations.sort((a, b) => b.priority - a.priority).slice(0, limit);
}

// ═══════════════════════════════════════════════════
// 4. HAFTALIK ANALYTICS
// ═══════════════════════════════════════════════════

export async function generateWeeklyAnalytics(userId: string): Promise<void> {
    const db = admin.firestore();

    const now = new Date();
    const weekMs = 7 * 24 * 60 * 60 * 1000;
    const weekStart = new Date(now.getTime() - weekMs);
    const weekId = getWeekId(now);   // '2026-W14'

    // Bu hafta activities
    const activitiesSnap = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(weekStart))
        .get();

    if (activitiesSnap.empty) return;

    const activities = activitiesSnap.docs.map(d => d.data());

    // Skill breakdown
    const skillBreakdown = {
        quiz: { attempts: 0, avgScore: 0, total: 0 },
        listening: { attempts: 0, avgScore: 0, total: 0 },
        speaking: { attempts: 0, avgScore: 0, total: 0 },
        flashcard: { attempts: 0, avgScore: 0, total: 0 },
    };

    for (const a of activities) {
        const sk = (a['skillType'] as keyof typeof skillBreakdown) ?? 'quiz';
        if (skillBreakdown[sk]) {
            skillBreakdown[sk].attempts++;
            skillBreakdown[sk].total += (a['scorePercent'] as number) ?? 0;
        }
    }

    const finalBreakdown = {
        quiz: {
            attempts: skillBreakdown.quiz.attempts,
            avgScore: avg(skillBreakdown.quiz)
        },
        listening: {
            attempts: skillBreakdown.listening.attempts,
            avgScore: avg(skillBreakdown.listening)
        },
        speaking: {
            attempts: skillBreakdown.speaking.attempts,
            avgScore: avg(skillBreakdown.speaking)
        },
        flashcard: {
            attempts: skillBreakdown.flashcard.attempts,
            avgScore: avg(skillBreakdown.flashcard)
        },
    };

    // Zaif va kuchli content IDlar
    const weakContentIds: string[] = [];
    const strongContentIds: string[] = [];
    for (const a of activities) {
        const cid = a['contentId'] as string | undefined;
        const score = (a['scorePercent'] as number) ?? 0;
        if (!cid) continue;
        if (score < 60 && !weakContentIds.includes(cid)) weakContentIds.push(cid);
        if (score >= 80 && !strongContentIds.includes(cid)) strongContentIds.push(cid);
    }

    // Eng ko'p xato teg
    const mistakesSnap = await db.collection('mistakes')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(weekStart))
        .get();

    const tagCount: Record<string, number> = {};
    for (const d of mistakesSnap.docs) {
        const tag = (d.data()['skillTag'] as string) ?? 'unknown';
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
    const topMistakeTags = Object.entries(tagCount)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([tag]) => tag);

    const totalScores = activities.map(a => (a['scorePercent'] as number) ?? 0);
    const overallAvg = totalScores.length
        ? Math.round(totalScores.reduce((s, v) => s + v, 0) / totalScores.length)
        : 0;

    const analytics: WeeklyAnalytics = {
        userId,
        weekId,
        lessonsCompleted: activities.length,
        totalMinutes: activities.length * 10, // taxminiy: har dars 10 daqiqa
        avgScore: overallAvg,
        skillBreakdown: finalBreakdown,
        weakContentIds: weakContentIds.slice(0, 5),
        strongContentIds: strongContentIds.slice(0, 5),
        topMistakeTags,
        generatedAt: admin.firestore.Timestamp.now(),
    };

    await db.collection('analytics')
        .doc(userId)
        .collection('weekly')
        .doc(weekId)
        .set(analytics);

    console.log(`📊 Haftalik analytics: ${userId} | ${weekId} | ${activities.length} dars`);
}

// ═══════════════════════════════════════════════════
// YORDAMCHI FUNKSIYALAR
// ═══════════════════════════════════════════════════

function avg(s: { attempts: number; total: number }): number {
    return s.attempts > 0 ? Math.round(s.total / s.attempts) : 0;
}

function getWeekId(date: Date): string {
    const d = new Date(date);
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
    const week1 = new Date(d.getFullYear(), 0, 4);
    const weekNum = 1 + Math.round(
        ((d.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7
    );
    return `${d.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}