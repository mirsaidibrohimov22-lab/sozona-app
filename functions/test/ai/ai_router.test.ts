// functions/test/ai/ai_router.test.ts
import { describe, it, expect, jest, beforeEach } from '@jest/globals';

jest.mock('openai');
jest.mock('@google/generative-ai');
jest.mock('firebase-functions', () => ({
    config: () => ({ openai: { key: 'test-key' }, gemini: { key: 'test-key' } }),
    logger: { warn: jest.fn(), error: jest.fn(), info: jest.fn() },
}));

describe('AI Router', () => {
    beforeEach(() => jest.clearAllMocks());

    it('OpenAI muvaffaqiyatli javob qaytaradi', async () => {
        const OpenAI = (await import('openai')).default as jest.MockedClass<typeof import('openai').default>;
        OpenAI.mockImplementation(() => ({
            chat: {
                completions: {
                    create: jest.fn().mockResolvedValue({
                        choices: [{ message: { content: '{"result":"ok"}' } }],
                        usage: { total_tokens: 50, prompt_tokens: 20, completion_tokens: 30 },
                        model: 'gpt-4o-mini',
                    }),
                },
            },
        }) as unknown as InstanceType<typeof import('openai').default>);

        const { openAiComplete } = await import('../../src/ai/openai_client');
        const result = await openAiComplete('test prompt', undefined, true);
        expect(result).toBe('{"result":"ok"}');
    });

    it('Gemini fallback muvaffaqiyatli ishlaydi', async () => {
        const { GoogleGenerativeAI } = (await import('@google/generative-ai')) as {
            GoogleGenerativeAI: jest.MockedClass<typeof import('@google/generative-ai').GoogleGenerativeAI>;
        };
        GoogleGenerativeAI.mockImplementation(() => ({
            getGenerativeModel: () => ({
                generateContent: jest.fn().mockResolvedValue({
                    response: { text: () => 'Gemini javobi' },
                }),
            }),
        }) as unknown as InstanceType<typeof import('@google/generative-ai').GoogleGenerativeAI>);

        const { geminiComplete } = await import('../../src/ai/gemini_client');
        const result = await geminiComplete('test prompt');
        expect(result).toBe('Gemini javobi');
    });

    it('System prompt qo\'shiladi', async () => {
        const OpenAI = (await import('openai')).default as jest.MockedClass<typeof import('openai').default>;
        const mockCreate = jest.fn().mockResolvedValue({
            choices: [{ message: { content: 'javob' } }],
            usage: { total_tokens: 30, prompt_tokens: 10, completion_tokens: 20 },
            model: 'gpt-4o-mini',
        });
        OpenAI.mockImplementation(() => ({
            chat: { completions: { create: mockCreate } },
        }) as unknown as InstanceType<typeof import('openai').default>);

        const { openAiComplete } = await import('../../src/ai/openai_client');
        await openAiComplete('user prompt', 'system prompt');

        const call = mockCreate.mock.calls[0]?.[0] as { messages: Array<{ role: string; content: string }> };
        expect(call.messages[0].role).toBe('system');
        expect(call.messages[0].content).toBe('system prompt');
    });
});
