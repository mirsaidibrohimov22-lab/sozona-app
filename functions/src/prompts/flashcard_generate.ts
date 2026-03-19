// functions/src/prompts/flashcard_generate.ts
// ✅ v3.0: CEFR validatsiya + avtomatik retry (max 2 marta) qo'shildi

import { aiRouter } from '../ai/ai_router';
import { validateWithSchema } from '../schemas/schema_validator';
import flashcardSchema from '../schemas/flashcard_schema.json';
import { buildLevelBlock, type CEFRLevel } from './cefr_level_guide';
import { validateFlashcardsLevel, buildRetryNote } from './cefr_validator';

const WORD_TYPE_GUIDE: Record<CEFRLevel, string> = {
    A1: 'ONLY the most basic, high-frequency words for absolute beginners: single nouns and simple verbs only. No phrasal verbs, no idioms, no abstract words.',
    A2: 'Common everyday words for basic communication. Simple adjectives and common verbs. No phrasal verbs.',
    B1: 'Useful everyday vocabulary including common phrasal verbs (give up, look forward to) and collocations.',
    B2: 'Academic and professional vocabulary, idiomatic expressions, formal/informal pairs, complex collocations.',
    C1: 'Sophisticated vocabulary, nuanced synonyms, formal register, idiomatic expressions, advanced terms.',
};

const EXAMPLE_GUIDE: Record<CEFRLevel, string> = {
    A1: 'MAX 5 words. Present simple only. E.g: "I have a cat."',
    A2: 'MAX 8 words. Simple tenses. E.g: "She went to the shop."',
    B1: 'MAX 15 words. Any common tense.',
    B2: 'MAX 20 words. Complex structures allowed.',
    C1: 'Natural length. Show word in authentic context.',
};

function buildPrompt(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    cardCount: number;
    includeExamples: boolean;
    includePronunciation: boolean;
    retryNote?: string;
}): string {
    const { language, level, topic, cardCount, includeExamples, includePronunciation, retryNote } = params;
    const languageName = language === 'en' ? 'English' : 'German';
    const levelBlock = buildLevelBlock(level, language);
    const retryBlock = retryNote ? `\n\n${retryNote}` : '';

    return `You are an expert ${languageName} language teacher creating flashcards.

${levelBlock}

Topic: "${topic}"
Cards: ${cardCount}
${includePronunciation ? 'Include IPA pronunciation.' : ''}
${includeExamples ? 'Include example sentences.' : ''}

Word selection for ${level}: ${WORD_TYPE_GUIDE[level]}
Example sentence rule: ${EXAMPLE_GUIDE[level]}

CRITICAL: Every word on every card MUST be within ${level} level.
Translation must be in Uzbek.${retryBlock}

Return ONLY valid JSON:
{
  "cards": [
    {
      "id": "fc1",
      "front": "${languageName} word",
      "back": "O'zbek tarjimasi",
      "pronunciation": "/IPA/",
      "exampleSentence": "${level} level example",
      "exampleTranslation": "O'zbekcha",
      "tags": ["${topic}","${level}"]
    }
  ]
}

Generate EXACTLY ${cardCount} different cards.`;
}

export async function generateFlashcards(params: {
    language: 'en' | 'de';
    level: CEFRLevel;
    topic: string;
    cardCount: number;
    includeExamples?: boolean;
    includePronunciation?: boolean;
}): Promise<unknown> {
    const {
        language, level, topic, cardCount,
        includeExamples = true, includePronunciation = true,
    } = params;

    const MAX_RETRIES = 2;
    let lastValidation = null;
    let cards: Array<Record<string, unknown>> = [];

    // ── Retry loop ──────────────────────────────────────────────
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
        const retryNote = attempt > 0 && lastValidation
            ? buildRetryNote(lastValidation, level)
            : undefined;

        const prompt = buildPrompt({
            language, level, topic, cardCount,
            includeExamples, includePronunciation, retryNote,
        });

        const response = await aiRouter({ prompt, schema: flashcardSchema, maxTokens: 2500, temperature: 0.6 });

        let rawData: Record<string, unknown>;
        try {
            rawData = JSON.parse(response.text || '{}') as Record<string, unknown>;
        } catch {
            if (attempt === MAX_RETRIES) throw new Error('AI JSON qaytarmadi');
            continue;
        }

        const validated = validateWithSchema(rawData, flashcardSchema);
        if (!validated.isValid) {
            if (attempt === MAX_RETRIES) throw new Error(`Schema xato: ${validated.errors.join(', ')}`);
            continue;
        }

        const data = validated.data as Record<string, unknown>;
        cards = data.cards as Array<Record<string, unknown>>;

        // ── CEFR validatsiya ────────────────────────────────────
        lastValidation = validateFlashcardsLevel(cards, level);
        console.log(`📊 Flashcard validatsiya (urinish ${attempt + 1}): ${lastValidation.summary}`);

        if (lastValidation.isValid || lastValidation.score >= 70) break;

        if (attempt === MAX_RETRIES) {
            console.warn(`⚠️ Flashcard ${MAX_RETRIES} urinishdan keyin ham xato: score=${lastValidation.score}`);
            console.warn('Xatolar:', lastValidation.issues.map(i => i.message).join(' | '));
        }
    }

    return {
        cards,
        totalCards: cards.length,
        metadata: {
            language, level, topic, includeExamples, includePronunciation,
            generatedAt: new Date().toISOString(),
        },
        cefrValidation: lastValidation ? { score: lastValidation.score, summary: lastValidation.summary } : null,
    };
}