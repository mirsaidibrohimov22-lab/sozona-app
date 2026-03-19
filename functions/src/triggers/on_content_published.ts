// functions/src/triggers/on_content_published.ts
// On Content Published Trigger — Kontent nashr bo'lganda notification yuborish

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onContentPublished = functions.firestore
    .document('content/{contentId}')
    .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        const contentData = snap.data();
        const contentId = context.params.contentId as string;

        if (!contentData.isPublished) {
            console.log('Content not published yet, skipping notification');
            return null;
        }

        const {
            type,
            title,
            classId,
            creatorName,
        } = contentData as {
            type: string;
            title: string;
            classId: string;
            creatorName: string;
            language: string;
            level: string;
        };

        try {
            const membersSnapshot = await admin
                .firestore()
                .collection(`classes/${classId}/members`)
                .get();

            if (membersSnapshot.empty) {
                console.log('No members in class, skipping notification');
                return null;
            }

            const batch = admin.firestore().batch();
            const notificationPromises: Promise<void>[] = [];

            membersSnapshot.forEach((memberDoc: admin.firestore.QueryDocumentSnapshot) => {
                const memberId = memberDoc.id;

                const notificationRef = admin.firestore().collection('notifications').doc();

                batch.set(notificationRef, {
                    id: notificationRef.id,
                    userId: memberId,
                    type: 'teacher_content',
                    title: getNotificationTitle(type),
                    body: getNotificationBody(title, creatorName, type),
                    data: {
                        contentId,
                        classId,
                        actionRoute: `/student/content/${contentId}`,
                    },
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    readAt: null,
                });

                notificationPromises.push(
                    sendPushNotification(
                        memberId,
                        getNotificationTitle(type),
                        getNotificationBody(title, creatorName, type),
                        { contentId, classId, type: 'teacher_content' }
                    )
                );
            });

            await batch.commit();
            await Promise.allSettled(notificationPromises);

            console.log(`Sent notifications to ${membersSnapshot.size} students for content: ${contentId}`);
            return null;
        } catch (error) {
            console.error('Error sending notifications:', error);
            return null;
        }
    });

function getNotificationTitle(contentType: string): string {
    const titles: Record<string, string> = {
        quiz: '📝 Yangi Quiz!',
        flashcard_set: '🃏 Yangi Flashcard to\'plami!',
        listening: '🎧 Yangi Listening mashqi!',
    };
    return titles[contentType] ?? '📚 Yangi mashq!';
}

function getNotificationBody(title: string, creatorName: string, contentType: string): string {
    const typeNames: Record<string, string> = {
        quiz: 'quiz',
        flashcard_set: 'flashcard to\'plami',
        listening: 'listening mashqi',
    };
    const typeName = typeNames[contentType] ?? 'mashq';
    return `${creatorName} sizga "${title}" ${typeName}ni yubordi. Mashq qiling!`;
}

async function sendPushNotification(
    userId: string,
    title: string,
    body: string,
    data: Record<string, string>
): Promise<void> {
    try {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.exists) return;

        const fcmToken = userDoc.data()?.fcmToken as string | undefined;
        if (!fcmToken) return;

        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: { title, body },
            data,
            android: {
                priority: 'high',
                notification: { sound: 'default', channelId: 'teacher_content' },
            },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        };

        await admin.messaging().send(message);
        console.log(`Push notification sent to user ${userId}`);
    } catch (error) {
        console.error(`Error sending push notification to user ${userId}:`, error);
    }
}

export const publishScheduledContent = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async (_context: unknown) => {
        const now = admin.firestore.Timestamp.now();

        try {
            const scheduledContents = await admin
                .firestore()
                .collection('content')
                .where('isPublished', '==', false)
                .where('scheduledAt', '<=', now)
                .get();

            if (scheduledContents.empty) {
                console.log('No scheduled content to publish');
                return null;
            }

            const batch = admin.firestore().batch();
            scheduledContents.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
                batch.update(doc.ref, {
                    isPublished: true,
                    publishedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            await batch.commit();
            console.log(`Published ${scheduledContents.size} scheduled content(s)`);
            return null;
        } catch (error) {
            console.error('Error publishing scheduled content:', error);
            return null;
        }
    });
