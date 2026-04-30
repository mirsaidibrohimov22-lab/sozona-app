// functions/src/prompts/ai_chat_conversation.ts
// SO'ZONA — AI Chat O'qituvchi
// ✅ Prompt talabi:
//   - Tushuntirish beradi
//   - Misollar beradi
//   - Grammatikani oddiy qilib tushuntiradi
//   - Foydalanuvchi darajasiga moslashadi

import { aiRouter } from '../ai/ai_router';
import { getUserProfile } from '../trackers/user_activity_tracker';
import * as admin from 'firebase-admin';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

export interface ChatRequest {
    userId: string;
    message: string;
    language: 'en' | 'de';
    conversationHistory?: ChatTurn[];
    isPremium?: boolean;
    statsContext?: string; // ✅ Real statistika (natijalar so'ralganda)
}

export interface ChatTurn {
    role: 'user' | 'assistant';
    content: string;
    timestamp?: string;
}

export interface ChatResponse {
    reply: string;
    suggestions: string[];         // Keyingi savollar uchun tavsiyalar
    detectedTopic?: string;        // Aniqlangan mavzu
    grammarTip?: string;           // Grammatik maslahat
    relatedExercise?: {            // Tegishli mashq tavsiyasi
        type: 'quiz' | 'flashcard' | 'listening' | 'speaking';
        topic: string;
        reason: string;
    };
    metadata: {
        model: string;
        responseTime: number;
    };
}

// ═══════════════════════════════════════════════════════════════
// SYSTEM PROMPT — O'QITUVCHI ROLI
// ═══════════════════════════════════════════════════════════════

function buildSystemPrompt(
    language: string,
    level: string,
    weakTopics: string[],
    strongTopics: string[],
): string {
    const langName = language === 'en' ? 'ingliz' : 'nemis';
    const weakSection = weakTopics.length > 0
        ? `O'quvchining zaif joylari: ${weakTopics.join(', ')}. Shu mavzularga ko'proq e'tibor bering.`
        : '';

    return `Sen So'zona ilovasining AI o'qituvchisisan. O'zbek bolalariga ${langName} tilini o'rgatasan.

SENING VAZIFANG:
1. Grammatikani ODDIY va TUSHUNARLI qilib tushuntir
2. Har doim MISOLLAR bilan ko'rsat
3. Xatolarni YUMSHOQ tuzat — rag'batlantir
4. O'quvchi darajasi: ${level}
${weakSection}

QOIDALAR:
- O'zbek tilida javob ber (talaba bola)
- Misollarda ${langName} va o'zbek tarjimasini bergin
- Agar grammatik savol bo'lsa — jadval yoki qisqa ro'yxat ko'rinishida tushuntir
- Agar so'z so'rasa — talaffuz (IPA), misol gap va sinonimlar bergin
- Javob oxirida 1-2 ta keyingi savol uchun tavsiya bergin
- Qisqa va aniq javob ber, lekin to'liq

JSON formatida javob ber:
{
  "reply": "Asosiy javob matni",
  "suggestions": ["Keyingi savol 1", "Keyingi savol 2"],
  "detectedTopic": "aniqlangan_mavzu",
  "grammarTip": "Qisqa grammatik maslahat (ixtiyoriy)",
  "relatedExercise": {
    "type": "quiz|flashcard|listening|speaking",
    "topic": "mavzu",
    "reason": "Nima uchun bu mashq foydali"
  }
}

Hech qanday markdown, backtick yoki izoh qo'shma. Faqat JSON.`;
}

// ═══════════════════════════════════════════════════════════════
// ASOSIY FUNKSIYA
// ═══════════════════════════════════════════════════════════════

/**
 * AI Chat — o'qituvchi bilan suhbat.
 * 
 * Qo'llanishi:
 * - Grammatik savol so'rash
 * - So'z ma'nosini bilish
 * - Mashq haqida maslahat olish
 * - Xatolarni tushuntirish
 */
export async function chatWithTeacher(request: ChatRequest): Promise<ChatResponse> {
    const startTime = Date.now();
    const { userId, message, language, conversationHistory = [], isPremium = false, statsContext = '' } = request;

    // 1. Foydalanuvchi profilini olish
    const profile = await getUserProfile(userId);
    const level = profile?.overallLevel ?? 'A1';
    const weakTopics = profile?.weakTopics ?? [];
    const strongTopics = profile?.strongTopics ?? [];

    // ✅ FIX: Premium: 1500 token (chuqur javoblar), tekin: 800 token (qisqa javoblar)
    // Avval teskari yozilgan edi: isPremium ? 500 : 1000
    const maxTokens = isPremium ? 1500 : 800;

    // 2. System prompt yaratish
    const systemPrompt = buildSystemPrompt(language, level, weakTopics, strongTopics);

    // u2705 Real statistika (natijalar soraqlganda)
    const statsSection = statsContext
        ? `\n\nO'QUVCHI HAQIQIY STATISTIKASI:\n${statsContext}\n\nBu raqamlarni aniq ayt.`
        : '';

    // 3. Conversation kontekst yaratish
    const contextMessages = conversationHistory
        .slice(-6)  // Oxirgi 6 ta xabar (3 ta juft)
        .map(turn => `${turn.role === 'user' ? 'Talaba' : 'O\'qituvchi'}: ${turn.content}`)
        .join('\n');

    const fullPrompt = contextMessages
        ? `${systemPrompt}${statsSection}\n\nOldingi suhbat:\n${contextMessages}\n\nTalabaning yangi savoli: ${message}`
        : `${systemPrompt}${statsSection}\n\nTalaba: ${message}`;

    try {
        // 4. AI ga so'rov
        const response = await aiRouter({
            prompt: fullPrompt,
            maxTokens: maxTokens,
            temperature: 0.7,
            schema: null,
        });

        // 5. Javobni parse qilish
        const text = (response.text ?? response.content ?? '').replace(/```json|```/g, '').trim();
        let parsed: Record<string, unknown>;

        try {
            parsed = JSON.parse(text);
        } catch {
            // Agar JSON bo'lmasa, oddiy matn sifatida qaytarish
            parsed = {
                reply: text,
                suggestions: [],
            };
        }

        const result: ChatResponse = {
            reply: (parsed.reply as string) ?? text,
            suggestions: (parsed.suggestions as string[]) ?? [],
            detectedTopic: parsed.detectedTopic as string | undefined,
            grammarTip: parsed.grammarTip as string | undefined,
            relatedExercise: parsed.relatedExercise as ChatResponse['relatedExercise'],
            metadata: {
                model: response.model || 'gemini-2.0-flash',
                responseTime: Date.now() - startTime,
            },
        };

        // 6. Suhbatni Firestore ga saqlash
        await saveChatHistory(userId, message, result.reply, language);

        return result;
    } catch (error: unknown) {
        console.error('AI Chat xatosi:', error);

        // Fallback javob
        return {
            reply: language === 'en'
                ? 'Kechirasiz, hozir javob bera olmayapman. Iltimos, qaytadan urinib ko\'ring.'
                : 'Entschuldigung, ich kann gerade nicht antworten. Bitte versuchen Sie es erneut.',
            suggestions: [
                'Grammatika haqida so\'rang',
                'Yangi so\'z o\'rganing',
                'Mashq qiling',
            ],
            metadata: {
                model: 'fallback',
                responseTime: Date.now() - startTime,
            },
        };
    }
}

// ═══════════════════════════════════════════════════════════════
// SUHBAT TARIXINI SAQLASH
// ═══════════════════════════════════════════════════════════════

async function saveChatHistory(
    userId: string,
    userMessage: string,
    aiReply: string,
    language: string,
): Promise<void> {
    const db = admin.firestore();
    const chatRef = db.collection('users').doc(userId).collection('chatHistory');

    const batch = db.batch();

    // Foydalanuvchi xabari
    batch.set(chatRef.doc(), {
        text: userMessage,
        isUser: true,
        language,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // AI javobi
    batch.set(chatRef.doc(), {
        text: aiReply,
        isUser: false,
        language,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
}

// ═══════════════════════════════════════════════════════════════
// TEZKOR SAVOLLAR (Quick Actions)
// ═══════════════════════════════════════════════════════════════

/** Tezkor grammatik tushuntirish (bir savol — bir javob) */
export async function quickGrammarExplain(params: {
    topic: string;
    language: 'en' | 'de';
    level: string;
}): Promise<{ explanation: string; examples: string[] }> {
    const { topic, language, level } = params;
    const langName = language === 'en' ? 'ingliz' : 'nemis';

    const prompt = `${level} darajali o'quvchi uchun "${topic}" mavzusini ${langName} tilida qisqa tushuntir.

Faqat JSON:
{
  "explanation": "1-2 paragraf tushuntirish (o'zbek tilida)",
  "examples": ["Misol 1 (${langName}) — Tarjima", "Misol 2 — Tarjima", "Misol 3 — Tarjima"]
}`;

    const response = await aiRouter({ prompt, maxTokens: 500, temperature: 0.6, schema: null });
    const text = (response.text ?? '').replace(/```json|```/g, '').trim();

    try {
        return JSON.parse(text) as { explanation: string; examples: string[] };
    } catch {
        return {
            explanation: text,
            examples: [],
        };
    }
}