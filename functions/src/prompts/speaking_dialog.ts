// functions/src/prompts/speaking_dialog.ts
// ✅ v3.0: CEFR validatsiya + avtomatik retry qo'shildi
// ✅ level endi CEFR (A1-C1) formatida

import { callAIWithRetry } from '../ai/ai_router';
import { parseAndValidate } from '../schemas/schema_validator';
import { checkRateLimit } from '../middleware/rate_limiter';
import { calculateCost, logCost } from '../middleware/cost_monitor';
import speakingSchema from '../schemas/speaking_schema.json';
import { buildLevelBlock, type CEFRLevel } from './cefr_level_guide';
import { FORBIDDEN_WORDS_BY_LEVEL } from './cefr_validator';

interface SpeakingDialogRequest {
    topic: string;
    level: CEFRLevel;
    language: 'en' | 'de';
    turns?: number;
}

const TURN_LENGTH_GUIDE: Record<CEFRLevel, string> = {
    A1: 'Each turn: MAX 4 words. Greetings, yes/no, single nouns only.',
    A2: 'Each turn: MAX 8 words. Simple sentences.',
    B1: '1-2 natural sentences, up to 20 words.',
    B2: '2-3 sentences with varied structures.',
    C1: 'Natural length, sophisticated language.',
};

const SUGGESTION_GUIDE: Record<CEFRLevel, string> = {
    A1: 'Student suggestions: single words or 2-3 word phrases. E.g: "Yes." or "I like it."',
    A2: 'Student suggestions: short simple sentences. E.g: "I go by bus."',
    B1: 'Complete sentences with basic connectors.',
    B2: 'Fluent sentences with some complexity.',
    C1: 'Sophisticated, natural responses.',
};

function buildPrompt(data: SpeakingDialogRequest, retryNote?: string): string {
    const turns = data.turns ?? 6;
    const languageName = data.language === 'en' ? 'English' : 'German';
    const levelBlock = buildLevelBlock(data.level, data.language);
    const retryBlock = retryNote ? `\n\n${retryNote}` : '';

    return `Create a ${languageName} speaking practice dialogue for ${data.level} level about: "${data.topic}"

${levelBlock}

Dialogue rules:
- ${turns} turns total
- ${TURN_LENGTH_GUIDE[data.level]}
- ${SUGGESTION_GUIDE[data.level]}
- AI partner speaks first
- EVERY word must be within ${data.level} vocabulary${retryBlock}

Return ONLY valid JSON:
{
  "topic": "${data.topic}",
  "level": "${data.level}",
  "language": "${data.language}",
  "turns": [
    {"speaker":"partner","text":"...","translation":"O'zbekcha","tips":"..."},
    {"speaker":"student","suggestion":"...","translation":"O'zbekcha","alternatives":["...","..."]}
  ],
  "vocabulary": [{"word":"...","translation":"...","example":"..."}],
  "culturalNotes": "..."
}`;
}

/** Speaking dialog uchun oddiy CEFR tekshiruvi */
function validateSpeakingLevel(dialogData: unknown, level: CEFRLevel): { score: number; issues: string[] } {
    const issues: string[] = [];
    const forbidden = FORBIDDEN_WORDS_BY_LEVEL[level] ?? [];
    const d = dialogData as Record<string, unknown>;
    const turns = Array.isArray(d?.['turns']) ? d['turns'] as Record<string, unknown>[] : [];

    for (const turn of turns) {
        const text = String(turn['text'] || turn['suggestion'] || '').toLowerCase();
        for (const word of forbidden) {
            if (text.includes(word.toLowerCase())) {
                issues.push(`"${word}" so'zi ${level} uchun murakkab`);
            }
        }
    }

    const score = Math.max(0, 100 - issues.length * 15);
    return { score, issues };
}

export async function generateSpeakingDialog(data: SpeakingDialogRequest, uid: string): Promise<unknown> {
    await checkRateLimit(uid);

    const MAX_RETRIES = 2;
    let dialogData: unknown = null;
    let lastValidation: { score: number; issues: string[] } | null = null;
    let aiResponse: Awaited<ReturnType<typeof callAIWithRetry>> | null = null;

    // ── Retry loop ──────────────────────────────────────────────
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
        let retryNote: string | undefined;
        if (attempt > 0 && lastValidation && lastValidation.issues.length > 0) {
            const errorList = lastValidation.issues.slice(0, 4).map(i => `- ${i}`).join('\n');
            retryNote = `⚠️ FIX THESE ${data.level} LEVEL VIOLATIONS:\n${errorList}\nReplace all forbidden words with simpler ${data.level}-appropriate alternatives.`;
        }

        const prompt = buildPrompt(data, retryNote);

        aiResponse = await callAIWithRetry({
            messages: [
                { role: 'system', content: 'You are a language learning assistant creating CEFR-appropriate dialogues.' },
                { role: 'user', content: prompt },
            ],
            temperature: 0.8,
            maxTokens: 1500,
        });

        const { data: parsed, errors } = parseAndValidate(aiResponse.content, speakingSchema);
        if (errors || !parsed) {
            if (attempt === MAX_RETRIES) throw new Error(`AI javob noto'g'ri: ${errors?.join(', ')}`);
            continue;
        }

        dialogData = parsed;

        // ── CEFR validatsiya ────────────────────────────────────
        lastValidation = validateSpeakingLevel(dialogData, data.level);
        console.log(`📊 Speaking validatsiya (urinish ${attempt + 1}): score=${lastValidation.score}, xatolar=${lastValidation.issues.length}`);

        if (lastValidation.score >= 70) break;

        if (attempt === MAX_RETRIES) {
            console.warn(`⚠️ Speaking ${MAX_RETRIES} urinishdan keyin ham xato: score=${lastValidation.score}`);
        }
    }

    // ── Cost logging ────────────────────────────────────────────
    if (aiResponse) {
        const cost = calculateCost(
            aiResponse.model,
            aiResponse.usage?.promptTokens ?? 0,
            aiResponse.usage?.completionTokens ?? 0,
        );
        await logCost(uid, 'generateSpeakingDialog', {
            model: aiResponse.model,
            promptTokens: aiResponse.usage?.promptTokens ?? 0,
            completionTokens: aiResponse.usage?.completionTokens ?? 0,
            totalTokens: aiResponse.usage?.totalTokens ?? 0,
            cost,
        });
    }

    return dialogData;
}