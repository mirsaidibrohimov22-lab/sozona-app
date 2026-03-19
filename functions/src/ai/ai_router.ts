// functions/src/ai/ai_router.ts
// SO'ZONA — AI Router (Gemini-only, OpenAI keyinroq qo'shiladi)
// ✅ PATCH: OpenAI key yo'q — to'g'ridan Gemini ishlatiladi

import { geminiComplete } from './gemini_client';

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
// aiRouter — prompt-based (Gemini)
// ═══════════════════════════════════════════════════════════════

export async function aiRouter(request: AiRouterRequest): Promise<AiRouterResponse> {
    console.log('🤖 Gemini ishga tushmoqda (aiRouter)...');
    // ✅ FIX: maxTokens endi geminiComplete ga uzatiladi (avval yo'qolayotgan edi)
    const text = await geminiComplete(
        request.prompt,
        request.systemPrompt,
        request.maxTokens ?? 4096,
    );
    return { text, content: text, model: 'gemini-1.5-flash' };
}

// ═══════════════════════════════════════════════════════════════
// callAI — messages-based (Gemini)
// ═══════════════════════════════════════════════════════════════

export async function callAI(request: AIRequest): Promise<AIResponse> {
    const lastMessage = request.messages[request.messages.length - 1];
    const systemMessage = request.messages.find(m => m.role === 'system');

    console.log('🤖 Gemini ishga tushmoqda (callAI)...');
    const text = await geminiComplete(
        lastMessage?.content ?? '',
        systemMessage?.content
    );
    return {
        content: text,
        model: 'gemini-1.5-flash',
        usage: { promptTokens: 0, completionTokens: 0, totalTokens: 0 },
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