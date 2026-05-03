// functions/src/ai/ai_router.ts
// SO'ZONA — AI Router
// ✅ Gemini: barcha funksiyalar (tekin + premium)
// ✅ OpenAI (gpt-4o-mini): faqat premium AI murabbiy mashq yaratish uchun
// ✅ FIX: model nomi GEMINI_MODEL_NAME konstanta orqali — gemini_client.ts bilan mos

import { geminiComplete, GEMINI_MODEL_NAME } from './gemini_client';
import type { GeminiResult } from './gemini_client';
import { openAiComplete } from './openai_client';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

interface AiRouterRequest {
    prompt: string;
    systemPrompt?: string;
    maxTokens?: number;
    temperature?: number;
    schema?: unknown;
}

interface AiRouterResponse {
    text: string;
    content: string;
    model: string;
}

interface AIRequest {
    messages: Array<{ role: string; content: string }>;
    model?: string;
    temperature?: number;
    maxTokens?: number;
}

interface AIResponse {
    content: string;
    model: string;
    usage?: {
        promptTokens: number;
        completionTokens: number;
        totalTokens: number;
    };
}

// ═══════════════════════════════════════════════════════════════
// aiRouter — Gemini (barcha umumiy funksiyalar)
// ═══════════════════════════════════════════════════════════════

export async function aiRouter(request: AiRouterRequest): Promise<AiRouterResponse> {
    console.log('🤖 Gemini ishga tushmoqda (aiRouter)...');
    const result: GeminiResult = await geminiComplete(
        request.prompt,
        request.systemPrompt,
        request.maxTokens ?? 4096,
    );
    return { text: result.text, content: result.text, model: GEMINI_MODEL_NAME };
}

// ═══════════════════════════════════════════════════════════════
// openAiRouter — OpenAI GPT-4o-mini (faqat premium murabbiy uchun)
// ═══════════════════════════════════════════════════════════════

export async function openAiRouter(request: AiRouterRequest): Promise<AiRouterResponse> {
    console.log('🧠 OpenAI GPT-4o-mini ishga tushmoqda (premium)...');
    const text = await openAiComplete(
        request.prompt,
        request.systemPrompt,
        true, // JSON mode
    );
    return { text, content: text, model: 'gpt-4o-mini' };
}

// ═══════════════════════════════════════════════════════════════
// callAI — messages-based (Gemini)
// ═══════════════════════════════════════════════════════════════

export async function callAI(request: AIRequest): Promise<AIResponse> {
    // ✅ FIX: Barcha conversation history ni birlashtirish
    // Avval: faqat oxirgi xabar → Gemini kontextni bilmasdi
    // Yangi: system + barcha messages bitta prompt sifatida
    const systemMessage = request.messages.find(m => m.role === 'system');
    const conversationMessages = request.messages.filter(m => m.role !== 'system');

    // Conversation history ni bitta matnga birlashtirish
    const conversationText = conversationMessages
        .map(m => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.content}`)
        .join('\n\n');

    console.log('🤖 Gemini ishga tushmoqda (callAI)...');
    // ✅ FIX: result obyektidan haqiqiy tokenlarni olamiz
    const result: GeminiResult = await geminiComplete(
        conversationText,
        systemMessage?.content,
    );
    return {
        content: result.text,
        model: GEMINI_MODEL_NAME,
        usage: {
            promptTokens: result.promptTokens,
            completionTokens: result.completionTokens,
            totalTokens: result.promptTokens + result.completionTokens,
        },
    };
}

// ═══════════════════════════════════════════════════════════════
// callAIWithRetry — retry logic bilan (Gemini)
// ═══════════════════════════════════════════════════════════════

export async function callAIWithRetry(
    request: AIRequest,
    maxRetries = 2
): Promise<AIResponse> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return await callAI(request);
        } catch (error: unknown) {
            lastError = error instanceof Error ? error : new Error(String(error));
            if (attempt < maxRetries) {
                const delay = Math.pow(2, attempt) * 1000;
                console.log(`⏳ Retry ${attempt + 1} — ${delay}ms kutilmoqda...`);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }

    throw lastError ?? new Error('Barcha urinishlar muvaffaqiyatsiz');
}