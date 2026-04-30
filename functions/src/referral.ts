// functions/src/referral.ts
// So'zona — Referral tizimi Cloud Functions
//
// LOGIKA:
//   1. generateReferralCode — SZ-XXXX-XXXX unikal kod yaratish
//   2. getReferralStats     — kod, usedCount, pendingCount, rewardedCount
//   3. redeemReferralCode   — kodni qo'llash (mukofot YO'Q — kutish boshlanadi)
//   4. processReferralRewards (scheduled, har kuni 02:00) —
//      Do'st 7 kun faol bo'lsa → KEYIN ikkalasiga 3 kun premium beriladi
//
// MUKOFOT BERILISH SHARTI:
//   - Do'st kodni kiritgan (redeemedAt saqlangan)
//   - Kamida 7 kalendar kun o'tgan
//   - Do'stning progress/{uid}.lastActiveDate redeemedAt dan KEYIN bo'lgan
//     (ya'ni hech bo'lmasa bir marta ilova ishlatgan)
//   - rewardGiven: false (qayta berilmasin)
//
// MUHIM: admin.initializeApp() index.ts da — bu faylda chaqirilmaydi

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// ─────────────────────────────────────────────────────────────
// Yordamchi: SZ-XXXX-XXXX formatida kod yaratish
// Chalkash belgilar yo'q: I, O, 0, 1
// ─────────────────────────────────────────────────────────────
function _generateCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const part = (len: number): string =>
        Array.from({ length: len }, () =>
            chars[Math.floor(Math.random() * chars.length)]
        ).join('');
    return `SZ-${part(4)}-${part(4)}`;
}

// ─────────────────────────────────────────────────────────────
// Yordamchi: 3 kunlik premium berish
// Faqat processReferralRewards tomonidan chaqiriladi
// ─────────────────────────────────────────────────────────────
async function _grant3DayPremium(uid: string): Promise<void> {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
        console.warn(`⚠️ _grant3DayPremium: user ${uid} topilmadi`);
        return;
    }

    const data = userSnap.data()!;
    const now = admin.firestore.Timestamp.now();
    const existing = data['premiumExpiresAt'] as admin.firestore.Timestamp | undefined;

    // Mavjud premium muddatiga ustiga 3 kun qo'shamiz
    let newExpiry: admin.firestore.Timestamp;
    if (existing && existing.toMillis() > now.toMillis()) {
        const cur = existing.toDate();
        cur.setDate(cur.getDate() + 3);
        newExpiry = admin.firestore.Timestamp.fromDate(cur);
    } else {
        const future = new Date();
        future.setDate(future.getDate() + 3);
        newExpiry = admin.firestore.Timestamp.fromDate(future);
    }

    await userRef.update({
        isPremium: true,
        premiumExpiresAt: newExpiry,
        premiumSource: 'referral_reward',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Bildirishnoma yuborish
    await db.collection('notifications').add({
        userId: uid,
        type: 'premium_activated',
        title: '🎁 Referral mukofoti keldi!',
        body: "Do'stingiz 1 hafta davomida So'zona ishlatdi — siz 3 kun bepul premium oldingiz!",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ 3 kunlik premium berildi: ${uid} → ${newExpiry.toDate().toISOString()}`);
}

// ─────────────────────────────────────────────────────────────
// 1. generateReferralCode
//    Har foydalanuvchiga FAQAT BIR MARTA kod beriladi.
// ─────────────────────────────────────────────────────────────
export const generateReferralCode = functions
    .region('us-central1')
    .https.onCall(async (
        _data: Record<string, unknown>,
        ctx: functions.https.CallableContext
    ) => {
        if (!ctx.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Tizimga kiring.');
        }
        const uid = ctx.auth.uid;
        const db = admin.firestore();

        const userSnap = await db.collection('users').doc(uid).get();
        if (!userSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Foydalanuvchi topilmadi.');
        }

        // Kod allaqachon bormi?
        const existing = userSnap.data()?.referralCode as string | undefined;
        if (existing) return { code: existing };

        // Unikal kod topilgunga qadar urinish
        let code = _generateCode();
        for (let i = 0; i < 10; i++) {
            const snap = await db.collection('referral_codes').doc(code).get();
            if (!snap.exists) break;
            code = _generateCode();
        }

        const now = admin.firestore.Timestamp.now();

        await db.collection('referral_codes').doc(code).set({
            ownerUid: uid,
            code,
            createdAt: now,
            usedCount: 0,     // jami qo'llaganlar
            pendingCount: 0,  // 7 kun kutilmoqda
            rewardedCount: 0, // mukofot berilganlar
            maxUses: 100,
        });

        await db.collection('users').doc(uid).update({
            referralCode: code,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Yangi referral kod: ${uid} → ${code}`);
        return { code };
    });

// ─────────────────────────────────────────────────────────────
// 2. getReferralStats
//    Statistika: code, usedCount, pendingCount, rewardedCount
// ─────────────────────────────────────────────────────────────
export const getReferralStats = functions
    .region('us-central1')
    .https.onCall(async (
        _data: Record<string, unknown>,
        ctx: functions.https.CallableContext
    ) => {
        if (!ctx.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Tizimga kiring.');
        }
        const uid = ctx.auth.uid;
        const db = admin.firestore();

        const userSnap = await db.collection('users').doc(uid).get();
        if (!userSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Foydalanuvchi topilmadi.');
        }

        const userData = userSnap.data()!;
        const referralCode = userData['referralCode'] as string | undefined;
        const hasRedeemed = !!(userData['redeemedReferralCode'] as string | undefined);

        if (!referralCode) {
            return {
                code: null,
                usedCount: 0,
                pendingCount: 0,
                rewardedCount: 0,
                deepLink: null,
                hasRedeemed,
            };
        }

        const codeSnap = await db.collection('referral_codes').doc(referralCode).get();
        const codeData = codeSnap.data() ?? {};

        const deepLink = `sozona://referral?code=${referralCode}`;

        return {
            code: referralCode,
            usedCount: (codeData['usedCount'] as number) ?? 0,
            pendingCount: (codeData['pendingCount'] as number) ?? 0,
            rewardedCount: (codeData['rewardedCount'] as number) ?? 0,
            deepLink,
            hasRedeemed,
        };
    });

// ─────────────────────────────────────────────────────────────
// 3. redeemReferralCode
//    Do'st kodni kiritadi — MUKOFOT YO'Q (7 kun kutiladi)
//    Faqat redemption yoziladi. Mukofot processReferralRewards beradi.
// ─────────────────────────────────────────────────────────────
export const redeemReferralCode = functions
    .region('us-central1')
    .https.onCall(async (
        data: Record<string, unknown>,
        ctx: functions.https.CallableContext
    ) => {
        if (!ctx.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Tizimga kiring.');
        }
        const uid = ctx.auth.uid;
        const code = ((data['code'] as string) ?? '').trim().toUpperCase();

        if (!code || !/^SZ-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(code)) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                "Kod formati noto'g'ri. Namuna: SZ-ABCD-1234"
            );
        }

        const db = admin.firestore();
        const userRef = db.collection('users').doc(uid);
        const codeRef = db.collection('referral_codes').doc(code);

        // Tranzaksiya — poyga sharoitidan himoya
        await db.runTransaction(async (tx) => {
            const [userSnap, codeSnap] = await Promise.all([
                tx.get(userRef),
                tx.get(codeRef),
            ]);

            if (!userSnap.exists) {
                throw new functions.https.HttpsError('not-found', 'Foydalanuvchi topilmadi.');
            }
            if (!codeSnap.exists) {
                throw new functions.https.HttpsError('not-found', 'Bunday kod mavjud emas.');
            }

            const userData = userSnap.data()!;
            const codeData = codeSnap.data()!;

            if (codeData['ownerUid'] === uid) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    "O'z kodingizni qo'llab bo'lmaydi."
                );
            }
            if (userData['redeemedReferralCode']) {
                throw new functions.https.HttpsError(
                    'already-exists',
                    "Siz allaqachon referral kodi qo'llagansiz."
                );
            }
            if ((codeData['usedCount'] as number ?? 0) >= (codeData['maxUses'] as number ?? 100)) {
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    "Bu kod o'z limitiga yetdi."
                );
            }

            const now = admin.firestore.Timestamp.now();

            // Foydalanuvchiga kod yozamiz
            tx.update(userRef, {
                redeemedReferralCode: code,
                redeemedReferralAt: now,
            });

            // Kod statistikasini yangilash
            tx.update(codeRef, {
                usedCount: admin.firestore.FieldValue.increment(1),
                pendingCount: admin.firestore.FieldValue.increment(1),
                lastUsedAt: now,
            });

            // uses subcollectionga yozamiz — processReferralRewards shu yerdan o'qiydi
            tx.set(codeRef.collection('uses').doc(uid), {
                friendUid: uid,
                ownerUid: codeData['ownerUid'],
                redeemedAt: now,
                rewardGiven: false,       // false → 7 kun o'tgach true bo'ladi
                rewardCheckAfter: new Date(now.toMillis() + 7 * 24 * 60 * 60 * 1000), // +7 kun
            });
        });

        console.log(`✅ Referral kod qo'llandi (kutish boshlandi): ${uid} → ${code}`);
        return {
            success: true,
            message:
                "Kod qabul qilindi! 1 hafta davomida So'zona ishlating — " +
                "keyin ikkalangiz 3 kun bepul premium olasiz! 🎁",
        };
    });

// ─────────────────────────────────────────────────────────────
// 4. processReferralRewards (har kuni soat 02:00 Toshkent)
//    Shartlar:
//      a) rewardGiven: false
//      b) redeemedAt dan 7+ kun o'tgan
//      c) do'stning lastActiveDate redeemedAt dan KEYIN — faol bo'lgan
//    Bajarilsa → ikkalasiga 3 kun premium + rewardGiven: true
// ─────────────────────────────────────────────────────────────
export const processReferralRewards = functions
    .region('us-central1')
    .pubsub.schedule('0 2 * * *')
    .timeZone('Asia/Tashkent')
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();
        const sevenDaysAgoMs = now.getTime() - 7 * 24 * 60 * 60 * 1000;

        // Barcha referral kodlarini olish
        const codesSnap = await db.collection('referral_codes').get();
        if (codesSnap.empty) {
            console.log('Referral kod topilmadi');
            return;
        }

        let rewardedCount = 0;

        for (const codeDoc of codesSnap.docs) {
            // Bu kod uchun kutayotgan redemptionlar
            const usesSnap = await codeDoc.ref
                .collection('uses')
                .where('rewardGiven', '==', false)
                .get();

            if (usesSnap.empty) continue;

            for (const useDoc of usesSnap.docs) {
                const useData = useDoc.data();
                const redeemedAt = useData['redeemedAt'] as admin.firestore.Timestamp;
                const friendUid = useData['friendUid'] as string;
                const ownerUid = useData['ownerUid'] as string;

                if (!redeemedAt || !friendUid || !ownerUid) continue;

                // Shart (b): 7 kun o'tdimi?
                if (redeemedAt.toMillis() > sevenDaysAgoMs) continue;

                // Shart (c): do'st redeemedAt dan KEYIN faol bo'lganmi?
                const progressSnap = await db.collection('progress').doc(friendUid).get();
                if (!progressSnap.exists) continue;

                const progressData = progressSnap.data()!;
                const lastActive = progressData['lastActiveDate'] as admin.firestore.Timestamp | undefined;

                if (!lastActive) continue;

                // lastActiveDate > redeemedAt — ilovani ishlatganligining isboti
                if (lastActive.toMillis() <= redeemedAt.toMillis()) {
                    console.log(`⏳ Do'st ${friendUid} hali faol bo'lmagan — o'tkazildi`);
                    continue;
                }

                // ✅ Barcha shartlar bajarildi — mukofot berish
                try {
                    await Promise.all([
                        _grant3DayPremium(friendUid),  // do'st
                        _grant3DayPremium(ownerUid),   // kod egasi
                    ]);

                    // Natijani yozish
                    await useDoc.ref.update({
                        rewardGiven: true,
                        rewardedAt: admin.firestore.Timestamp.now(),
                    });

                    // Kod statistikasini yangilash
                    await codeDoc.ref.update({
                        pendingCount: admin.firestore.FieldValue.increment(-1),
                        rewardedCount: admin.firestore.FieldValue.increment(1),
                    });

                    rewardedCount++;
                    console.log(`✅ Referral mukofot berildi: do'st=${friendUid}, egasi=${ownerUid}`);
                } catch (e) {
                    console.error(`⚠️ Mukofot berishda xato (${friendUid}):`, e);
                }
            }
        }

        console.log(`✅ processReferralRewards: ${rewardedCount} ta juft mukofot oldi`);
    });