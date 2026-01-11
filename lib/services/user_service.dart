import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firestore_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static UserService get instance => _instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreService _fs = FirestoreService.instance;

  /// ✅ Helper: safe write that creates doc if missing
  Future<void> _mergeUser(String uid, Map<String, dynamic> data) async {
    await _fs.userDoc(uid).set(data, SetOptions(merge: true));
  }

  /// ✅ Call this after register/login if you want to guarantee the doc exists
  Future<void> ensureUserDoc(String uid, {String? email}) async {
    await _mergeUser(uid, {
      if (email != null) 'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Update user profile information
  /// Only updates fields that are not null
  Future<void> updateMyProfile(
    String uid, {
    String? firstName,
    String? lastName,
    String? displayName,
    String? gender,
    String? phone,
    String? bio,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (displayName != null) data['displayName'] = displayName;
      if (gender != null) data['gender'] = gender;
      if (phone != null) data['phone'] = phone;
      if (bio != null) data['bio'] = bio;

      // Always update timestamp
      data['lastUpdated'] = FieldValue.serverTimestamp();

      if (data.isNotEmpty) {
        // ✅ was update() -> now set(merge:true)
        await _mergeUser(uid, data);
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Upload profile photo and update user document
  /// Returns the download URL of the uploaded image
  Future<String?> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child(
            'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();

      // ✅ was update() -> now set(merge:true)
      await _mergeUser(uid, {
        'photoUrl': url,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return url;
    } catch (e) {
      throw Exception('Failed to upload profile photo: ${e.toString()}');
    }
  }

  /// Update user's cover image
  Future<void> updateCoverImage(String uid, String coverUrl) async {
    try {
      // ✅ was update() -> now set(merge:true)
      await _mergeUser(uid, {
        'coverUrl': coverUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update cover image: ${e.toString()}');
    }
  }

  /// Get user data as a stream (real-time updates)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _fs.userDoc(uid).snapshots();
  }

  /// Get user data as a one-time fetch
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    try {
      return await _fs.userDoc(uid).get();
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Upload any file to user's storage and return URL
  Future<String> uploadFile({
    required String uid,
    required File file,
    required String folder, // e.g., 'avatars', 'covers', 'documents'
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      final ref = _storage.ref().child('$folder/$uid/$fileName');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Delete file from storage using its URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Update user's display name (for compatibility)
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await updateMyProfile(uid, displayName: displayName);
    } catch (e) {
      throw Exception('Failed to update display name: ${e.toString()}');
    }
  }
}
