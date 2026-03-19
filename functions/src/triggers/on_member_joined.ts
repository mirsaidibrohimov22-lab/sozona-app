// functions/src/triggers/on_member_joined.ts
// ✅ YANGI: Student sinfga qo'shilganda memberCount avtomatik yangilanadi
// Bu trigger student tomonidan classes update qila olmasligi muammosini hal qiladi

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onMemberJoined = functions
    .region('us-central1')
    .firestore
    .document('classes/{classId}/members/{memberId}')
    .onCreate(async (snap, context) => {
        const classId = context.params.classId;
        try {
            await admin.firestore()
                .collection('classes')
                .doc(classId)
                .update({
                    memberCount: admin.firestore.FieldValue.increment(1),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            console.log(`✅ memberCount +1: class ${classId}`);
        } catch (e) {
            console.error(`❌ memberCount update xatosi: ${e}`);
        }
    });

export const onMemberLeft = functions
    .region('us-central1')
    .firestore
    .document('classes/{classId}/members/{memberId}')
    .onDelete(async (snap, context) => {
        const classId = context.params.classId;
        try {
            await admin.firestore()
                .collection('classes')
                .doc(classId)
                .update({
                    memberCount: admin.firestore.FieldValue.increment(-1),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            console.log(`✅ memberCount -1: class ${classId}`);
        } catch (e) {
            console.error(`❌ memberCount update xatosi: ${e}`);
        }
    });