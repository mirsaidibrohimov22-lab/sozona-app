// functions/src/middleware/rate_limiter.ts
// SO'ZONA — Rate Limiter

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const RATE_LIMIT = 60; // 60 requests per hour
const WINDOW = 60 * 60 * 1000; // 1 hour

export async function checkRateLimit(uid: string): Promise<void> {
    const now = Date.now();
    const rateLimitRef = admin.firestore().collection('rate_limits').doc(uid);

    try {
        const doc = await rateLimitRef.get();

        if (!doc.exists) {
            await rateLimitRef.set({ count: 1, windowStart: now, lastRequest: now });
            return;
        }

        const data = doc.data()!;
        const windowStart = data.windowStart as number;
        const count = data.count as number;

        if (now - windowStart > WINDOW) {
            await rateLimitRef.set({ count: 1, windowStart: now, lastRequest: now });
            return;
        }

        if (count >= RATE_LIMIT) {
            const resetTime = new Date(windowStart + WINDOW);
            throw new functions.https.HttpsError(
                'resource-exhausted',
                `Juda ko'p so'rov. Iltimos, ${resetTime.toLocaleTimeString()} dan keyin urinib ko'ring.`
            );
        }

        await rateLimitRef.update({
            count: admin.firestore.FieldValue.increment(1),
            lastRequest: now,
        });

    } catch (error: unknown) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error('Rate limit error:', error);
    }
}

export async function getRateLimitStatus(uid: string): Promise<{
    remaining: number;
    resetAt: Date;
}> {
    const doc = await admin.firestore().collection('rate_limits').doc(uid).get();

    if (!doc.exists) {
        return { remaining: RATE_LIMIT, resetAt: new Date(Date.now() + WINDOW) };
    }

    const data = doc.data()!;
    const remaining = Math.max(0, RATE_LIMIT - (data.count as number));
    const resetAt = new Date((data.windowStart as number) + WINDOW);
    return { remaining, resetAt };
}
