// functions/src/index.ts
// SO'ZONA — Cloud Functions Index
// ✅ FIX: generateQuiz — grammar va userId parametrlari uzatiladi
// ✅ FIX: generateListening — grammar va userId parametrlari uzatiladi
// ✅ FIX: safeParseJson() gemini_client.ts da — barcha JSON parse muammolari hal qilindi
// ✅ YANGI: onMemberJoined, onMemberLeft — memberCount avtomatik yangilanadi

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

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
import { checkRateLimit } from './middleware/rate_limiter';

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

function toLang(v: unknown): Lang { return v === 'de' ? 'de' : 'en'; }
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
// ═══════════════════════════════════════

export const chatWithAI = functions
    .region('us-central1')
    .runWith(aiRunWith)
    .https.onCall(async (data: Record<string, unknown>, ctx: functions.https.CallableContext) => {
        const uid = requireAuth(ctx);
        await checkRateLimit(uid);
        try {
            return await chatWithTeacher({
                userId: uid,
                message: (data.message as string) ?? '',
                language: toLang(data.language),
                conversationHistory: (data.history as Array<{ role: 'user' | 'assistant'; content: string }>) ?? [],
            });
        } catch (e) { normalizeAiError(e, 'AI Chat'); }
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

export const healthCheck = functions.region('us-central1').https
    .onRequest((_req: functions.https.Request, res: functions.Response) => {
        res.json({
            status: 'ok',
            timestamp: new Date().toISOString(),
            version: '3.2.0',
            fixes: ['json_parse_fix', 'grammar_per_level', 'firestore_index', 'member_count_trigger'],
        });
    });