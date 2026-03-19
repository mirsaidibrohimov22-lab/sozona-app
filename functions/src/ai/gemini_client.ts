// functions/src/ai/gemini_client.ts
// ✅ FIX: maxOutputTokens 2048 → 16000
// SABAB: gemini-2.5-flash da thinking tokenlar ham maxOutputTokens dan
//        hisoblanadi. 2048 kichik bo'lgani uchun thinking tokenlar
//        hamma joyni egallab, javob bo'sh yoki truncated kelardi —
//        Cloud Function DEADLINE_EXCEEDED berardi.

import { GoogleGenerativeAI } from '@google/generative-ai';

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

export async function geminiComplete(
    prompt: string,
    systemPrompt?: string,
    maxTokens: number = 16000,
): Promise<string> {
    const key = process.env.GEMINI_KEY ?? '';
    if (!key) throw new Error('GEMINI_KEY sozlanmagan.');

    const fullPrompt = systemPrompt
        ? `${systemPrompt}\n\n${prompt}`
        : prompt;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${key}`;

    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            contents: [{ parts: [{ text: fullPrompt }] }],
            generationConfig: {
                temperature: 0.7,
                topP: 0.9,
                // ✅ FIX: 16000 — thinking tokenlar + javob uchun yetarli joy
                // Avval 2048 edi — thinking tokenlar (5000-15000) uni to'ldirardi
                // va haqiqiy javob uchun joy qolmasdi → DEADLINE_EXCEEDED
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
        error?: { message?: string };
    };

    if (data.error) throw new Error(`Gemini xatosi: ${data.error.message}`);

    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    if (!rawText) throw new Error("Gemini bo'sh javob qaytardi");

    console.log('🤖 Gemini 2.5-flash raw:', rawText.slice(0, 100));
    return rawText;
}

export default new GoogleGenerativeAI(process.env.GEMINI_KEY ?? '');