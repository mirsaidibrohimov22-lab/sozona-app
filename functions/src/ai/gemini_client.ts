// functions/src/ai/gemini_client.ts
// ✅ FIX 1: maxOutputTokens 2048 → 16000 (thinking tokenlar uchun)
// ✅ FIX 2: Haqiqiy model nomi 'gemini-2.5-flash' — ai_router.ts bilan mos
// ✅ FIX 3: Token usage qaytariladi — cost_monitor to'g'ri hisoblaydi

import { GoogleGenerativeAI } from '@google/generative-ai';

export const GEMINI_MODEL_NAME = 'gemini-2.5-flash';

export function cleanJsonResponse(text: string): string {
    let s = text.trim();
    if (s.startsWith('```json')) s = s.slice(7);
    else if (s.startsWith('```')) s = s.slice(3);
    if (s.endsWith('```')) s = s.slice(0, -3);
    return s.trim();
}

export function safeParseJson(text: string): Record<string, unknown> {
    try {
        return JSON.parse(cleanJsonResponse(text)) as Record<string, unknown>;
    } catch {
        const match = text.match(/\{[\s\S]*\}/);
        if (match) {
            try { return JSON.parse(match[0]) as Record<string, unknown>; }
            catch { /* davom etadi */ }
        }
        throw new Error(
            `AI javobidan JSON ajratib olish imkonsiz. Raw: ${text.slice(0, 300)}`
        );
    }
}

// ✅ FIX: geminiComplete endi { text, promptTokens, completionTokens } qaytaradi
// Avval: faqat text → callAI da usage=0. Yangi: tokenlar ham qaytariladi
export interface GeminiResult {
    text: string;
    promptTokens: number;
    completionTokens: number;
}

export async function geminiComplete(
    prompt: string,
    systemPrompt?: string,
    maxTokens: number = 16000,
): Promise<GeminiResult> {
    const key = process.env.GEMINI_KEY ?? '';
    if (!key) throw new Error('GEMINI_KEY sozlanmagan.');

    const fullPrompt = systemPrompt
        ? `${systemPrompt}\n\n${prompt}`
        : prompt;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL_NAME}:generateContent?key=${key}`;

    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            contents: [{ parts: [{ text: fullPrompt }] }],
            generationConfig: {
                temperature: 0.7,
                topP: 0.9,
                // ✅ FIX: 16000 — thinking tokenlar + javob uchun yetarli joy
                maxOutputTokens: maxTokens,
                thinkingConfig: {
                    thinkingBudget: 0,
                },
            },
        }),
    });

    if (!response.ok) {
        const errText = await response.text();
        throw new Error(
            `Gemini API xatosi (${response.status}): ${errText.slice(0, 200)}`
        );
    }

    const data = await response.json() as {
        candidates?: Array<{
            content?: { parts?: Array<{ text?: string }> };
        }>;
        usageMetadata?: {
            promptTokenCount?: number;
            candidatesTokenCount?: number;
            totalTokenCount?: number;
        };
        error?: { message?: string };
    };

    if (data.error) throw new Error(`Gemini xatosi: ${data.error.message}`);

    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    if (!rawText) throw new Error("Gemini bo'sh javob qaytardi");

    // ✅ FIX: Haqiqiy token sonlarini olish va qaytarish
    const usage = data.usageMetadata;
    const promptTokens = usage?.promptTokenCount ?? 0;
    const completionTokens = usage?.candidatesTokenCount ?? 0;
    console.log(`🔢 Gemini tokens: prompt=${promptTokens}, output=${completionTokens}, total=${usage?.totalTokenCount ?? 0}`);
    console.log(`🤖 Gemini ${GEMINI_MODEL_NAME} raw:`, rawText.slice(0, 100));

    return { text: rawText, promptTokens, completionTokens };
}

export default new GoogleGenerativeAI(process.env.GEMINI_KEY ?? '');