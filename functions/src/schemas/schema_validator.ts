// functions/src/schemas/schema_validator.ts
// SO'ZONA — Schema Validator (JSON parse + validation)

/// JSON xavfsiz parse qilish
export function safeParseJson(text: string): unknown | null {
    if (!text || text.trim().length === 0) return null;
    try {
        // Markdown ```json ... ``` wrapper'ni olib tashlash
        const cleaned = text.replace(/```json\s*/gi, '').replace(/```\s*/g, '').trim();
        return JSON.parse(cleaned);
    } catch {
        return null;
    }
}

interface ValidationResult {
    valid: boolean;
    errors: string[];
    data?: unknown;
}

/// Quiz sxemasini tekshirish
export function validateQuiz(data: unknown): ValidationResult {
    const errors: string[] = [];

    if (!data || typeof data !== 'object') {
        return { valid: false, errors: ['Data must be an object'] };
    }

    const d = data as Record<string, unknown>;

    if (typeof d.title !== 'string' || d.title.length === 0) {
        errors.push('title is required');
    }

    if (!Array.isArray(d.questions) || d.questions.length === 0) {
        errors.push('questions must be a non-empty array');
        return { valid: false, errors };
    }

    const validTypes = ['mcq', 'true_false', 'fill_blank'];
    (d.questions as unknown[]).forEach((q: unknown, i: number) => {
        if (!q || typeof q !== 'object') {
            errors.push(`Question ${i + 1} must be an object`);
            return;
        }
        const question = q as Record<string, unknown>;
        if (typeof question.id !== 'string') errors.push(`Question ${i + 1}: id required`);
        if (!validTypes.includes(question.type as string)) {
            errors.push(`Question ${i + 1}: invalid type '${question.type}'`);
        }
        if (typeof question.question !== 'string') errors.push(`Question ${i + 1}: question text required`);
        if (typeof question.correctAnswer !== 'string') errors.push(`Question ${i + 1}: correctAnswer required`);
    });

    return {
        valid: errors.length === 0,
        errors,
        data: errors.length === 0 ? data : undefined,
    };
}

/// Flashcard sxemasini tekshirish
export function validateFlashcard(data: unknown): ValidationResult {
    const errors: string[] = [];

    if (!data || typeof data !== 'object') {
        return { valid: false, errors: ['Data must be an object'] };
    }

    const d = data as Record<string, unknown>;

    if (typeof d.title !== 'string' || d.title.length === 0) {
        errors.push('title is required');
    }

    if (!Array.isArray(d.cards) || d.cards.length === 0) {
        errors.push('cards must be a non-empty array');
        return { valid: false, errors };
    }

    (d.cards as unknown[]).forEach((c: unknown, i: number) => {
        if (!c || typeof c !== 'object') {
            errors.push(`Card ${i + 1} must be an object`);
            return;
        }
        const card = c as Record<string, unknown>;
        if (typeof card.id !== 'string') errors.push(`Card ${i + 1}: id required`);
        if (typeof card.front !== 'string' || card.front.length === 0) errors.push(`Card ${i + 1}: front required`);
        if (typeof card.back !== 'string' || card.back.length === 0) errors.push(`Card ${i + 1}: back required`);
    });

    return {
        valid: errors.length === 0,
        errors,
        data: errors.length === 0 ? data : undefined,
    };
}

/// Listening sxemasini tekshirish
export function validateListening(data: unknown): ValidationResult {
    const errors: string[] = [];

    if (!data || typeof data !== 'object') {
        return { valid: false, errors: ['Data must be an object'] };
    }

    const d = data as Record<string, unknown>;

    if (typeof d.title !== 'string' || d.title.length === 0) {
        errors.push('title is required');
    }

    if (typeof d.transcript !== 'string' || d.transcript.length < 50) {
        errors.push('transcript must be at least 50 characters');
    }

    if (!Array.isArray(d.questions) || d.questions.length === 0) {
        errors.push('questions must be a non-empty array');
    }

    return {
        valid: errors.length === 0,
        errors,
        data: errors.length === 0 ? data : undefined,
    };
}

/// JSON Schema bilan tekshirish (validator va flashcard_validator uchun)
export function validateWithSchema(
    data: unknown,
    _schema: unknown
): { isValid: boolean; errors: string[]; data?: unknown } {
    // Haqiqiy AJV schema validation uchun emas, oddiy tekshiruv
    if (!data || typeof data !== 'object') {
        return { isValid: false, errors: ['Invalid data format'] };
    }
    return { isValid: true, errors: [], data };
}

/// parseAndValidate — speaking_dialog va explain_topic uchun
export function parseAndValidate(
    text: string,
    _schema: unknown
): { data: unknown; errors: string[] | null } {
    const parsed = safeParseJson(text);
    if (!parsed) {
        return { data: null, errors: ['Failed to parse JSON response'] };
    }
    return { data: parsed, errors: null };
}
