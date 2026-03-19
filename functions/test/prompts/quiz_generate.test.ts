// functions/test/prompts/quiz_generate.test.ts
import { describe, it, expect } from '@jest/globals';
import { buildQuizPrompt } from '../../src/prompts/quiz_generate';

describe('buildQuizPrompt', () => {
    const base = { language: 'de' as const, level: 'A2' as const, topic: 'Modalverben', questionCount: 5 };

    it('system va user prompt qaytaradi', () => {
        const result = buildQuizPrompt(base);
        expect(result).toHaveProperty('system');
        expect(result).toHaveProperty('user');
        expect(result.system.length).toBeGreaterThan(20);
        expect(result.user.length).toBeGreaterThan(20);
    });

    it('mavzu user promptda mavjud', () => {
        expect(buildQuizPrompt(base).user).toContain('Modalverben');
    });

    it('daraja user promptda mavjud', () => {
        expect(buildQuizPrompt(base).user).toContain('A2');
    });

    it("savollar soni user promptda ko'rsatilgan", () => {
        expect(buildQuizPrompt(base).user).toContain('5');
    });

    it("zaif mavzular qo'shiladi", () => {
        const result = buildQuizPrompt({ ...base, weakItems: ['mögen', 'können'] });
        expect(result.user).toContain('mögen');
        expect(result.user).toContain('können');
    });

    it("ingliz tili uchun system promptda 'ingliz' so'zi", () => {
        const result = buildQuizPrompt({ ...base, language: 'en' });
        expect(result.system).toContain('ingliz');
    });

    it("nemis tili uchun system promptda 'nemis' so'zi", () => {
        expect(buildQuizPrompt(base).system).toContain('nemis');
    });

    it("JSON format talab qilinadi", () => {
        const result = buildQuizPrompt(base);
        expect(result.user).toContain('JSON');
        expect(result.user).toContain('"questions"');
    });
});
