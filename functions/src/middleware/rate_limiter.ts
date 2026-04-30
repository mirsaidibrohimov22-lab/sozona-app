// functions/src/middleware/rate_limiter.ts
// SO'ZONA — Rate Limiter
// ✅ Umumiy: soatiga 60 ta so'rov (barcha funksiyalar)
// ✅ AI Chat: tekin — kuniga 10 ta, premium — kuniga 20 ta (500 token)

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// ── Umumiy rate limit (barcha funksiyalar uchun) ──────────────
const RATE_LIMIT = 60;          // soatiga 60 ta so'rov
const WINDOW = 60 * 60 * 1000; // 1 soat (ms)

// ── AI Chat kunlik limitlar ───────────────────────────────────
const CHAT_LIMIT_FREE = 10;  // tekin: kuniga 10 ta
const CHAT_LIMIT_PREMIUM = 20;  // premium: kuniga 20 ta
const DAY_WINDOW = 24 * 60 * 60 * 1000; // 1 kun (ms)

// ─────────────────────────────────────────────────────────────
// UMUMIY RATE LIMIT (chatWithAI dan tashqari barcha funksiyalar)
// ─────────────────────────────────────────────────────────────
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

        // Yangi oyna — reset
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

// ─────────────────────────────────────────────────────────────
// AI CHAT KUNLIK LIMIT
// Tekin: kuniga 10 ta | Premium: kuniga 20 ta (500 token)
// ─────────────────────────────────────────────────────────────
export async function checkChatDailyLimit(uid: string): Promise<void> {
    const now = Date.now();
    const db = admin.firestore();

    // 1. Foydalanuvchi premium ekanligini tekshirish
    const userSnap = await db.collection('users').doc(uid).get();
    const userData = userSnap.data() ?? {};
    const isPremium = (userData.isPremium as boolean) ?? false;
    const premiumExpiresAt = userData.premiumExpiresAt as admin.firestore.Timestamp | undefined;
    const hasActivePremium = isPremium && (
        !premiumExpiresAt || premiumExpiresAt.toMillis() > now
    );

    const dailyLimit = hasActivePremium ? CHAT_LIMIT_PREMIUM : CHAT_LIMIT_FREE;

    // 2. Kunlik chat counter
    const chatLimitRef = db.collection('chat_limits').doc(uid);
    const doc = await chatLimitRef.get();

    if (!doc.exists) {
        await chatLimitRef.set({ count: 1, dayStart: now });
        return;
    }

    const data = doc.data()!;
    const dayStart = data.dayStart as number;
    const count = data.count as number;

    // Yangi kun — reset
    if (now - dayStart > DAY_WINDOW) {
        await chatLimitRef.set({ count: 1, dayStart: now });
        return;
    }

    // Limit tekshiruvi
    if (count >= dailyLimit) {
        const resetTime = new Date(dayStart + DAY_WINDOW);
        const resetHour = resetTime.toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' });

        if (hasActivePremium) {
            throw new functions.https.HttpsError(
                'resource-exhausted',
                `Kunlik ${CHAT_LIMIT_PREMIUM} ta savol limitiga yetdingiz. Ertaga ${resetHour} da yangilanadi.`
            );
        } else {
            throw new functions.https.HttpsError(
                'resource-exhausted',
                `Tekin foydalanuvchilar uchun kunlik ${CHAT_LIMIT_FREE} ta savol limiti. Premium oling yoki ertaga ${resetHour} da qaytib keling.`
            );
        }
    }

    // Counterni oshirish
    await chatLimitRef.update({
        count: admin.firestore.FieldValue.increment(1),
    });
}

// ─────────────────────────────────────────────────────────────
// QOLGAN CHAT SONINI OLISH (UI uchun)
// ─────────────────────────────────────────────────────────────
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

export async function getChatLimitStatus(uid: string): Promise<{
    used: number;
    limit: number;
    remaining: number;
    isPremium: boolean;
    resetAt: Date;
}> {
    const now = Date.now();
    const db = admin.firestore();

    const userSnap = await db.collection('users').doc(uid).get();
    const userData = userSnap.data() ?? {};
    const isPremium = (userData.isPremium as boolean) ?? false;
    const premiumExpiresAt = userData.premiumExpiresAt as admin.firestore.Timestamp | undefined;
    const hasActivePremium = isPremium && (!premiumExpiresAt || premiumExpiresAt.toMillis() > now);
    const limit = hasActivePremium ? CHAT_LIMIT_PREMIUM : CHAT_LIMIT_FREE;

    const doc = await db.collection('chat_limits').doc(uid).get();

    if (!doc.exists || (now - (doc.data()!.dayStart as number)) > DAY_WINDOW) {
        return { used: 0, limit, remaining: limit, isPremium: hasActivePremium, resetAt: new Date(now + DAY_WINDOW) };
    }

    const data = doc.data()!;
    const used = data.count as number;
    return {
        used,
        limit,
        remaining: Math.max(0, limit - used),
        isPremium: hasActivePremium,
        resetAt: new Date((data.dayStart as number) + DAY_WINDOW),
    };
}