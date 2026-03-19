// functions/test/middleware/rate_limiter.test.ts
import { describe, it, expect, jest, beforeEach } from '@jest/globals';

const mockSet = jest.fn();
const mockRunTransaction = jest.fn();

jest.mock('firebase-admin', () => ({
    firestore: jest.fn(() => ({
        collection: jest.fn(() => ({ doc: jest.fn(() => ({})) })),
        runTransaction: mockRunTransaction,
    })),
}));

jest.mock('firebase-functions', () => ({
    logger: { warn: jest.fn(), error: jest.fn() },
    https: {
        HttpsError: class HttpsError extends Error {
            constructor(public code: string, message: string) {
                super(message);
            }
        },
    },
}));

describe('Rate Limiter', () => {
    beforeEach(() => jest.clearAllMocks());

    it("limitdan oshilmasa — o'tkazib yuboradi", async () => {
        mockRunTransaction.mockImplementation(async (fn: (tx: {
            get: jest.Mock;
            set: jest.Mock;
        }) => Promise<void>) => {
            await fn({
                get: jest.fn().mockResolvedValue({
                    data: () => ({ requests: [], userId: 'u1', action: 'quiz' }),
                }),
                set: mockSet,
            });
        });

        const { checkRateLimit } = await import('../../src/middleware/rate_limiter');
        await expect(checkRateLimit('u1')).resolves.not.toThrow();
    });

    it('limit oshsa — HttpsError qaytaradi', async () => {
        const now = Date.now();
        const fullRequests = Array(60).fill(now - 1000) as number[];

        mockRunTransaction.mockImplementation(async (fn: (tx: {
            get: jest.Mock;
            set: jest.Mock;
        }) => Promise<void>) => {
            await fn({
                get: jest.fn().mockResolvedValue({
                    data: () => ({ requests: fullRequests }),
                }),
                set: mockSet,
            });
        });

        const { checkRateLimit } = await import('../../src/middleware/rate_limiter');
        await expect(checkRateLimit('u1')).rejects.toThrow();
    });
});
