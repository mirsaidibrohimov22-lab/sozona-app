// functions/src/middleware/auth_middleware.ts
// SO'ZONA — Auth Middleware

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

export async function verifyAuth(context: functions.https.CallableContext): Promise<string> {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Foydalanuvchi login qilmagan. Iltimos, tizimga kiring.'
        );
    }
    return context.auth.uid;
}

export async function getUserData(uid: string): Promise<Record<string, unknown>> {
    try {
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Foydalanuvchi topilmadi');
        }
        return userDoc.data() as Record<string, unknown>;
    } catch (error: unknown) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error('Error getting user data:', error);
        throw new functions.https.HttpsError('internal', 'Foydalanuvchi ma\'lumotlarini olishda xatolik');
    }
}

export async function checkRole(uid: string, requiredRole: 'student' | 'teacher'): Promise<void> {
    const userData = await getUserData(uid);
    if (userData.role !== requiredRole) {
        throw new functions.https.HttpsError(
            'permission-denied',
            `Bu funksiya faqat ${requiredRole} uchun`
        );
    }
}
