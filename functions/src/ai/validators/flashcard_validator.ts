// functions/src/ai/validators/flashcard_validator.ts
// Flashcard Validator — AI yaratgan flashcard to'plamini tekshirish

import { validateWithSchema } from '../../schemas/schema_validator';
import flashcardSchema from '../../schemas/flashcard_schema.json';

interface FlashcardValidationResult {
    isValid: boolean;
    errors: string[];
    warnings: string[];
    data?: unknown;
}

export function validateFlashcards(
    flashcardData: unknown,
    expectedCardCount?: number
): FlashcardValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];

    const schemaResult = validateWithSchema(flashcardData, flashcardSchema);
    if (!schemaResult.isValid) {
        return { isValid: false, errors: schemaResult.errors, warnings: [] };
    }

    if (!flashcardData || typeof flashcardData !== 'object') {
        return { isValid: false, errors: ['Invalid data'], warnings: [] };
    }

    const data = flashcardData as Record<string, unknown>;
    const cards = data.cards as Array<Record<string, unknown>>;

    if (!Array.isArray(cards)) {
        return { isValid: false, errors: ['cards must be an array'], warnings: [] };
    }

    if (expectedCardCount && cards.length !== expectedCardCount) {
        errors.push(`Expected ${expectedCardCount} cards, got ${cards.length}`);
    }

    if (cards.length < 1) {
        errors.push('At least 1 card is required');
    }

    const seenFronts = new Set<string>();
    const seenBacks = new Set<string>();

    cards.forEach((card: Record<string, unknown>, index: number) => {
        const cardNum = index + 1;

        const frontTrimmed = (card.front as string)?.trim() ?? '';
        if (frontTrimmed.length < 1) {
            errors.push(`Card ${cardNum}: Front is empty`);
        } else if (frontTrimmed.length < 2) {
            warnings.push(`Card ${cardNum}: Front is too short`);
        }

        const backTrimmed = (card.back as string)?.trim() ?? '';
        if (backTrimmed.length < 1) {
            errors.push(`Card ${cardNum}: Back is empty`);
        }

        const frontLower = frontTrimmed.toLowerCase();
        if (seenFronts.has(frontLower)) {
            errors.push(`Card ${cardNum}: Duplicate front text "${frontTrimmed}"`);
        }
        seenFronts.add(frontLower);

        const backLower = backTrimmed.toLowerCase();
        if (seenBacks.has(backLower) && cards.length < 50) {
            warnings.push(`Card ${cardNum}: Duplicate back text "${backTrimmed}"`);
        }
        seenBacks.add(backLower);

        if (card.pronunciation) {
            const pronTrimmed = (card.pronunciation as string).trim();
            if (!pronTrimmed.startsWith('/') || !pronTrimmed.endsWith('/')) {
                warnings.push(`Card ${cardNum}: Pronunciation should be in IPA format (/.../)"`);
            }
        }

        if (card.tags && Array.isArray(card.tags)) {
            (card.tags as string[]).forEach((tag: string, tagIndex: number) => {
                if (!/^[a-z_]+$/.test(tag)) {
                    warnings.push(`Card ${cardNum}, Tag ${tagIndex + 1}: Invalid format "${tag}"`);
                }
            });
        }
    });

    return {
        isValid: errors.length === 0,
        errors,
        warnings,
        data: errors.length === 0 ? flashcardData : undefined,
    };
}

export function validateFlashcardsStrict(
    flashcardData: unknown,
    expectedCardCount?: number
): { isValid: boolean; message: string; data?: unknown } {
    const result = validateFlashcards(flashcardData, expectedCardCount);

    if (!result.isValid) {
        return { isValid: false, message: `Validation failed: ${result.errors.join('; ')}` };
    }

    if (result.warnings.length > 0) {
        console.warn('Flashcard validation warnings:', result.warnings);
    }

    const data = flashcardData as Record<string, unknown>;
    const cards = data.cards as unknown[];
    return {
        isValid: true,
        message: `Valid flashcard set with ${cards.length} cards`,
        data: result.data,
    };
}
