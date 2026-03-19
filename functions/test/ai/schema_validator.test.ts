// functions/test/ai/schema_validator.test.ts
import { describe, it, expect } from '@jest/globals';
import {
    validateQuiz,
    validateFlashcard,
    validateListening,
    safeParseJson,
} from '../../src/schemas/schema_validator';

describe('Schema Validator', () => {
    describe('safeParseJson', () => {
        it("to'g'ri JSON parse qiladi", () => {
            expect(safeParseJson('{"a":1}')).toEqual({ a: 1 });
        });
        it('markdown wrapper bilan parse qiladi', () => {
            expect(safeParseJson('```json\n{"a":1}\n```')).toEqual({ a: 1 });
        });
        it("noto'g'ri JSON — null", () => {
            expect(safeParseJson('bu json emas')).toBeNull();
        });
        it("bo'sh string — null", () => {
            expect(safeParseJson('')).toBeNull();
        });
    });

    describe('validateQuiz', () => {
        it("to'g'ri quiz sxemasi — valid", () => {
            const data = {
                title: 'Test',
                questions: [{
                    id: 'q1', type: 'mcq', question: 'Savol?',
                    options: ['A', 'B', 'C', 'D'], correctAnswer: 'A',
                }],
            };
            expect(validateQuiz(data).valid).toBe(true);
        });
        it("questions yo'q — invalid", () => {
            expect(validateQuiz({ title: 'Quiz' }).valid).toBe(false);
        });
        it("noto'g'ri type — invalid", () => {
            const data = {
                title: 'Test',
                questions: [{ id: 'q1', type: 'unknown', question: 'Savol?', correctAnswer: 'A' }],
            };
            expect(validateQuiz(data).valid).toBe(false);
        });
    });

    describe('validateFlashcard', () => {
        it("to'g'ri flashcard sxemasi", () => {
            const data = {
                title: "So'zlar",
                cards: [{ id: 'c1', front: 'Haus', back: 'Uy' }],
            };
            expect(validateFlashcard(data).valid).toBe(true);
        });
        it("cards bo'sh — invalid", () => {
            expect(validateFlashcard({ title: 'Test', cards: [] }).valid).toBe(false);
        });
    });

    describe('validateListening', () => {
        it("to'g'ri listening sxemasi", () => {
            const data = {
                title: 'Dialog',
                transcript: 'A'.repeat(60),
                questions: [{ id: 'q1', question: 'Kim?', correctAnswer: 'Ali' }],
            };
            expect(validateListening(data).valid).toBe(true);
        });
        it("qisqa transcript — invalid", () => {
            const data = {
                title: 'Dialog',
                transcript: 'Qisqa',
                questions: [{ id: 'q1', question: 'Kim?', correctAnswer: 'Ali' }],
            };
            expect(validateListening(data).valid).toBe(false);
        });
    });
});
