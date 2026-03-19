// functions/src/prompts/cefr_validator.ts
// ✅ YANGI: AI tomonidan yaratilgan kontentni CEFR darajasiga tekshiradi
// Xato bo'lsa avtomatik qayta so'rov yuboradi (max 2 marta)
//
// QANDAY ISHLATILADI:
//   quiz_generate.ts, listening_generate.ts, flashcard_generate.ts da
//   AI javobini qaytarishdan OLDIN shu validator orqali o'tkaziladi.

import type { CEFRLevel } from './cefr_level_guide';

// ─── Taqiqlangan so'zlar darajaga qarab ───────────────────────

// Har daraja uchun: bu so'zlar paydo bo'lsa — daraja NOTO'G'RI
export const FORBIDDEN_WORDS_BY_LEVEL: Record<CEFRLevel, string[]> = {
    A1: [
        // B1+ so'zlar — A1 da bo'lmasligi kerak
        'relaxing', 'exercise', 'popular', 'prefer', 'sometimes', 'together',
        'wonderful', 'fantastic', 'experience', 'activity', 'interesting',
        'important', 'different', 'opportunity', 'community', 'environment',
        'traditional', 'celebration', 'technology', 'information', 'education',
        'competition', 'performance', 'professional', 'international',
        'unfortunately', 'comfortable', 'approximately', 'immediately',
        'although', 'however', 'therefore', 'furthermore', 'nevertheless',
        // German A1 taqiqlangan
        'normalerweise', 'interessant', 'manchmal', 'zusammen', 'vielleicht',
        'natürlich', 'besonders', 'eigentlich', 'wahrscheinlich',
    ],
    A2: [
        // B2+ so'zlar — A2 da bo'lmasligi kerak
        'sophisticated', 'comprehensive', 'fundamental', 'consequently',
        'nevertheless', 'furthermore', 'approximately', 'substantially',
        'predominantly', 'simultaneously', 'controversial', 'ambiguous',
        'implications', 'perspective', 'significant', 'demonstrate',
        // German A2 taqiqlangan
        'selbstverständlich', 'ausgezeichnet', 'bemerkenswert',
        'außerordentlich', 'gewissermaßen',
    ],
    B1: [
        // C1+ so'zlar — B1 da bo'lmasligi kerak
        'ubiquitous', 'quintessential', 'paradigm', 'juxtapose', 'ameliorate',
        'exacerbate', 'idiosyncratic', 'surreptitious', 'perspicacious',
        'obfuscate', 'disingenuous', 'supercilious', 'ephemeral',
    ],
    B2: [
        // C2 so'zlar
        'ululate', 'tmesis', 'susurrus', 'anfractuous', 'borborygmus',
    ],
    C1: [], // C1 da hech narsa taqiqlanmagan
};

// ─── Grammatika tekshiruvi ────────────────────────────────────

// A1 da faqat present simple bo'lishi kerak
// Bu regex past tense irregular verb larni topadi
const PAST_TENSE_IRREGULAR = /\b(went|came|said|got|made|knew|took|saw|came|gave|found|thought|told|became|showed|felt|left|put|brought|began|kept|held|wrote|stood|heard|let|meant|set|met|ran|paid|sat|spoke|led|read|grew|lost|fell|sent|built|understood|drew|chose|broke|spent|cut|rose|drove|bought|caught|taught|fought|sought|brought|sold|told|won|hung|dug|lit|wore|tore|stole|swore|froze|chose|wove|dealt|lent|bent|leant|crept|slept|wept|swept|kept|felt|smelt|spelt|built|burnt|learnt|dreamt)\b/gi;

// ─── So'z soni tekshiruvi ─────────────────────────────────────

const MAX_WORDS_PER_SENTENCE: Record<CEFRLevel, number> = {
    A1: 7,
    A2: 12,
    B1: 22,
    B2: 35,
    C1: 999,
};

const MAX_TRANSCRIPT_WORDS: Record<CEFRLevel, number> = {
    A1: 70,
    A2: 120,
    B1: 200,
    B2: 310,
    C1: 999,
};

// ─── Validatsiya natijasi ─────────────────────────────────────

export interface ValidationIssue {
    type: 'forbidden_word' | 'sentence_too_long' | 'wrong_grammar' | 'transcript_too_long' | 'missing_field';
    message: string;
    severity: 'error' | 'warning';
}

export interface CEFRValidationResult {
    isValid: boolean;
    score: number;        // 0-100: 100 = mukammal, 70+ = qabul qilinadi
    issues: ValidationIssue[];
    summary: string;
}

// ─── Asosiy validator ─────────────────────────────────────────

/**
 * Quiz savollarini CEFR darajasiga tekshiradi
 */
export function validateQuizLevel(
    questions: Record<string, unknown>[],
    level: CEFRLevel,
): CEFRValidationResult {
    const issues: ValidationIssue[] = [];
    const forbidden = FORBIDDEN_WORDS_BY_LEVEL[level];
    const maxWords = MAX_WORDS_PER_SENTENCE[level];

    for (const [qi, q] of questions.entries()) {
        const qNum = qi + 1;
        const questionText = String(q['question'] || '').toLowerCase();
        const explanation = String(q['explanation'] || '').toLowerCase();
        const options = Array.isArray(q['options']) ? q['options'].map(String) : [];
        const allText = [questionText, explanation, ...options].join(' ');

        // 1. Taqiqlangan so'zlarni tekshir
        for (const word of forbidden) {
            if (allText.includes(word.toLowerCase())) {
                issues.push({
                    type: 'forbidden_word',
                    message: `Q${qNum}: "${word}" so'zi ${level} darajasida qo'llanilmaydi`,
                    severity: 'error',
                });
            }
        }

        // 2. Gap uzunligini tekshir
        const sentences = String(q['question'] || '').split(/[.!?]+/).filter(Boolean);
        for (const sentence of sentences) {
            const wordCount = sentence.trim().split(/\s+/).length;
            if (wordCount > maxWords) {
                issues.push({
                    type: 'sentence_too_long',
                    message: `Q${qNum}: gap ${wordCount} so'z, ${level} uchun max ${maxWords} ta ruxsat`,
                    severity: level === 'A1' || level === 'A2' ? 'error' : 'warning',
                });
            }
        }

        // 3. A1 da past tense tekshir
        if (level === 'A1') {
            const pastMatches = String(q['question'] || '').match(PAST_TENSE_IRREGULAR);
            if (pastMatches) {
                issues.push({
                    type: 'wrong_grammar',
                    message: `Q${qNum}: A1 da past tense ruxsat emas (topildi: ${pastMatches.join(', ')})`,
                    severity: 'error',
                });
            }
        }
    }

    const errorCount = issues.filter(i => i.severity === 'error').length;
    const score = Math.max(0, 100 - errorCount * 15);

    return {
        isValid: errorCount === 0,
        score,
        issues,
        summary: errorCount === 0
            ? `✅ ${level} darajasiga mos (${questions.length} savol tekshirildi)`
            : `❌ ${errorCount} xato topildi — qayta yaratish kerak`,
    };
}

/**
 * Listening transcript ni CEFR darajasiga tekshiradi
 */
export function validateListeningLevel(
    transcript: string,
    questions: Record<string, unknown>[],
    level: CEFRLevel,
): CEFRValidationResult {
    const issues: ValidationIssue[] = [];
    const forbidden = FORBIDDEN_WORDS_BY_LEVEL[level];
    const transcriptLower = transcript.toLowerCase();

    // 1. Taqiqlangan so'zlar
    for (const word of forbidden) {
        if (transcriptLower.includes(word.toLowerCase())) {
            issues.push({
                type: 'forbidden_word',
                message: `Transcript: "${word}" so'zi ${level} darajasida qo'llanilmaydi`,
                severity: 'error',
            });
        }
    }

    // 2. Transcript uzunligi
    const wordCount = transcript.split(/\s+/).length;
    const maxWords = MAX_TRANSCRIPT_WORDS[level];
    if (wordCount > maxWords * 1.3) {  // 30% tolerance
        issues.push({
            type: 'transcript_too_long',
            message: `Transcript ${wordCount} so'z, ${level} uchun max ~${maxWords} ta`,
            severity: 'warning',
        });
    }

    // 3. A1 da past tense
    if (level === 'A1') {
        const pastMatches = transcript.match(PAST_TENSE_IRREGULAR);
        if (pastMatches && pastMatches.length > 2) {
            issues.push({
                type: 'wrong_grammar',
                message: `Transcript: A1 da past tense ko'p ishlatilgan (${pastMatches.slice(0, 3).join(', ')}...)`,
                severity: 'error',
            });
        }
    }

    // 4. Savollarni ham tekshir
    const questionResult = validateQuizLevel(questions, level);
    issues.push(...questionResult.issues);

    const errorCount = issues.filter(i => i.severity === 'error').length;
    const score = Math.max(0, 100 - errorCount * 15);

    return {
        isValid: errorCount === 0,
        score,
        issues,
        summary: errorCount === 0
            ? `✅ ${level} darajasiga mos (${wordCount} so'z, ${questions.length} savol)`
            : `❌ ${errorCount} xato topildi`,
    };
}

/**
 * Flashcard kartalarini CEFR darajasiga tekshiradi
 */
export function validateFlashcardsLevel(
    cards: Record<string, unknown>[],
    level: CEFRLevel,
): CEFRValidationResult {
    const issues: ValidationIssue[] = [];
    const forbidden = FORBIDDEN_WORDS_BY_LEVEL[level];
    const maxWords = MAX_WORDS_PER_SENTENCE[level];

    for (const [ci, card] of cards.entries()) {
        const cardNum = ci + 1;
        const front = String(card['front'] || '').toLowerCase();
        const example = String(card['exampleSentence'] || '').toLowerCase();
        const allText = `${front} ${example}`;

        // 1. Taqiqlangan so'zlar
        for (const word of forbidden) {
            if (allText.includes(word.toLowerCase())) {
                issues.push({
                    type: 'forbidden_word',
                    message: `Karta ${cardNum}: "${word}" so'zi ${level} uchun murakkab`,
                    severity: 'error',
                });
            }
        }

        // 2. Misol gap uzunligi
        if (card['exampleSentence']) {
            const exWordCount = String(card['exampleSentence']).split(/\s+/).length;
            if (exWordCount > maxWords) {
                issues.push({
                    type: 'sentence_too_long',
                    message: `Karta ${cardNum}: misol gap ${exWordCount} so'z, max ${maxWords}`,
                    severity: 'warning',
                });
            }
        }

        // 3. Majburiy maydonlar
        if (!card['front'] || !card['back']) {
            issues.push({
                type: 'missing_field',
                message: `Karta ${cardNum}: front yoki back bo'sh`,
                severity: 'error',
            });
        }
    }

    const errorCount = issues.filter(i => i.severity === 'error').length;
    const score = Math.max(0, 100 - errorCount * 10);

    return {
        isValid: errorCount === 0,
        score,
        issues,
        summary: errorCount === 0
            ? `✅ ${level} darajasiga mos (${cards.length} karta tekshirildi)`
            : `❌ ${errorCount} xato topildi`,
    };
}

// ─── Qayta so'rov yordamchi ───────────────────────────────────

/**
 * Validatsiya xatolarini AI ga tushunarli tuzatish ko'rsatmasiga aylantiradi.
 * Bu string qayta-prompt (retry prompt) ga qo'shiladi.
 */
export function buildRetryNote(result: CEFRValidationResult, level: CEFRLevel): string {
    const errorMessages = result.issues
        .filter(i => i.severity === 'error')
        .slice(0, 5)  // max 5 ta xato ko'rsatamiz
        .map(i => `- ${i.message}`)
        .join('\n');

    return `
⚠️ PREVIOUS ATTEMPT HAD ${level} LEVEL VIOLATIONS. FIX THESE ERRORS:
${errorMessages}

STRICT REMINDER for ${level}:
- Replace ALL forbidden words with simpler ${level}-appropriate alternatives
- Shorten ALL sentences that exceed the word limit
- Do NOT use past tense in A1 content
Generate again with these corrections applied to every item.
`.trim();
}