// ═══════════════════════════════════════════════════════════════
// TO'LIQ FAYL — COPY-PASTE QILING
// PATH: lib/features/profile/data/datasources/profile_remote_datasource.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/profile/data/models/profile_model.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';

// ─── Interface ───────────────────────────────────────────────
abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String userId);

  Future<UserProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  );

  // ✅ YANGI: Notification uchun alohida method — Timestamp bug yo'q
  Future<UserProfileModel> updateNotificationSettings(
    String userId,
    UserNotificationSettings notifications,
  );

  Future<String> uploadAvatar(String userId, String filePath);
  Future<void> requestDataExport(String userId);
  Future<void> requestAccountDelete(String userId);
}

// ─── Implementation ───────────────────────────────────────────
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  ProfileRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  // ─── getProfile ───────────────────────────────────────────
  @override
  Future<UserProfileModel> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Profil topilmadi');
      }
      return UserProfileModel.fromFirestore(doc);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Profil yuklanmadi: $e');
    }
  }

  // ─── updateProfile ────────────────────────────────────────
  // ESLATMA: Bu methodda notifications yubormang!
  // Notifications uchun updateNotificationSettings ishlating.
  @override
  Future<UserProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      // ✅ server-side timestamp — mijoz soati bilan chalkashmasin
      fields['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(fields);
      return getProfile(userId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Profil yangilanmadi',
        code: e.code,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Profil yangilanmadi: $e');
    }
  }

  // ─── updateNotificationSettings ───────────────────────────
  // ✅ BUG FIX: Timestamp crash muammosi shu yerda hal qilindi.
  //
  // MUAMMO NIMA EDI:
  //   updateProfile() ichida fields['updatedAt'] = Timestamp.fromDate(now)
  //   qo'shilardi. Firestore.update() chaqirilganda ba'zan nested map
  //   sifatida yuborilardi:
  //     { notifications: {microSession: true}, updatedAt: Timestamp }
  //   Firestore SDK bu ikki fieldni birlashtirmay, ba'zan
  //   notifications field o'rniga Timestamp qaytarishi mumkin edi.
  //   Keyin fromFirestore() da:
  //     d['notifications'] as Map<String, dynamic>  ← CRASH!
  //
  // FIX:
  //   Dot notation bilan har bir fieldni alohida yangilash:
  //     'notifications.microSession': true
  //     'notifications.streak': true
  //   Bu Firestore'da faqat o'sha nested fieldni o'zgartiradi,
  //   boshqa fieldlarga tegmaydi.
  @override
  Future<UserProfileModel> updateNotificationSettings(
    String userId,
    UserNotificationSettings notifications,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        // ✅ Dot notation — notifications va updatedAt aralashmaydi
        'notifications.microSession': notifications.microSession,
        'notifications.streak': notifications.streak,
        'notifications.teacherContent': notifications.teacherContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return getProfile(userId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Bildirishnoma sozlamalari saqlanmadi',
        code: e.code,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Bildirishnoma sozlamalari saqlanmadi: $e',
      );
    }
  }

  // ─── uploadAvatar ─────────────────────────────────────────
  @override
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final ext = filePath.split('.').last;
      final ref = _storage.ref('avatars/$userId/${_uuid.v4()}.$ext');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return url;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Avatar yuklanmadi',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Avatar yuklanmadi: $e');
    }
  }

  // ─── requestDataExport ────────────────────────────────────
  @override
  Future<void> requestDataExport(String userId) async {
    try {
      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'type': 'export',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? "Export so'rov yuborilmadi",
        code: e.code,
      );
    }
  }

  // ─── requestAccountDelete ─────────────────────────────────
  @override
  Future<void> requestAccountDelete(String userId) async {
    try {
      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'type': 'delete',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? "O'chirish so'rov yuborilmadi",
        code: e.code,
      );
    }
  }
}
