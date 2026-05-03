// functions/src/index.ts
// SO'ZONA — Cloud Functions Index
// ✅ FIX: generateQuiz — grammar va userId parametrlari uzatiladi
// ✅ FIX: generateListening — grammar va userId parametrlari uzatiladi
// ✅ FIX: safeParseJson() gemini_client.ts da — barcha JSON parse muammolari hal qilindi
// ✅ YANGI: onMemberJoined, onMemberLeft — memberCount avtomatik yangilanadi
// ✅ YANGI: joinClassByCode — student sinfga Cloud Function orqali qo'shiladi (PERMISSION_DENIED hal qilindi)
// ✅ YANGI: Streak tizimi 2-qism — checkStreaks penalty logikasi (daysMissed * 2)

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as https from 'https';

import { generateSpeakingDialog } from './prompts/speaking_dialog';
import { explainTopic as _explainTopic } from './prompts/explain_topic';
import { generateQuiz as _generateQuiz } from './prompts/quiz_generate';
import { generateFlashcards as _generateFlashcards } from './prompts/flashcard_generate';
import { generateListening as _generateListening } from './prompts/listening_generate';
import { generateMotivationMessage } from './prompts/motivation_message';
import { analyzeWeakness as _analyzeWeakness } from './prompts/analyze_weakness';
import { generateAdaptiveQuiz } from './prompts/adaptive_quiz_generate';
import { chatWithTeacher, quickGrammarExplain } from './prompts/ai_chat_conversation';
import { generateSpeakingTask, assessSpeaking } from './prompts/assess_speaking';
import { selectAdaptiveContent } from './prompts/adaptive_content_selector';
import { saveActivity, getUserProfile } from './trackers/user_activity_tracker';
import type { SkillType, DifficultyLevel } from './trackers/user_activity_tracker';
import { onContentPublished, publishScheduledContent } from './triggers/on_content_published';
import { onDataRequest } from './triggers/on_data_request';
import { onMemberJoined, onMemberLeft } from './triggers/on_member_joined';
import { checkRateLimit, checkChatDailyLimit, getChatLimitStatus } from './middleware/rate_limiter';
import { getPremiumCoachAdvice, detectUzbekUser, getVoiceCoachSummary } from './prompts/premium_coach';
import openai from './ai/openai_client'; // ✅ generateSpeech uchun

admin.initializeApp();

// ── Helpers ──
type Lang = 'en' | 'de';
type Level = 'A1' | 'A2' | 'B1' | 'B2' | 'C1';

function requireAuth(ctx: functions.https.CallableContext): string {
    if (!ctx.auth) throw new functions.https.HttpsError('unauthenticated', 'Login qilmagan');
    return ctx.auth.uid;
}

function normalizeAiError(error: unknown, label: string): never {
    console.error(`${label} error:`, error);
    const msg = error instanceof Error ? error.message : String(error);

    if (msg.includes('429') || msg.includes('Too Many Requests') || msg.includes('quota')) {
        throw new functions.https.HttpsError(
            'resource-exhausted',
            'AI hozir band. Iltimos, bir necha daqiqadan keyin qaytadan urinib ko\'ring.'
        );
    }
    if (msg.includes('timeout') || msg.includes('DEADLINE_EXCEEDED')) {
        throw new functions.https.HttpsError(
            'deadline-exceeded',
            'So\'rov vaqti tugadi. Qayta urinib ko\'ring.'
        );
    }
    if (msg.includes('UNAVAILABLE') || msg.includes('unavailable')) {
        throw new functions.https.HttpsError(
            'unavailable',
            'AI server vaqtincha ishlamayapti. Keyinroq urinib ko\'ring.'
        );
    }
    if (msg.includes('INVALID_ARGUMENT') || msg.includes('invalid')) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            `${label}: Noto'g'ri so'rov. Qayta urinib ko'ring.`
        );
    }
    const userMessage = msg.length > 100
        ? `${label} xatolik yuz berdi. Qayta urinib ko'ring.`
        : msg;
    throw new functions.https.HttpsError('internal', userMessage);
}

function fail(error: unknown, label: string): never {
    normalizeAiError(error, label);
}

// ✅ FIX: Flutter enum nomi ('german'/'english') va API kodi ('de'/'en') ikkalasini ham qabul qiladi
function toLang(v: unknown): Lang { return (v === 'de' || v === 'german') ? 'de' : 'en'; }
function toLevel(v: unknown): Level {
    const valid: Level[] = ['A1', 'A2', 'B1', 'B2', 'C1'];
    return valid.includes(v as Level) ? (v as Level) : 'A1';
}

const aiRunWith = {
    timeoutSeconds: 120,
    memory: '512MB' as const,
    secrets: ['GEMINI_KEY'],
};

// ═══════════════════════════════════════
// SPEAKING DIALOG
// ═══════════════════════════════════════

export const createSpeakingDialog = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try { return await generateSpeakingDialog(data as unknown as Parameters<typeof generateSpeakingDialog>[0], uid); }
        catch (e) { normalizeAiError(e, 'Speaking'); }
    });

// ═══════════════════════════════════════
// EXPLAIN TOPIC
// ═══════════════════════════════════════

export const explainTopic = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try { return await _explainTopic(data as unknown as Parameters<typeof _explainTopic>[0], uid); }
        catch (e) { normalizeAiError(e, 'Explain'); }
    });

// ═══════════════════════════════════════
// GENERATE QUIZ
// ═══════════════════════════════════════

export const generateQuiz = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await _generateQuiz({
                language: toLang(data.language),
                level: toLevel(data.level),
                topic: (data.topic as string) ?? 'Daily Life',
                questionCount: (data.questionCount as number) ?? 10,
                difficulty: (data.difficulty as 'easy' | 'medium' | 'hard') ?? 'medium',
                grammar: (data.grammar as string) ?? '',
                weakItems: (data.weakItems as string[]) ?? [],
                userId: (data.save as boolean) !== false ? uid : undefined,
                quizMode: (data.quizMode as 'grammar_only' | 'topic_grammar' | 'passage') ?? 'topic_grammar', // ✅ YANGI
            });
        } catch (e) { normalizeAiError(e, 'Quiz'); }
    });

// ═══════════════════════════════════════
// GENERATE FLASHCARDS
// ═══════════════════════════════════════

export const generateFlashcards = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await _generateFlashcards({
                language: toLang(data.language),
                level: toLevel(data.level),
                topic: (data.topic as string) ?? 'general',
                cardCount: (data.count as number) ?? (data.cardCount as number) ?? 10,
                includeExamples: (data.includeExamples as boolean) ?? true,
                includePronunciation: (data.includePronunciation as boolean) ?? true,
            });
        } catch (e) { normalizeAiError(e, 'Flashcard'); }
    });

// ═══════════════════════════════════════
// GENERATE LISTENING
// ═══════════════════════════════════════

export const generateListening = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await _generateListening({
                language: toLang(data.language),
                level: toLevel(data.level),
                topic: (data.topic as string) ?? 'daily_life',
                duration: (data.duration as number) ?? 60,
                questionCount: (data.questionCount as number) ?? 5,
                grammar: (data.grammar as string) ?? '',
                userId: uid,
            });
        } catch (e) { normalizeAiError(e, 'Listening'); }
    });

// ═══════════════════════════════════════
// MOTIVATION MESSAGE
// ═══════════════════════════════════════

export const getMotivationMessage = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            const streak = (data.currentStreak as number) ?? 0;
            const score = (data.averageScore as number) ?? 50;
            const name = (data.studentName as string) ?? 'Talaba';
            let msgCtx: 'low_performance' | 'good_streak' | 'level_up' | 'long_absence' | 'milestone';
            if (score < 40) msgCtx = 'low_performance';
            else if (streak >= 7) msgCtx = 'milestone';
            else if (streak >= 3) msgCtx = 'good_streak';
            else if (score >= 80) msgCtx = 'level_up';
            else msgCtx = 'good_streak';
            const message = await generateMotivationMessage({
                studentName: name, context: msgCtx,
                language: ((data.language as string) === 'english' ? 'en' : 'uz') as 'uz' | 'en',
                details: { currentStreak: streak, recentScore: score },
            });
            return { message };
        } catch (e) { normalizeAiError(e, 'Motivation'); }
    });

// ═══════════════════════════════════════
// ANALYZE WEAKNESS
// ═══════════════════════════════════════

export const analyzeWeakness = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await _analyzeWeakness({
                studentId: uid,
                language: toLang(data.language),
                currentLevel: (data.level as string) ?? 'A1',
                weakItems: (data.weakItems as Array<{
                    type: 'word' | 'grammar_rule' | 'question';
                    content: string;
                    incorrectCount: number;
                    lastAttempt: string;
                }>) ?? [],
                recentScores: (data.recentScores as number[]) ?? [],
            });
        } catch (e) { normalizeAiError(e, 'Weakness'); }
    });

// ═══════════════════════════════════════
// ADAPTIVE QUIZ
// ═══════════════════════════════════════

export const createAdaptiveQuiz = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await generateAdaptiveQuiz({
                userId: uid,
                language: toLang(data.language),
                level: toLevel(data.level) as string,
                questionCount: (data.questionCount as number) ?? 10,
            });
        } catch (e) { normalizeAiError(e, 'Adaptive Quiz'); }
    });

// ═══════════════════════════════════════
// AI CHAT
// ✅ Tekin: kuniga 10 ta savol
// ✅ Premium: kuniga 20 ta savol, 500 token
// ═══════════════════════════════════════

export const chatWithAI = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkChatDailyLimit(uid);
        try {
            const userSnap = await admin.firestore().collection('users').doc(uid).get();
            const userData = userSnap.data() ?? {};
            const isPremium = (userData.isPremium as boolean) ?? false;
            const premiumExpiresAt = userData.premiumExpiresAt as admin.firestore.Timestamp | undefined;
            const hasActivePremium = isPremium && (!premiumExpiresAt || premiumExpiresAt.toMillis() > Date.now());

            const message = (data.message as string) ?? '';

            // ✅ Natijalar so'ralganda — real statistika qo'shamiz
            const lower = message.toLowerCase();
            const wantsStats = lower.includes('natija') ||
                lower.includes('ko\'rsatkich') ||
                lower.includes('statistika') ||
                lower.includes('progress') ||
                lower.includes('yaxshimi') ||
                lower.includes('darajam') ||
                lower.includes('murabbiy') ||
                (lower.includes('qanday') && (lower.includes('bajar') || lower.includes('o\'qish')));

            let statsContext = '';
            if (wantsStats && hasActivePremium) {
                try {
                    const userName = (userData.displayName as string) ?? "O'quvchi";
                    statsContext = await getVoiceCoachSummary(uid, userName);
                } catch (e) {
                    console.error('Stats context xato:', e);
                }
            }

            return await chatWithTeacher({
                userId: uid,
                message,
                language: toLang(data.language),
                conversationHistory: (data.history as Array<{ role: 'user' | 'assistant'; content: string }>) ?? [],
                isPremium: hasActivePremium,
                statsContext,
            });
        } catch (e) { normalizeAiError(e, 'AI Chat'); }
    });

// ═══════════════════════════════════════
// AI CHAT LIMIT HOLATI (UI uchun)
// ═══════════════════════════════════════

export const getChatStatus = functions
    .region('us-central1')
    .https.onCall(async (_data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            return await getChatLimitStatus(uid);
        } catch (e) { fail(e, 'Chat Status'); }
    });

// ═══════════════════════════════════════
// QUICK GRAMMAR
// ═══════════════════════════════════════

export const quickGrammar = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await quickGrammarExplain({
                topic: (data.topic as string) ?? 'present simple',
                language: toLang(data.language),
                level: (data.level as string) ?? 'A1',
            });
        } catch (e) { normalizeAiError(e, 'Grammar'); }
    });

// ═══════════════════════════════════════
// SPEAKING TASK
// ═══════════════════════════════════════

export const createSpeakingTask = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await generateSpeakingTask({
                userId: uid,
                language: toLang(data.language),
                level: (data.level as string) ?? 'A1',
                topic: data.topic as string | undefined,
                taskType: (data.taskType as 'describe' | 'narrate' | 'opinion' | 'roleplay' | 'read_aloud') ?? 'describe',
            });
        } catch (e) { normalizeAiError(e, 'Speaking Task'); }
    });

// ═══════════════════════════════════════
// SPEAKING ASSESSMENT
// ═══════════════════════════════════════

export const assessSpeakingResult = functions
    .region('us-central1')
    .runWith({ timeoutSeconds: 120, memory: '1GB' as const, secrets: ['GEMINI_KEY'] })
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await assessSpeaking({
                userId: uid,
                taskId: (data.taskId as string) ?? '',
                language: toLang(data.language),
                level: (data.level as string) ?? 'A1',
                topic: (data.topic as string) ?? 'general',
                transcribedText: (data.transcribedText as string) ?? '',
                audioDuration: (data.audioDuration as number) ?? 30,
            });
        } catch (e) { normalizeAiError(e, 'Speaking Assessment'); }
    });

// ═══════════════════════════════════════
// ADAPTIVE CONTENT SELECTOR
// ═══════════════════════════════════════

export const getAdaptivePlan = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await selectAdaptiveContent({
                userId: uid,
                language: toLang(data.language),
                sessionDuration: (data.sessionDuration as number) ?? 10,
            });
        } catch (e) { normalizeAiError(e, 'Adaptive Plan'); }
    });

// ═══════════════════════════════════════
// ACTIVITY SAQLASH
// ═══════════════════════════════════════

export const recordActivity = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            const activityId = await saveActivity({
                userId: uid,
                skillType: (data.skillType as SkillType) ?? 'quiz',
                topic: (data.topic as string) ?? 'general',
                difficulty: (data.difficulty as DifficultyLevel) ?? 'medium',
                correctAnswers: (data.correctAnswers as number) ?? 0,
                wrongAnswers: (data.wrongAnswers as number) ?? 0,
                responseTime: (data.responseTime as number) ?? 0,
                vocabularyUsed: (data.vocabularyUsed as string[]) ?? [],
                grammarErrors: (data.grammarErrors as string[]) ?? [],
                language: toLang(data.language),
                level: (data.level as string) ?? 'A1',
                timestamp: admin.firestore.Timestamp.now(),
                scorePercent: (data.scorePercent as number) ?? 0,
                weakItems: (data.weakItems as string[]) ?? [],
                strongItems: (data.strongItems as string[]) ?? [],
                sessionId: data.sessionId as string | undefined,
                contentId: data.contentId as string | undefined,
                classId: data.classId as string | undefined, // ✅ YANGI
            });
            return { activityId, success: true };
        } catch (e) { fail(e, 'Activity Record'); }
    });

// ═══════════════════════════════════════
// USER PROFIL
// ═══════════════════════════════════════

export const fetchUserProfile = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (_data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            const profile = await getUserProfile(uid);
            return profile ?? {
                userId: uid,
                vocabularyLevel: 50,
                grammarLevel: 50,
                listeningLevel: 50,
                speakingLevel: 50,
                weakTopics: [],
                strongTopics: [],
                overallLevel: 'A1',
                totalActivities: 0,
                averageScore: 0,
            };
        } catch (e) { fail(e, 'User Profile'); }
    });

// ═══════════════════════════════════════
// TEACHER FUNCTIONS
// ═══════════════════════════════════════

export const getTeachingAdvice = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            const { aiRouter } = await import('./ai/ai_router');
            const avgScore = (data.avgScore as number) ?? 0;
            const active = (data.activeStudents as number) ?? 0;
            const total = (data.totalStudents as number) ?? 0;
            const skills = data.skillBreakdown as Record<string, number> ?? {};
            const prompt = `You are a teaching advisor. Class: ${active}/${total} active, avg ${avgScore}%. Skills: ${JSON.stringify(skills)}. Give 2-3 actionable advice in Uzbek Latin. Return ONLY text.`;
            const resp = await aiRouter({ prompt, maxTokens: 200, temperature: 0.7, schema: null });
            const advice = (resp.text ?? resp.content ?? '').replace(/```/g, '').trim();
            return { advice: advice || `${active} faol o'quvchi, ${avgScore}% ball. Zaif joylarga e'tibor bering!` };
        } catch (e) {
            console.error('Teaching advice error:', e);
            return { advice: 'Sinfingiz yaxshi rivojlanmoqda! Davom eting.' };
        }
    });

export const getProactiveSuggestion = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            const { aiRouter } = await import('./ai/ai_router');
            const lang = (data.language as string) ?? 'english';
            const level = (data.level as string) ?? 'A1';
            const weak = (data.weakAreas as string[]) ?? [];
            const days = (data.daysSinceLastSession as number) ?? 0;
            const streak = (data.currentStreak as number) ?? 0;
            let sType = 'quiz', urgency = 'medium';
            if (days > 3) { sType = 'flashcard'; urgency = 'high'; }
            else if (weak.length > 3) { urgency = 'high'; }
            else if (streak >= 5) { sType = 'listening'; urgency = 'low'; }
            const label = lang === 'german' ? 'nemis' : 'ingliz';
            const prompt = `Proactive coach. Student: ${label} ${level}. Streak ${streak}d. Absent ${days}d. Weak: ${weak.join(',') || 'none'}. ONE short Uzbek suggestion (2 sent). Return ONLY text.`;
            const resp = await aiRouter({ prompt, maxTokens: 100, temperature: 0.8, schema: null });
            const msg = (resp.text ?? resp.content ?? '').replace(/```/g, '').trim();
            return { message: msg || 'Bugun mashq qilish uchun ajoyib kun! 🚀', suggestionType: sType, urgency };
        } catch (e) {
            console.error('Proactive suggestion error:', e);
            return { message: 'Bugun mashq uchun ajoyib kun! 🚀', suggestionType: 'quiz', urgency: 'medium' };
        }
    });

// ═══════════════════════════════════════
// ✅ YANGI: JOIN CLASS BY CODE
// Student sinfga qo'shiladi — admin SDK orqali (Firestore Rules bypass)
// Sabab: Student classes/{id}/members/ ga to'g'ridan yoza olmaydi
// ═══════════════════════════════════════

export const joinClassByCode = functions
    .region('us-central1')
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);

        const joinCode = ((data.joinCode as string) ?? '').toUpperCase().trim();
        const studentName = (data.studentName as string) ?? '';
        const studentLevel = (data.studentLevel as string) ?? 'A1';

        if (!joinCode || joinCode.length !== 6) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Kod 6 ta belgidan iborat bo\'lishi kerak'
            );
        }

        const db = admin.firestore();

        // 1. Join code bo'yicha sinf topish
        const classSnap = await db.collection('classes')
            .where('joinCode', '==', joinCode)
            .where('isActive', '==', true)
            .limit(1)
            .get();

        if (classSnap.empty) {
            throw new functions.https.HttpsError('not-found', 'Bunday kod bilan sinf topilmadi');
        }

        const classDoc = classSnap.docs[0];
        const classId = classDoc.id;
        const classRef = db.collection('classes').doc(classId);
        const memberRef = classRef.collection('members').doc(uid);

        // ✅ FIX: limit tekshiruvi va qo'shish — bitta atomik transaction ichida
        // Avval: tekshiruv tashqarida (eski ma'lumot) → 2 kishi bir vaqtda kirsa limit oshib ketardi
        // Yangi: transaction ichida yangi o'qish → haqiqiy, hozirgi holat tekshiriladi
        const now = admin.firestore.Timestamp.now();
        await db.runTransaction(async (tx) => {
            // Transaction ichida YANGI o'qish — hozirgi haqiqiy holat
            const [freshClassSnap, memberDoc] = await Promise.all([
                tx.get(classRef),
                tx.get(memberRef),
            ]);

            // 2. Allaqachon a'zo emasligini tekshirish
            if (memberDoc.exists) {
                throw new functions.https.HttpsError(
                    'already-exists',
                    'Siz bu sinfga allaqachon a\'zo siz'
                );
            }

            // 3. Sinf to'liq emasligini ATOMIK tekshirish
            const freshData = freshClassSnap.data() ?? {};
            const maxStudents = (freshData['maxStudents'] as number) ?? 50;
            const memberCount = (freshData['memberCount'] as number) ?? 0;
            if (memberCount >= maxStudents) {
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    'Sinf to\'liq. Boshqa sinfga qo\'shiling.'
                );
            }

            // 4. Atomik qo'shish
            tx.set(memberRef, {
                userId: uid,
                fullName: studentName,
                level: studentLevel,
                joinedAt: now,
                lastActiveAt: now,
                averageScore: 0.0,
                totalAttempts: 0,
                currentStreak: 0,
                avatarUrl: null,
            });
            // memberCount trigger (onMemberJoined) tomonidan yangilanadi
        });

        console.log(`✅ Student ${uid} joined class ${classId} with code ${joinCode}`);

        // ✅ M4 FIX: memberCount + 1 o'chirildi
        // Avvalgi: memberCount+1 qaytardi — lekin real increment onMemberJoined trigger'da asinxron
        // Yangi: Flutter UI stream orqali haqiqiy qiymatni o'qiydi
        return {
            success: true,
            classId,
            // ✅ FIX: classData o'chirildi — freshData (transaction dan) ishlatiladi
            className: classDoc.data()?.['name'] ?? '',
            teacherId: classDoc.data()?.['teacherId'] ?? '',
            joinCode,
        };
    });

// ═══════════════════════════════════════
// TRIGGERS
// ═══════════════════════════════════════

export { onContentPublished };
export { publishScheduledContent };
export { onDataRequest };

// ✅ YANGI: Student sinfga qo'shilganda/chiqganda memberCount avtomatik yangilanadi
export { onMemberJoined, onMemberLeft };

// ═══════════════════════════════════════
// HEALTH CHECK
// ═══════════════════════════════════════


// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: PREMIUM AI MURABBIY
// ✅ Backend da premium tekshiruvi — tekin foydalanuvchi kira olmaydi
// ✅ OpenAI bilan mashqlarni o'zi yaratadi
// ═══════════════════════════════════════════════════════════════

export const premiumCoach = functions
    .region('us-central1')
    .runWith({ ...aiRunWith, secrets: ['GEMINI_KEY', 'OPENAI_KEY'] })
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);

        // ✅ BACKEND PREMIUM TEKSHIRUVI
        const userSnap = await admin.firestore().collection('users').doc(uid).get();
        const userData = userSnap.data() ?? {};
        const isPremium = (userData.isPremium as boolean) ?? false;
        const premiumExpiresAt = userData.premiumExpiresAt as admin.firestore.Timestamp | undefined;
        const hasActivePremium = isPremium && (!premiumExpiresAt || premiumExpiresAt.toMillis() > Date.now());

        if (!hasActivePremium) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Bu funksiya faqat premium foydalanuvchilar uchun. Premium oling!'
            );
        }

        try {
            return await getPremiumCoachAdvice({
                userId: uid,
                studentName: (data.studentName as string) ?? "O'quvchi",
                language: toLang(data.language),
                level: (data.level as string) ?? 'A1',
                trigger: (data.trigger as 'after_lesson' | 'daily_check' | 'weak_area' | 'motivation') ?? 'daily_check',
                skillType: data.skillType as 'quiz' | 'flashcard' | 'listening' | 'speaking' | undefined,
                lastScore: data.lastScore as number | undefined,
                dailyGoalMinutes: data.dailyGoalMinutes as number | undefined,
                sessionData: data.sessionData as Record<string, unknown> | undefined, // ✅ YANGI
            });
        } catch (e) { normalizeAiError(e, 'Premium Coach'); }
    });

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: O'ZBEKISTON ANIQLOVCHI
// ═══════════════════════════════════════════════════════════════

export const checkUzbekUser = functions
    .region('us-central1')
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            const result = await detectUzbekUser({
                deviceLocale: (data.deviceLocale as string) ?? 'en',
                ipCountry: ctx.rawRequest?.headers?.['x-appengine-country'] as string | undefined
                    ?? (data.ipCountry as string | undefined),
            });

            // O'zbek bo'lsa — Firestore da avtomatik belgilash
            if (result.isUzbek) {
                const db = admin.firestore();
                await db.collection('users').doc(uid).update({
                    isUzbekUser: true,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            return result;
        } catch (e) {
            console.error('checkUzbekUser error:', e);
            return { isUzbek: false, reason: "Aniqlab bo'lmadi" };
        }
    });

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: OPENAI TABIIY OVOZ (TTS) — Premium foydalanuvchilar uchun
// Flutter AudioPlayerWidget useOpenAiTts:true bo'lsa shu endpointni chaqiradi
// Javobi: { audio: base64mp3, format: 'mp3', voice: string, charCount: number }
// ═══════════════════════════════════════════════════════════════

export const generateSpeech = functions
    .region('us-central1')
    .runWith({ timeoutSeconds: 60, memory: '512MB' as const, secrets: ['OPENAI_KEY'], minInstances: 1 })
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);

        // Premium tekshiruvi
        const userSnap = await admin.firestore().collection('users').doc(uid).get();
        const userData = userSnap.data() ?? {};
        const isPremium = (userData.isPremium as boolean) ?? false;
        const premiumExpiresAt = userData.premiumExpiresAt as admin.firestore.Timestamp | undefined;
        const hasActivePremium = isPremium && (!premiumExpiresAt || premiumExpiresAt.toMillis() > Date.now());

        if (!hasActivePremium) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Bu funksiya faqat premium foydalanuvchilar uchun.'
            );
        }

        const text = ((data.text as string) ?? '').trim();
        if (!text) {
            throw new functions.https.HttpsError('invalid-argument', "Matn bo'sh");
        }
        // OpenAI TTS max 4096 belgi
        const truncated = text.length > 4096 ? text.slice(0, 4096) : text;

        const voice = (data.voice as string) ?? 'shimmer';
        const speed = Math.max(0.25, Math.min(4.0, (data.speed as number) ?? 0.9));

        try {
            const response = await openai.audio.speech.create({
                model: 'tts-1-hd', // ✅ Yuqori sifatli model
                voice: voice as 'nova' | 'alloy' | 'echo' | 'fable' | 'onyx' | 'shimmer',
                input: truncated,
                response_format: 'mp3',
                speed,
            });

            const buffer = Buffer.from(await response.arrayBuffer());
            return {
                audio: buffer.toString('base64'),
                format: 'mp3',
                voice,
                charCount: truncated.length,
            };
        } catch (e) {
            console.error('⚠️ OpenAI TTS xatosi:', e);
            throw new functions.https.HttpsError('internal', 'Ovoz yaratishda xatolik yuz berdi');
        }
    });

// ═══════════════════════════════════════════════════════════════
// PROMO KOD AKTIVISATIYA
// ═══════════════════════════════════════════════════════════════

export const redeemPromoCode = functions
    .region('us-central1')
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        const db = admin.firestore();

        const code = ((data.code as string) ?? '').toUpperCase().trim();

        if (!code || code.length < 4) {
            throw new functions.https.HttpsError('invalid-argument', "Promo kod noto'g'ri");
        }

        const promoRef = db.collection('promoCodes').doc(code);
        const usedByRef = promoRef.collection('usedBy').doc(uid);
        const userRef = db.collection('users').doc(uid);

        // ✅ FIX: batch → transaction
        const premiumUntil = await db.runTransaction(async (t) => {
            const promoSnap = await t.get(promoRef);
            const usedBySnap = await t.get(usedByRef);

            if (!promoSnap.exists) {
                throw new functions.https.HttpsError('not-found', 'Promo kod topilmadi');
            }

            const promo = promoSnap.data()!;

            const now = admin.firestore.Timestamp.now();
            if (promo.expiresAt && promo.expiresAt.toMillis() < now.toMillis()) {
                throw new functions.https.HttpsError('failed-precondition', 'Promo kod muddati tugagan');
            }

            const maxUses: number = promo.maxUses ?? 1;
            const usedCount: number = promo.usedCount ?? 0;
            if (usedCount >= maxUses) {
                throw new functions.https.HttpsError('resource-exhausted', "Promo kod o'z limitiga yetdi");
            }

            if (usedBySnap.exists) {
                throw new functions.https.HttpsError('already-exists', 'Siz bu promo kodni allaqachon ishlatgansiz');
            }

            const userSnap = await t.get(userRef);
            const userData = userSnap.data() ?? {};
            const existingExpiry = userData.premiumExpiresAt?.toDate?.() as Date | undefined;
            const baseDate = existingExpiry && existingExpiry > new Date() ? existingExpiry : new Date();
            const until = new Date(baseDate);
            until.setMonth(until.getMonth() + (promo.durationMonths ?? 1));

            t.update(userRef, {
                isPremium: true,
                premiumExpiresAt: admin.firestore.Timestamp.fromDate(until),
                premiumSource: 'promo_code',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            t.update(promoRef, {
                usedCount: admin.firestore.FieldValue.increment(1),
            });

            t.set(usedByRef, {
                uid,
                redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return until;
        });

        // ✅ O4 FIX: db2 o'rniga mavjud db ishlatiladi — ortiqcha instance yo'q
        const expiryFormatted = premiumUntil.toLocaleDateString('uz-UZ', {
            year: 'numeric', month: 'long', day: 'numeric',
        });
        await db.collection('notifications').add({
            userId: uid,
            type: 'premium_activated',
            title: '🎉 Premium faollashdi!',
            body: `Tabriklaymiz! Premium obunangiz ${expiryFormatted} gacha faol. Barcha imkoniyatlar ochiq!`,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
            success: true,
            premiumUntil: premiumUntil.toISOString(),
            message: 'Premium bir oyga faollashdi!',
        };
    });

// ✅ YANGI: Muddati o'tgan premiumlarni avtomatik o'chirish (har kuni soat 03:00 Toshkent)
// ─────────────────────────────────────────────────────────────────────────
// PREMIUM TUGASH OGOHLANTIRISHI — har kuni 01:00 Toshkent
// ✅ YANGI: premiumExpiresAt 1-2 kun qolganda foydalanuvchiga push yuboradi
// expireOldPremiums (03:00) dan 2 soat oldin ishlaydi — foydalanuvchi tayyor bo'ladi
// ─────────────────────────────────────────────────────────────────────────
export const warnExpiringPremiums = functions
    .region('us-central1')
    .pubsub.schedule('0 1 * * *')
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();

        // 1-2 kun ichida tugaydigan premiumlar
        const in1Day = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const in2Days = new Date(now.getTime() + 48 * 60 * 60 * 1000);

        const snap = await db.collection('users')
            .where('isPremium', '==', true)
            .where('premiumExpiresAt', '>=', admin.firestore.Timestamp.fromDate(in1Day))
            .where('premiumExpiresAt', '<=', admin.firestore.Timestamp.fromDate(in2Days))
            .get();

        if (snap.empty) {
            console.log('Premium muddati yaqin foydalanuvchi yo\'q');
            return;
        }

        let sentCount = 0;
        for (const doc of snap.docs) {
            const uid = doc.id;
            const expiresAt = (doc.data().premiumExpiresAt as admin.firestore.Timestamp).toDate();
            const hoursLeft = Math.round((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60));
            const label = hoursLeft <= 24 ? 'ertaga' : '2 kunda';

            await sendFcmToUser(
                db,
                uid,
                {
                    title: '⚠️ Premium tarifingiz tugayapti',
                    body: `Premium tarifingiz ${label} tugaydi. Uzluksiz o'qishni davom ettirishingiz uchun yangilang!`,
                },
                {
                    type: 'premium_expiry',
                    title: '⚠️ Premium tarifingiz tugayapti',
                    body: `Premium tarifingiz ${label} tugaydi. Uzluksiz o'qishni davom ettirishingiz uchun yangilang!`,
                },
                'premium_channel'
            );
            sentCount++;
        }

        console.log(`✅ Premium ogohlantirish: ${sentCount} ta foydalanuvchiga yuborildi`);
    });

export const expireOldPremiums = functions
    .region('us-central1')
    .pubsub.schedule('0 3 * * *')
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();

        const snap = await db.collection('users')
            .where('isPremium', '==', true)
            .where('premiumExpiresAt', '<', now)
            .get();

        if (snap.empty) {
            console.log('Muddati o\'tgan premium yo\'q');
            return;
        }

        const batches: FirebaseFirestore.WriteBatch[] = [];
        let batch = db.batch();
        let count = 0;

        for (const doc of snap.docs) {
            // ✅ M2 FIX: premiumExpiresAt ham tozalanadi
            // Avvalgi: faqat isPremium:false → eski sana qolardi, kod premiumExpiresAt o'qisa xato
            batch.update(doc.ref, {
                isPremium: false,
                premiumExpiresAt: admin.firestore.FieldValue.delete(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            count++;
            if (count % 499 === 0) {
                batches.push(batch);
                batch = db.batch();
            }
        }
        batches.push(batch);

        await Promise.all(batches.map(b => b.commit()));
        console.log(`✅ ${snap.size} ta premium muddati o'tgan: o'chirildi`);
    });

// ═══════════════════════════════════════════════════════════════
// ✅ FIX 3: VERIFY IAP PURCHASE — Google Play tasdiqlash
// ═══════════════════════════════════════════════════════════════
export const verifyPurchase = functions
    .region('us-central1')
    .runWith({ timeoutSeconds: 30, memory: '256MB' as const })
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        const db = admin.firestore();

        const productId = (data.productId as string) ?? '';
        const purchaseToken = (data.purchaseToken as string) ?? '';
        const packageName = (data.packageName as string) ?? '';

        if (!productId || !purchaseToken || !packageName) {
            throw new functions.https.HttpsError('invalid-argument', "productId, purchaseToken va packageName kerak");
        }

        const userRef = db.collection('users').doc(uid);
        const userSnap = await userRef.get();
        if (!userSnap.exists) {
            throw new functions.https.HttpsError('not-found', "Foydalanuvchi topilmadi");
        }

        // ─── Token qayta ishlatilganini tekshirish ───────────────────────────
        // ✅ FIX: Bilet yirtish — bir token bir martagina ishlatilishi mumkin
        // Avval: tokenni saqlamardi → bir token bilan ikki marta premium olsa bo'lardi
        // Yangi: 'used_purchase_tokens' kolleksiyasida saqlanadi → ikkinchi urinish bloklanadi
        const tokenRef = db.collection('used_purchase_tokens').doc(
            // Token uzun bo'lishi mumkin — Firestore ID uchun url-safe base64
            // + → -, / → _, = olib tashlanadi (Firestore ID da / muammo yaratadi)
            Buffer.from(purchaseToken).toString('base64')
                .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '').slice(0, 500)
        );
        const tokenSnap = await tokenRef.get();
        if (tokenSnap.exists) {
            console.warn(`❌ Token qayta ishlatildi: uid=${uid}, product=${productId}`);
            throw new functions.https.HttpsError('already-exists', "Bu xarid allaqachon tasdiqlangan");
        }

        // ─── Google Play Developer API orqali token tasdiqlash ───────────────
        // Service account credentials Firebase Admin SDK dan olinadi
        let accessToken: string;
        try {
            const tokenResponse = await admin.app().options.credential!.getAccessToken();
            accessToken = tokenResponse.access_token;
        } catch (e) {
            console.error('Access token olishda xatolik:', e);
            throw new functions.https.HttpsError('internal', "Tasdiqlash xizmati ishlamayapti");
        }

        // Google Play API: subscription yoki product tekshirish
        const isSubscription = productId.includes('monthly') || productId.includes('yearly') || productId.includes('sub');
        const apiPath = isSubscription
            ? `/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`
            : `/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`;

        const playResponse = await new Promise<Record<string, unknown>>((resolve, reject) => {
            const options = {
                hostname: 'androidpublisher.googleapis.com',
                path: apiPath,
                method: 'GET',
                headers: { Authorization: `Bearer ${accessToken}` },
            };
            const req = https.request(options, (res) => {
                let body = '';
                res.on('data', (chunk: Buffer) => { body += chunk.toString(); });
                res.on('end', () => {
                    try {
                        const parsed = JSON.parse(body) as Record<string, unknown>;
                        if (res.statusCode === 200) resolve(parsed);
                        else reject(new Error(`Play API ${res.statusCode}: ${body}`));
                    } catch (e) { reject(new Error("Play API javobini parse qilib bo'lmadi")); }
                });
            });
            req.on('error', reject);
            req.end();
        });

        // ─── Tasdiqlash natijasini tekshirish ────────────────────────────────
        // ✅ FIX: subscription uchun expiryTimeMillis saqlash uchun tashqariga chiqarildi
        let subscriptionExpiryMs = 0;

        if (isSubscription) {
            // subscriptionState: 1=faol, 2=to'xtatilgan, 3=muddati tugagan va h.k.
            const state = playResponse['subscriptionState'] as number | undefined;
            // paymentState: 0=kutilmoqda, 1=to'langan
            const paymentState = playResponse['paymentState'] as number | undefined;
            const isValid = state === 1 && paymentState === 1;
            if (!isValid) {
                console.warn(`❌ Subscription invalid: uid=${uid}, state=${state}, payment=${paymentState}`);
                throw new functions.https.HttpsError('permission-denied', "Xarid tasdiqlanmadi");
            }
            // expiryTimeMillis — Google Play dagi haqiqiy tugash sanasi
            subscriptionExpiryMs = parseInt((playResponse['expiryTimeMillis'] as string) ?? '0', 10);
            if (subscriptionExpiryMs < Date.now()) {
                throw new functions.https.HttpsError('permission-denied', "Obuna muddati tugagan");
            }
        } else {
            // purchaseState: 0=xarid qilingan, 1=bekor qilingan, 2=kutilmoqda
            const purchaseState = playResponse['purchaseState'] as number | undefined;
            if (purchaseState !== 0) {
                console.warn(`❌ Purchase invalid: uid=${uid}, purchaseState=${purchaseState}`);
                throw new functions.https.HttpsError('permission-denied', "Xarid tasdiqlanmadi");
            }
        }

        // ─── Tasdiqlangan — Firestore yangilash ─────────────────────────────
        const now = admin.firestore.Timestamp.now();
        const isYearly = productId.includes('yearly');

        // ✅ FIX: Subscription bo'lsa — Google Play expiryTimeMillis ishlatiladi
        // (haqiqiy tugash sanasi, server vaqtiga bog'liq emas).
        // One-time purchase bo'lsa — server vaqtidan 1 oy/1 yil qo'shiladi.
        const expireDate = isSubscription && subscriptionExpiryMs > 0
            ? new Date(subscriptionExpiryMs)
            : (() => {
                const d = new Date();
                d.setMonth(d.getMonth() + (isYearly ? 12 : 1));
                return d;
            })();

        // ✅ FIX: Tokenni "ishlatilgan" deb belgilash (premium yozish bilan birga)
        // Agar userRef.update muvaffaqiyatli bo'lsa — token ham saqlanadi
        await userRef.update({
            isPremium: true,
            premiumProductId: productId,
            premiumSource: 'iap',
            premiumStartedAt: now,
            premiumExpiresAt: admin.firestore.Timestamp.fromDate(expireDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Tokenni ishlatilgan deb belgilash — keyingi urinish bloklanadi
        await tokenRef.set({
            uid,
            productId,
            usedAt: now,
            packageName,
        });

        await db.collection('notifications').add({
            userId: uid,
            type: 'premium_activated',
            title: '🎉 Premium faollashdi!',
            body: `Tabriklaymiz! Premium obunangiz ${isYearly ? '1 yil' : '1 oy'} muddatga faol. Barcha imkoniyatlar ochiq!`,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ IAP verified (Google Play): uid=${uid}, product=${productId}`);
        return { verified: true };
    });

// ═══════════════════════════════════════════════════════════════
// CLAIM DAILY REWARD — Kundalik quti mukofoti (server-side)
// Mukofot serverdа tanlanadi va yoziladi — client manipulyatsiya qila olmaydi
// ═══════════════════════════════════════════════════════════════
export const claimDailyReward = functions
    .region('us-central1')
    .https.onCall(async (_data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        const db = admin.firestore();
        const progressRef = db.collection('progress').doc(uid);
        const userRef = db.collection('users').doc(uid);
        const now = admin.firestore.Timestamp.now();

        // ✅ K1 FIX: race condition bartaraf — tekshiruv transaction ICHIDA
        // Avvalgi kod: tekshiruv tashqarida → 2 parallel so'rov ikki mukofot olardi
        // Yangi kod: barcha o'qish+tekshiruv+yozish bitta atomik transactionda
        const roll = Math.floor(Math.random() * 100);
        let rewardType: string;
        if (roll < 40) rewardType = 'xp50';
        else if (roll < 60) rewardType = 'xp100';
        else if (roll < 70) rewardType = 'premiumDay';
        else if (roll < 80) rewardType = 'badge';
        else rewardType = 'nothing';

        await db.runTransaction(async (tx) => {
            // 1. Transaction ichida o'qish — atomik tekshiruv
            const progressSnap = await tx.get(progressRef);
            if (progressSnap.exists) {
                const lastOpen = progressSnap.data()?.lastBoxOpenDate as admin.firestore.Timestamp | undefined;
                if (lastOpen) {
                    const lastDate = lastOpen.toDate();
                    const lastDay = new Date(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate());
                    const today = new Date();
                    const todayDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
                    if (lastDay.getTime() >= todayDay.getTime()) {
                        throw new functions.https.HttpsError('failed-precondition', 'Bugun quti allaqachon ochilgan');
                    }
                }
            }

            // 2. Mukofot yozish
            const progressUpdate: Record<string, unknown> = { lastBoxOpenDate: now };

            if (rewardType === 'xp50') {
                progressUpdate['totalXp'] = admin.firestore.FieldValue.increment(50);
                tx.update(userRef, { totalXp: admin.firestore.FieldValue.increment(50) });
            } else if (rewardType === 'xp100') {
                progressUpdate['totalXp'] = admin.firestore.FieldValue.increment(100);
                tx.update(userRef, { totalXp: admin.firestore.FieldValue.increment(100) });
            } else if (rewardType === 'badge') {
                // ✅ M3 FIX: badge users/{uid} ga ham yoziladi (progress + users)
                progressUpdate['badges'] = admin.firestore.FieldValue.arrayUnion(['lucky_star']);
                tx.update(userRef, { badges: admin.firestore.FieldValue.arrayUnion(['lucky_star']) });
            } else if (rewardType === 'premiumDay') {
                const userSnap = await tx.get(userRef);
                const userData = userSnap.data() ?? {};
                const existing = userData['premiumExpiresAt'] as admin.firestore.Timestamp | undefined;
                const base = existing && existing.toMillis() > now.toMillis()
                    ? existing.toDate()
                    : now.toDate();
                const newExpiry = new Date(base);
                newExpiry.setDate(newExpiry.getDate() + 1);
                tx.update(userRef, {
                    isPremium: true,
                    premiumExpiresAt: admin.firestore.Timestamp.fromDate(newExpiry),
                    premiumSource: 'daily_reward',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            tx.set(progressRef, progressUpdate, { merge: true });
        });

        console.log(`✅ Daily reward: ${uid} → ${rewardType}`);
        return { rewardType };
    });

export const healthCheck = functions.region('us-central1').https
    .onRequest((_req: functions.https.Request, res: functions.Response) => {
        res.json({
            status: 'ok',
            timestamp: new Date().toISOString(),
            version: '3.5.0',
            fixes: [
                'json_parse_fix', 'grammar_per_level', 'firestore_index',
                'member_count_trigger', 'join_class_permission_fix',
                'promo_code_added', 'uzbek_free_removed',
                'verify_purchase_added',
                'expire_all_premium_sources',
                'streak_penalty_logic',
            ],
        });
    });

// ═══════════════════════════════════════════════════════════════
// AI MURABBIY TIZIMI — YANGI FUNKSIYALAR
// ═══════════════════════════════════════════════════════════════

import {
    saveMistake,
    getNextRecommendations,
    generateWeeklyAnalytics,
    scheduleReview,
} from './prompts/ai_tutor_engine';

// ── Xato yozish (quiz/listening/speaking tugaganda chaqiriladi) ──
export const recordMistake = functions
    .region('us-central1')
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            await saveMistake({
                userId: uid,
                contentId: (data.contentId as string) ?? '',
                contentType: (data.contentType as 'quiz' | 'flashcard' | 'listening' | 'speaking') ?? 'quiz',
                userAnswer: (data.userAnswer as string) ?? '',
                correctAnswer: (data.correctAnswer as string) ?? '',
                scorePercent: (data.scorePercent as number) ?? 0,
                language: toLang(data.language),
            });
            return { success: true };
        } catch (e) { fail(e, 'RecordMistake'); }
    });

// ── Tavsiyalar ──
export const getRecommendations = functions
    .region('us-central1')
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            const recs = await getNextRecommendations({
                userId: uid,
                language: toLang(data.language),
                limit: (data.limit as number) ?? 5,
            });
            return { recommendations: recs };
        } catch (e) { fail(e, 'GetRecommendations'); }
    });

// ── Takrorlashni tugallash ──
export const completeReview = functions
    .region('us-central1')
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            const db = admin.firestore();
            const contentId = (data.contentId as string) ?? '';
            const score = (data.scorePercent as number) ?? 0;

            const snap = await db.collection('scheduled_reviews')
                .where('userId', '==', uid)
                .where('contentId', '==', contentId)
                .where('isCompleted', '==', false)
                .limit(1)
                .get();

            if (!snap.empty) {
                await snap.docs[0].ref.update({ isCompleted: true });
            }

            const contentDoc = await db.collection('content').doc(contentId).get();
            const cd = contentDoc.exists ? contentDoc.data()! : {};
            await scheduleReview({
                userId: uid,
                contentId,
                contentType: ((cd['type'] as string) ?? 'quiz') as 'quiz' | 'flashcard' | 'listening' | 'speaking',
                topic: (cd['topic'] as string) ?? 'general',
                level: (cd['level'] as string) ?? 'A1',
                language: toLang(data.language),
                score,
            });

            return { success: true };
        } catch (e) { fail(e, 'CompleteReview'); }
    });

// ── Haftalik analytics (har dushanba 07:00 Toshkent) ──
// ✅ FIX: Barcha userlarni bir vaqtda yuklamaslik — 50 tadan batch
export const generateWeeklyReport = functions
    .region('us-central1')
    .runWith({ timeoutSeconds: 540, memory: '512MB' as const })
    .pubsub.schedule('0 7 * * 1')
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const BATCH_SIZE = 50;
        // ✅ FIX: Bir vaqtda 10 ta parallel — 10x tezroq, timeout xavfi yo'q
        // Avval: ketma-ket → 300 user × 3 sek = 900 sek → TIMEOUT (limit 540 sek)
        // Yangi: 10 ta parallel → 300 user / 10 × 3 sek = 90 sek → xavfsiz
        const PARALLEL = 10;
        let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;
        let totalProcessed = 0;
        let totalFailed = 0;

        while (true) {
            let query = db.collection('users').limit(BATCH_SIZE);
            if (lastDoc) query = query.startAfter(lastDoc) as typeof query;

            const snap = await query.get();
            if (snap.empty) break;

            // 50 ta userlarni 10 tali guruhlarga bo'lib, parallel ishlat
            for (let i = 0; i < snap.docs.length; i += PARALLEL) {
                const chunk = snap.docs.slice(i, i + PARALLEL);
                const results = await Promise.allSettled(
                    chunk.map(doc => generateWeeklyAnalytics(doc.id))
                );
                results.forEach((r, idx) => {
                    if (r.status === 'rejected') {
                        totalFailed++;
                        console.error(`⚠️ Analytics xatosi (${chunk[idx].id}):`, r.reason);
                    }
                });
            }

            totalProcessed += snap.size;
            lastDoc = snap.docs[snap.docs.length - 1];
            if (snap.size < BATCH_SIZE) break;
        }

        console.log(`✅ Haftalik analytics tugadi: ${totalProcessed} ta user, ${totalFailed} ta xato`);
    });

// ── Bir user uchun darhol haftalik hisobot (test uchun) ──
export const triggerWeeklyReport = functions
    .region('us-central1')
    .https.onCall(async (_data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        try {
            await generateWeeklyAnalytics(uid);
            return { success: true, weekId: new Date().toISOString().slice(0, 10) };
        } catch (e) { fail(e, 'TriggerWeeklyReport'); }
    });

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: STREAK TIZIMI — 2-QISM (CLOUD FUNCTIONS)
// Streak logikasi: har o'tkazilgan kun → streak - 2 (minimum 0)
// Misol: 7 streak, 1 kun o'tkazdi → 7-2=5
//        7 streak, 2 kun o'tkazdi → 7-4=3
//        3 streak, 1 kun o'tkazdi → 3-2=1
// ═══════════════════════════════════════════════════════════════

// ── Yordamchi: FCM token orqali bildirishnoma yuborish ──────────────────
// channelId ixtiyoriy — ko'rsatilmasa 'streak_channel' ishlatiladi
async function sendFcmToUser(
    db: FirebaseFirestore.Firestore,
    uid: string,
    notification: { title: string; body: string },
    notificationDoc: {
        type: string;
        title: string;
        body: string;
    },
    channelId = 'streak_channel'
): Promise<void> {
    try {
        const userSnap = await db.collection('users').doc(uid).get();
        const fcmToken = userSnap.data()?.fcmToken as string | undefined;

        if (fcmToken) {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: notification.title,
                    body: notification.body,
                },
                data: { type: notificationDoc.type },
                android: {
                    priority: 'high',
                    notification: { channelId },
                },
                apns: {
                    payload: { aps: { badge: 1, sound: 'default' } },
                },
            });
        }

        await db.collection('notifications').add({
            userId: uid,
            type: notificationDoc.type,
            title: notificationDoc.title,
            body: notificationDoc.body,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (e) {
        console.error(`⚠️ FCM xatosi (uid=${uid}):`, e);
    }
}

// ── Funksiya 1: Streak ogohlantirish (har kuni 19:00 Toshkent) ──────────
// Streak >= 3 bo'lgan va bugun hali faol bo'lmagan foydalanuvchilarga yuboriladi.
export const sendStreakReminders = functions
    .region('us-central1')
    .pubsub.schedule('0 19 * * *')
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const todayTimestamp = admin.firestore.Timestamp.fromDate(todayStart);

        const snap = await db.collection('progress')
            .where('currentStreak', '>=', 3)
            .get();

        if (snap.empty) {
            console.log('Streak >= 3 foydalanuvchi yo\'q');
            return;
        }

        let sentCount = 0;

        for (const doc of snap.docs) {
            const uid = doc.id;
            const data = doc.data();
            const currentStreak: number = data.currentStreak ?? 0;
            const lastActiveRaw = data.lastActiveDate;

            if (lastActiveRaw instanceof admin.firestore.Timestamp) {
                const lastDate = lastActiveRaw.toDate();
                const lastDay = new Date(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate());
                if (lastDay.getTime() >= todayTimestamp.toDate().getTime()) {
                    continue;
                }
            }

            await sendFcmToUser(
                db,
                uid,
                {
                    title: '🔥 Streakni yo\'qotma!',
                    body: `${currentStreak} kunlik streaking xavf ostida! Bugun bir mashq qilsang yetarli.`,
                },
                {
                    type: 'streak',
                    title: '🔥 Streakni yo\'qotma!',
                    body: `${currentStreak} kunlik streaking xavf ostida! Bugun bir mashq qilsang yetarli.`,
                }
            );
            sentCount++;
        }

        console.log(`✅ Streak ogohlantirishlari: ${sentCount} ta foydalanuvchiga yuborildi`);
    });

// ── Funksiya 2: Streak kamaytirish (har kuni 23:50 Toshkent) ────────────
// ✅ TO'G'RI LOGIKA: har o'tkazilgan kun uchun streak - 2 (minimum 0)
// Misol: 7 streak, 1 kun o'tkazdi → 7-2=5
//        7 streak, 2 kun o'tkazdi → 7-4=3
export const checkStreaks = functions
    .region('us-central1')
    .pubsub.schedule('50 23 * * *')
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();
        const todayMs = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
        const msInDay = 24 * 60 * 60 * 1000;

        const snap = await db.collection('progress')
            .where('currentStreak', '>', 0)
            .get();

        if (snap.empty) {
            console.log('Aktiv streak yo\'q');
            return;
        }

        let batch = db.batch();
        let batchCount = 0;
        let updatedCount = 0;

        for (const doc of snap.docs) {
            const data = doc.data();
            const lastActiveRaw = data.lastActiveDate;
            const currentStreakVal: number = data.currentStreak ?? 0;

            // lastActiveDate yo'q — to'liq reset
            if (!lastActiveRaw || !(lastActiveRaw instanceof admin.firestore.Timestamp)) {
                batch.update(doc.ref, { currentStreak: 0 });
                batchCount++; updatedCount++;
                if (batchCount >= 499) { await batch.commit(); batch = db.batch(); batchCount = 0; }
                continue;
            }

            const lastDate = lastActiveRaw.toDate();
            const lastDayMs = new Date(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate()).getTime();
            const daysMissed = Math.round((todayMs - lastDayMs) / msInDay);

            // Bugun kirgan — hech narsa qilma
            if (daysMissed <= 0) continue;

            // Har o'tkazilgan kun 2 streak kuyadi, minimum 0
            // Misol: 7 streak, 1 kun → 7-2=5 | 7 streak, 2 kun → 7-4=3
            const penalty = daysMissed * 2;
            const newStreakVal = Math.max(0, currentStreakVal - penalty);
            batch.update(doc.ref, { currentStreak: newStreakVal });
            batchCount++; updatedCount++;

            if (batchCount >= 499) { await batch.commit(); batch = db.batch(); batchCount = 0; }
        }

        if (batchCount > 0) await batch.commit();
        console.log(`✅ Streak yangilandi: ${updatedCount} ta foydalanuvchi`);
    });

// ── Funksiya 3: Streak milestone mukofotlari ─────────────────────────────
// progress/{uid} yangilanganda avtomatik ishga tushadi.
// currentStreak 7, 30, 100 ga yetganda bir martalik mukofot beradi.
// Mukofot qayta berilmasligini alreadyRewarded_7/30/100 flag'lari ta'minlaydi.
export const giveStreakReward = functions
    .region('us-central1')
    .firestore.document('progress/{uid}')
    .onUpdate(async (change, context) => {
        const uid = context.params.uid as string;
        const before = change.before.data();
        const after = change.after.data();

        const streakBefore: number = before?.currentStreak ?? 0;
        const streakAfter: number = after?.currentStreak ?? 0;

        // Streak oshmagansa — hech narsa qilmaydi (reset bo'lsa ham chiqamiz)
        if (streakAfter <= streakBefore) return;

        const db = admin.firestore();
        const progressRef = change.after.ref;
        const userRef = db.collection('users').doc(uid);

        // ── 7 kunlik mukofot: 'weekly_champion' badge ──────────────────
        if (streakAfter >= 7 && !after.alreadyRewarded_7) {
            try {
                await progressRef.update({ alreadyRewarded_7: true });
                await userRef.update({
                    badges: admin.firestore.FieldValue.arrayUnion('weekly_champion'),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await sendFcmToUser(
                    db,
                    uid,
                    {
                        title: '🏆 7 kunlik streak!',
                        body: 'Ajoyib! "Weekly Champion" badge qo\'lga kiritdingiz! Davom eting!',
                    },
                    {
                        type: 'achievement',
                        title: '🏆 7 kunlik streak!',
                        body: 'Ajoyib! "Weekly Champion" badge qo\'lga kiritdingiz! Davom eting!',
                    }
                );
                console.log(`✅ 7-kun mukofot: ${uid} → weekly_champion badge`);
            } catch (e) {
                console.error(`⚠️ 7-kun mukofot xatosi (${uid}):`, e);
            }
        }

        // ── 30 kunlik mukofot: 3 kun bepul premium ─────────────────────
        if (streakAfter >= 30 && !after.alreadyRewarded_30) {
            try {
                await progressRef.update({ alreadyRewarded_30: true });

                const userSnap = await userRef.get();
                const userData = userSnap.data() ?? {};
                const existingExpiry = (userData.premiumExpiresAt as admin.firestore.Timestamp | undefined)?.toDate();
                const baseDate = existingExpiry && existingExpiry > new Date() ? existingExpiry : new Date();
                const newExpiry = new Date(baseDate);
                newExpiry.setDate(newExpiry.getDate() + 3);

                await userRef.update({
                    isPremium: true,
                    premiumExpiresAt: admin.firestore.Timestamp.fromDate(newExpiry),
                    premiumSource: 'streak_reward',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                await sendFcmToUser(
                    db,
                    uid,
                    {
                        title: '🎉 30 kunlik streak!',
                        body: '3 kun bepul premium qo\'lga kiritdingiz! Barcha imkoniyatlar ochiq.',
                    },
                    {
                        type: 'premium_activated',
                        title: '🎉 30 kunlik streak!',
                        body: '3 kun bepul premium qo\'lga kiritdingiz! Barcha imkoniyatlar ochiq.',
                    }
                );
                console.log(`✅ 30-kun mukofot: ${uid} → 3 kun premium`);
            } catch (e) {
                console.error(`⚠️ 30-kun mukofot xatosi (${uid}):`, e);
            }
        }

        // ── 100 kunlik mukofot: 'sozana_legend' badge ──────────────────
        if (streakAfter >= 100 && !after.alreadyRewarded_100) {
            try {
                await progressRef.update({ alreadyRewarded_100: true });
                await userRef.update({
                    badges: admin.firestore.FieldValue.arrayUnion('sozana_legend'),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await sendFcmToUser(
                    db,
                    uid,
                    {
                        title: '👑 100 kunlik streak — LEGENDA!',
                        body: 'Siz So\'zona legendasiga aylandingiz! "Sozana Legend" badge sizniki!',
                    },
                    {
                        type: 'achievement',
                        title: '👑 100 kunlik streak — LEGENDA!',
                        body: 'Siz So\'zona legendasiga aylandingiz! "Sozana Legend" badge sizniki!',
                    }
                );
                console.log(`✅ 100-kun mukofot: ${uid} → sozana_legend badge`);
            } catch (e) {
                console.error(`⚠️ 100-kun mukofot xatosi (${uid}):`, e);
            }
        }
    });
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: STREAK ORALIQ MILESTONE NOTIFICATIONLAR
// giveStreakReward da 7/30/100 bor — bu yerda 3/5/14/21 qo'shiladi
// progress/{uid} onUpdate — streakAfter oraliq milestonelarga yetganda
// ═══════════════════════════════════════════════════════════════

// Milestone konfiguratsiyasi
const STREAK_MILESTONES: Array<{
    streak: number;
    flag: string;
    title: string;
    body: string;
}> = [
        {
            streak: 3,
            flag: 'notified_3',
            title: '🔥 3 kunlik streak!',
            body: 'Zo\'r boshlanish! Davom eting — har kun yangi so\'z siz bilan!',
        },
        {
            streak: 5,
            flag: 'notified_5',
            title: '🌟 5 kunlik streak!',
            body: '5 kun ketma-ket! Siz haqiqiy o\'quvchisiz. Ertaga ham kutamiz!',
        },
        {
            streak: 14,
            flag: 'notified_14',
            title: '💪 2 haftalik streak!',
            body: '14 kun! Endi ingliz tili odat bo\'lib qolmoqda. Zo\'r!',
        },
        {
            streak: 21,
            flag: 'notified_21',
            title: '🏅 21 kunlik streak — ODAT!',
            body: 'Psixologlar aytadi: 21 kun — bu yangi odatning boshlanishi. Siz muvaffaq bo\'ldingiz!',
        },
    ];

export const notifyStreakMilestone = functions
    .region('us-central1')
    .firestore.document('progress/{uid}')
    .onUpdate(async (change, context) => {
        const uid = context.params.uid as string;
        const before = change.before.data();
        const after = change.after.data();

        const streakBefore: number = before?.currentStreak ?? 0;
        const streakAfter: number = after?.currentStreak ?? 0;

        // Streak oshmagan — hech narsa qilma
        if (streakAfter <= streakBefore) return;

        const db = admin.firestore();
        const progressRef = change.after.ref;

        for (const milestone of STREAK_MILESTONES) {
            // Milestone ga yetdi VA hali bildirilmagan
            if (streakAfter >= milestone.streak && !after[milestone.flag]) {
                try {
                    await progressRef.update({ [milestone.flag]: true });
                    await sendFcmToUser(
                        db,
                        uid,
                        { title: milestone.title, body: milestone.body },
                        {
                            type: 'streak_milestone',
                            title: milestone.title,
                            body: milestone.body,
                        }
                    );
                    console.log(`✅ Streak milestone ${milestone.streak}: ${uid}`);
                } catch (e) {
                    console.error(`⚠️ Streak milestone ${milestone.streak} xatosi (${uid}):`, e);
                }
            }
        }
    });

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: LEADERBOARD CLOUD FUNCTIONS
// notifyLeaderboardChange — top 3 kirsa / o'tib ketilsa FCM
// resetLeaderboard        — har oyning 1-sida reset + g'olib saqlash
// ═══════════════════════════════════════════════════════════════

// Spam oldini olish: bir foydalanuvchiga kuniga max 2 leaderboard notification
async function canSendLeaderboardNotif(db: FirebaseFirestore.Firestore, uid: string): Promise<boolean> {
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
    const ref = db.collection('leaderboard_notif_log').doc(`${uid}_${todayStr}`);
    const snap = await ref.get();
    const count: number = snap.exists ? (snap.data()?.count ?? 0) : 0;
    if (count >= 2) return false;
    await ref.set({ count: count + 1, uid, date: todayStr }, { merge: true });
    return true;
}

export const notifyLeaderboardChange = functions
    .region('us-central1')
    .firestore.document('users/{uid}')
    .onUpdate(async (change, context) => {
        const uid = context.params.uid as string;
        const before = change.before.data();
        const after = change.after.data();

        const countBefore: number = before?.referralValidCount ?? 0;
        const countAfter: number = after?.referralValidCount ?? 0;

        // Count o'zgarmagan — chiqamiz
        if (countAfter === countBefore) return;

        const db = admin.firestore();

        // Joriy leaderboard ni olish (top 50)
        const snap = await db.collection('users')
            .orderBy('referralValidCount', 'desc')
            .limit(50)
            .get();

        const entries = snap.docs.map((doc, i) => ({
            uid: doc.id,
            rank: i + 1,
            count: doc.data().referralValidCount ?? 0,
        }));

        const myEntry = entries.find(e => e.uid === uid);
        if (!myEntry) return;

        const myRank = myEntry.rank;

        // ── Foydalanuvchi top 3 ga kirgan ──
        if (myRank <= 3 && countAfter > countBefore) {
            const canSend = await canSendLeaderboardNotif(db, uid);
            if (canSend) {
                const prize = myRank === 1 ? 'IELTS' : myRank === 2 ? '6 oy premium' : '3 oy premium';
                await sendFcmToUser(
                    db,
                    uid,
                    {
                        title: `🏆 Tabrik! Siz ${myRank}-o'rindasiz!`,
                        body: `${myRank}-o'rin → ${prize}! Yetakchilikni saqlab qol!`,
                    },
                    {
                        type: 'leaderboard_top3',
                        title: `🏆 Tabrik! Siz ${myRank}-o'rindasiz!`,
                        body: `${myRank}-o'rin → ${prize}!`,
                    }
                );
            }
        }

        // ── Kimdir joriy foydalanuvchini o'tib ketgan ──
        // O'tib ketgan foydalanuvchini topish
        if (countAfter < countBefore) return; // Bu yerda count kamaygan emas

        // Bizni bir qator yuqoridagini tekshirish
        if (myRank > 1) {
            const above = entries.find(e => e.rank === myRank - 1);
            if (above && above.uid !== uid) {
                // Biz yuqoridagini yangi o'tib ketdikmi?
                if (countAfter > above.count) {
                    // Bu holat entries yangilangan bo'lsa bo'lishi mumkin emas
                    // Ammo kimdir bizni o'tib ketgan holatni quyida tekshiramiz
                }
            }
        }

        // Bizdan past turganlardan bizni o'tib ketgan bor?
        // Bu holat: boshqa user count yangilanganda ULAR trigger bo'ladi
        // Shuning uchun: agar boshqa user bizdan ko'p bo'lib qolsa,
        // biz "o'tib ketildi" deb notification olamiz
        // Bu logika: agar joriy trigger'dagi user (uid) bizdan yuqori bo'lsa va biz uning pastida bo'lsak
        // Bu yerda uid o'zgardi → boshqa userlar uchun tekshirish
        const updatedUserEntry = entries.find(e => e.uid === uid);
        if (!updatedUserEntry) return;

        // O'tib ketilgan foydalanuvchilarni topish:
        // trigger bo'lgan user (uid) kiming ustiga chiqdi?
        for (const entry of entries) {
            if (entry.uid === uid) continue;
            if (entry.rank > updatedUserEntry.rank && entry.count < countAfter) {
                // entry.uid o'tib ketildi
                const canSend = await canSendLeaderboardNotif(db, entry.uid);
                if (canSend) {
                    const userData = snap.docs.find(d => d.id === uid)?.data();
                    const name = userData?.displayName ?? 'Kimdir';
                    await sendFcmToUser(
                        db,
                        entry.uid,
                        {
                            title: '⚡ O\'rning o\'zgardi!',
                            body: `${name} seni ${entry.rank}-o\'rinda o\'tib ketdi! Kurashni davom ettir!`,
                        },
                        {
                            type: 'leaderboard_overtaken',
                            title: '⚡ O\'rning o\'zgardi!',
                            body: `${name} seni o\'tib ketdi!`,
                        }
                    );
                }
                break; // Faqat bitta "o'tib ketilgan" notif
            }
        }
    });

export const resetLeaderboard = functions
    .region('us-central1')
    .pubsub.schedule('0 0 1 * *') // Har oyning 1-sanasida 00:00
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();
        const yearMonth = `${now.getFullYear()}_${String(now.getMonth() + 1).padStart(2, '0')}`;

        // ── 1. O'tgan oyning g'olibini topish ──
        const snap = await db.collection('users')
            .orderBy('referralValidCount', 'desc')
            .limit(1)
            .get();

        if (!snap.empty) {
            const winner = snap.docs[0];
            const winnerData = winner.data();
            const winnerUid = winner.id;
            const winnerCount: number = winnerData.referralValidCount ?? 0;

            if (winnerCount > 0) {
                // G'olibni winners collection ga saqlash
                await db.collection('winners').doc(yearMonth).set({
                    uid: winnerUid,
                    displayName: winnerData.displayName ?? 'Noma\'lum',
                    referralValidCount: winnerCount,
                    prize: 'ielts',
                    wonAt: admin.firestore.FieldValue.serverTimestamp(),
                    yearMonth,
                });

                // G'olibga bildirishnoma
                const prevMonth = now.getMonth() === 0 ? 12 : now.getMonth();
                const monthNames: Record<number, string> = {
                    1: 'Yanvar', 2: 'Fevral', 3: 'Mart', 4: 'Aprel',
                    5: 'May', 6: 'Iyun', 7: 'Iyul', 8: 'Avgust',
                    9: 'Sentabr', 10: 'Oktabr', 11: 'Noyabr', 12: 'Dekabr',
                };
                const monthName = monthNames[prevMonth] ?? 'o\'tgan oy';

                await sendFcmToUser(
                    db,
                    winnerUid,
                    {
                        title: '🎉 Siz g\'oldib bo\'ldingiz!',
                        body: `${monthName} oyida ${winnerCount} taklif bilan 1-o\'rin! IELTS to\'lovi haqida siz bilan bog\'lanamiz.`,
                    },
                    {
                        type: 'leaderboard_winner',
                        title: '🎉 Siz g\'oldib bo\'ldingiz!',
                        body: `${monthName} oyida 1-o\'rin! IELTS to\'lovi haqida siz bilan bog\'lanamiz.`,
                    }
                );
                console.log(`✅ G'olib saqlandi: ${winnerUid}, oy: ${yearMonth}`);
            }
        }

        // ── 2. Barcha foydalanuvchilar referralValidCount = 0 reset ──
        const allUsers = await db.collection('users')
            .where('referralValidCount', '>', 0)
            .get();

        if (!allUsers.empty) {
            let batch = db.batch();
            let batchCount = 0;

            for (const doc of allUsers.docs) {
                batch.update(doc.ref, { referralValidCount: 0 });
                batchCount++;
                if (batchCount >= 499) {
                    await batch.commit();
                    batch = db.batch();
                    batchCount = 0;
                }
            }
            if (batchCount > 0) await batch.commit();
            console.log(`✅ Leaderboard reset: ${allUsers.size} ta foydalanuvchi`);
        }

        // ── 3. notif_log ni tozalash (eski yozuvlar) ──
        const logSnap = await db.collection('leaderboard_notif_log').limit(500).get();
        if (!logSnap.empty) {
            const delBatch = db.batch();
            logSnap.docs.forEach(d => delBatch.delete(d.ref));
            await delBatch.commit();
        }

        console.log(`✅ Leaderboard oylik reset tugadi: ${yearMonth}`);
    });

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: REFERRAL TIZIMI
// generateReferralCode   — SZ-XXXX-XXXX unikal kod yaratish
// getReferralStats       — kod, usedCount, pendingCount, rewardedCount
// redeemReferralCode     — kodni qo'llash (mukofot YO'Q — 7 kun kutiladi)
// processReferralRewards — har kuni 02:00: 7 kun faol do'stlarga 3 kun premium
// ═══════════════════════════════════════════════════════════════
export {
    generateReferralCode,
    getReferralStats,
    redeemReferralCode,
    processReferralRewards,
} from './referral';

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: OVOZLI YORDAMCHI — GPT CHAT
// Flutter voice_assistant_service.dart shu endpointni chaqiradi
// Javobi: { reply: string }
// ═══════════════════════════════════════════════════════════════

export const voiceChat = functions
    .region('us-central1')
    .runWith({ timeoutSeconds: 60, memory: '512MB' as const, secrets: ['OPENAI_KEY'], minInstances: 1 })
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);

        // Premium tekshiruvi
        const userSnap = await admin.firestore().collection('users').doc(uid).get();
        const userData = userSnap.data() ?? {};
        const isPremium = (userData.isPremium as boolean) ?? false;
        const premiumExpiresAt = userData.premiumExpiresAt as admin.firestore.Timestamp | undefined;
        const hasActivePremium = isPremium && (!premiumExpiresAt || premiumExpiresAt.toMillis() > Date.now());

        if (!hasActivePremium) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Bu funksiya faqat premium foydalanuvchilar uchun.'
            );
        }

        // Rate limit
        await checkRateLimit(uid);

        const messages = (data.messages as Array<{ role: string; content: string }>) ?? [];
        const userName = (data.userName as string) ?? "Do'stim";
        const weatherCtx = (data.weatherCtx as string | undefined);

        if (!messages.length) {
            throw new functions.https.HttpsError('invalid-argument', "Xabarlar bo'sh");
        }

        // ✅ Natijalar so'ralganda — parallel yuklanadi (kechikish yo'q)
        const lastUserMsg = messages[messages.length - 1]?.content?.toLowerCase() ?? '';
        const wantsStats = lastUserMsg.includes('natija') ||
            lastUserMsg.includes('ko\'rsatkich') ||
            lastUserMsg.includes('statistika') ||
            lastUserMsg.includes('yaxshimi') ||
            lastUserMsg.includes('darajam') ||
            lastUserMsg.includes('murabbiy') ||
            lastUserMsg.includes('progress');

        // Parallel: stats yuklanishi GPT so'rovini blokllamaydi
        const statsCtx = wantsStats
            ? await getVoiceCoachSummary(uid, userName).catch(() => '')
            : '';

        const systemPrompt = `Sen So'zona — o'zbek tilidagi ovozli AI yordamchi va ingliz hamda nemis tili o'qituvchisi.

Foydalanuvchi ismi: ${userName}${weatherCtx ? '\n' + weatherCtx : ''}${statsCtx ? '\n\nO\'QUVCHI STATISTIKASI:\n' + statsCtx : ''}

QANDAY GAPIRISH KERAK:
- Insonday, issiq, muloyim gapir — robot kabi rasmiy so'zlar ishlatma.
- O'zbekona iboralar: "voy", "qoyil-da", "ha bilasizmi", "shunday bo'lar-da", "xo'p".
- Ingliz yoki nemis so'zi so'ralsa — so'zni va talaffuzini ham ayt.
- Natijalar so'ralganda — statistikadagi raqamlarni aniq ayt.
- Kulgili narsa aytilsa — kulimsirab javob ber.
- Xato qilsa — muloyim to'g'irla.

QILMASLIK:
- Inglizcha yozma — faqat o'zbekcha.
- Emoji, belgi (#, *, →) yozma.
- Ro'yxat yozma — gaplar ketma-ket bo'lsin.
- 3 jumladan ko'p yozma.
- "Men sun'iy intellektman" dema — sen So'zona.`;

        try {
            const completion = await openai.chat.completions.create({
                model: 'gpt-4o-mini',
                max_tokens: 220,
                temperature: 0.88,
                messages: [
                    { role: 'system', content: systemPrompt },
                    ...messages.map(m => ({
                        role: m.role as 'user' | 'assistant',
                        content: m.content,
                    })),
                ],
            });

            const reply = (completion.choices[0]?.message?.content ?? '').trim()
                .replace(/[#*→•\[\](){}]/g, '')
                .replace(/\d+\.\s/g, '')
                .replace(/\s{2,}/g, ' ')
                .trim();

            return { reply: reply || "Kechirasiz, qayta so'rang." };
        } catch (e) {
            console.error('voiceChat error:', e);
            throw new functions.https.HttpsError('internal', 'AI javob bera olmadi');
        }
    });