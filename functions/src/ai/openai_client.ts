// functions/src/ai/openai_client.ts
// SO'ZONA — OpenAI Client

import OpenAI from 'openai';

const OPENAI_KEY = process.env.OPENAI_API_KEY ?? '';
const openai = new OpenAI({ apiKey: OPENAI_KEY });

/**
 * OpenAI API orqali matn yaratish
 * @param userPrompt - Foydalanuvchi so'rovi
 * @param systemPrompt - Tizim ko'rsatmasi (ixtiyoriy)
 * @param jsonMode - JSON formatda javob olish
 */
export async function openAiComplete(
    userPrompt: string,
    systemPrompt?: string,
    jsonMode = false
): Promise<string> {
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [];

    if (systemPrompt) {
        messages.push({ role: 'system', content: systemPrompt });
    }
    messages.push({ role: 'user', content: userPrompt });

    const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages,
        temperature: 0.7,
        max_tokens: 2000,
        ...(jsonMode ? { response_format: { type: 'json_object' } } : {}),
    });

    return completion.choices[0]?.message?.content ?? '';
}

export default openai;
