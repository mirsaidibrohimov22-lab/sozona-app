// functions/src/triggers/on_data_request.ts
// So'zona — Ma'lumot export/delete so'rov triggeri
// ✅ FIX: db lazy initialization — initializeApp() dan keyin chaqiriladi

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// ✅ FIX: top-level da emas, funksiya ichida chaqiriladi
function db() {
    return admin.firestore();
}

export const onDataRequest = functions.firestore
    .document('dataRequests/{requestId}')
    .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        const data = snap.data();
        const { userId, type } = data as { userId: string; type: string };

        if (!userId || !type) {
            functions.logger.warn('onDataRequest: userId yoki type yo\'q', { data });
            return;
        }

        try {
            if (type === 'export') {
                await handleDataExport(userId, context.params.requestId as string);
            } else if (type === 'delete') {
                await handleAccountDelete(userId, context.params.requestId as string);
            }
        } catch (error) {
            functions.logger.error('onDataRequest xatoligi', { error, userId, type });
            await snap.ref.update({
                status: 'failed',
                error: String(error),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    });

async function handleDataExport(userId: string, requestId: string): Promise<void> {
    functions.logger.info('Ma\'lumot export boshlandi', { userId });

    const [userDoc, attempts, weakItems, sessions] = await Promise.all([
        db().collection('users').doc(userId).get(),
        db().collection('attempts').where('userId', '==', userId).get(),
        db().collection('users').doc(userId).collection('weakItems').get(),
        db().collection('microSessions').doc(userId).collection('sessions').get(),
    ]);

    const exportData = {
        profile: userDoc.data() ?? {},
        attempts: attempts.docs.map((d: admin.firestore.QueryDocumentSnapshot) => ({ id: d.id, ...d.data() })),
        weakItems: weakItems.docs.map((d: admin.firestore.QueryDocumentSnapshot) => ({ id: d.id, ...d.data() })),
        sessions: sessions.docs.map((d: admin.firestore.QueryDocumentSnapshot) => ({ id: d.id, ...d.data() })),
        exportedAt: new Date().toISOString(),
    };

    const bucket = admin.storage().bucket();
    const fileName = `exports/${userId}/data_export_${Date.now()}.json`;
    const file = bucket.file(fileName);

    await file.save(JSON.stringify(exportData, null, 2), {
        contentType: 'application/json',
        metadata: { userId, requestId },
    });

    const [downloadUrl] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
    });

    await db().collection('dataRequests').doc(requestId).update({
        status: 'completed',
        downloadUrl,
        expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info('Export yakunlandi', { userId, downloadUrl });
}

async function handleAccountDelete(userId: string, requestId: string): Promise<void> {
    functions.logger.info('Hisob o\'chirish boshlandi', { userId });

    const batch = db().batch();

    const weakItems = await db().collection('users').doc(userId).collection('weakItems').get();
    weakItems.docs.forEach((d: admin.firestore.QueryDocumentSnapshot) => batch.delete(d.ref));

    const sessions = await db().collection('microSessions').doc(userId).collection('sessions').get();
    sessions.docs.forEach((d: admin.firestore.QueryDocumentSnapshot) => batch.delete(d.ref));

    await batch.commit();
    await db().collection('users').doc(userId).delete();
    await admin.auth().deleteUser(userId);

    await db().collection('dataRequests').doc(requestId).update({
        status: 'completed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info('Hisob o\'chirildi', { userId });
}