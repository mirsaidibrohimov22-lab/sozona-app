// functions/src/ai/validators/quiz_validator.ts
// Quiz Validator — AI yaratgan quizni tekshirish

import { validateWithSchema } from '../../schemas/schema_validator';
import quizSchema from '../../schemas/quiz_schema.json';

interface QuizValidationResult {
    isValid: boolean;
    errors: string[];
    warnings: string[];
    data?: unknown;
}

export function validateQuiz(
    quizData: unknown,
    expectedQuestionCount?: number
): QuizValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];

    const schemaResult = validateWithSchema(quizData, quizSchema);
    if (!schemaResult.isValid) {
        return { isValid: false, errors: schemaResult.errors, warnings: [] };
    }

    if (!quizData || typeof quizData !== 'object') {
        return { isValid: false, errors: ['Invalid data'], warnings: [] };
    }

    const data = quizData as Record<string, unknown>;
    const questions = data.questions as Array<Record<string, unknown>>;

    if (!Array.isArray(questions)) {
        return { isValid: false, errors: ['questions must be an array'], warnings: [] };
    }

    if (expectedQuestionCount && questions.length !== expectedQuestionCount) {
        errors.push(`Expected ${expectedQuestionCount} questions, got ${questions.length}`);
    }

    questions.forEach((question: Record<string, unknown>, index: number) => {
        const questionNum = index + 1;

        if (question.type === 'mcq') {
            const options = question.options as unknown[];
            if (!Array.isArray(options) || options.length !== 4) {
                errors.push(`Question ${questionNum}: MCQ must have exactly 4 options`);
            }
        }

        if (question.type === 'true_false') {
            const options = question.options as unknown[];
            if (!Array.isArray(options) || options.length !== 2) {
                errors.push(`Question ${questionNum}: True/False must have exactly 2 options`);
            }
        }

        if (question.type !== 'fill_blank' && Array.isArray(question.options)) {
            const options = question.options as string[];
            const correctAnswer = question.correctAnswer as string;
            const correctAnswerExists = options.some(
                (opt: string) => opt.trim().toLowerCase() === correctAnswer?.trim().toLowerCase()
            );
            if (!correctAnswerExists) {
                errors.push(`Question ${questionNum}: Correct answer not found in options`);
            }
        }

        const questionText = (question.question as string)?.trim() ?? '';
        if (questionText.length < 10) {
            errors.push(`Question ${questionNum}: Question text too short`);
        }

        if (Array.isArray(question.options)) {
            const uniqueOptions = new Set((question.options as string[]).map((opt: string) => opt.trim().toLowerCase()));
            if (uniqueOptions.size !== (question.options as string[]).length) {
                errors.push(`Question ${questionNum}: Duplicate options found`);
            }
        }
    });

    const totalPoints = questions.reduce(
        (sum: number, q: Record<string, unknown>) => sum + ((q.points as number) || 10),
        0
    );
    if (totalPoints < 10) {
        warnings.push(`Total points (${totalPoints}) seems too low`);
    }

    return {
        isValid: errors.length === 0,
        errors,
        warnings,
        data: errors.length === 0 ? quizData : undefined,
    };
}

export function validateQuizStrict(
    quizData: unknown,
    expectedQuestionCount?: number
): { isValid: boolean; message: string; data?: unknown } {
    const result = validateQuiz(quizData, expectedQuestionCount);

    if (!result.isValid) {
        return { isValid: false, message: `Validation failed: ${result.errors.join('; ')}` };
    }

    if (result.warnings.length > 0) {
        console.warn('Quiz validation warnings:', result.warnings);
    }

    const data = quizData as Record<string, unknown>;
    const questions = data.questions as unknown[];
    return {
        isValid: true,
        message: `Valid quiz with ${questions.length} questions`,
        data: result.data,
    };
}
