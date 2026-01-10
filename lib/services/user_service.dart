// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:habits_app/models/users.dart';

// import 'auth_service.dart';
// import 'firestore_service.dart';

// class UserService {
//   UserService._();
//   static final instance = UserService._();

//   final _auth = AuthService.instance;
//   final _fs = FirestoreService.instance;

//   String get uid {
//     final u = _auth.currentUser;
//     if (u == null) throw StateError('No user is logged in.');
//     return u.uid;
//   }

//   /// Stream the user profile as a Map (easy for UI)
//   Stream<Map<String, dynamic>?> watchProfile() => _fs.watchProfile(uid);

//   /// Stream the user profile typed
//   Stream<UserProfile?> watchTypedProfile() => _fs.watchTypedProfile(uid);

//   /// Ensure user profile exists (use after login/register)
//   Future<void> ensureProfile({
//     String? displayName,
//     String? email,
//     String? photoUrl,
//   }) async {
//     final u = _auth.currentUser;
//     if (u == null) throw StateError('No user is logged in.');

//     final ref = _fs.userDoc(u.uid);
//     final snap = await ref.get();

//     // If missing, create it
//     if (!snap.exists) {
//       await _fs.createUserProfile(
//         null,
//         uid: u.uid,
//         displayName: displayName ?? (u.displayName ?? 'User'),
//         email: email ?? (u.email ?? ''),
//         photoUrl: photoUrl ?? (u.photoURL),
//       );
//       return;
//     }

//     // If exists but missing key fields, patch them
//     final data = snap.data() ?? {};
//     final patch = <String, dynamic>{};

//     if ((data['displayName'] == null || (data['displayName'] as String).trim().isEmpty) &&
//         (displayName ?? u.displayName) != null) {
//       patch['displayName'] = displayName ?? u.displayName;
//     }

//     if ((data['email'] == null || (data['email'] as String).trim().isEmpty) &&
//         (email ?? u.email) != null) {
//       patch['email'] = email ?? u.email;
//     }

//     if (photoUrl != null && (data['photoUrl'] == null || (data['photoUrl'] as String).isEmpty)) {
//       patch['photoUrl'] = photoUrl;
//     }

//     if (patch.isNotEmpty) {
//       await ref.set(patch, SetOptions(merge: true));
//     }
//   }

//   /// Update display name in Firestore (and optionally auth displayName too)
//   Future<void> updateDisplayName(String name, {bool updateAuthToo = false}) async {
//     final clean = name.trim();
//     if (clean.isEmpty) throw ArgumentError('Name cannot be empty.');

//     await _fs.updateProfile(uid, {'displayName': clean});

//     if (updateAuthToo) {
//       await _auth.currentUser?.updateDisplayName(clean);
//     }
//   }

//   /// Update photo url in Firestore (you can set this after uploading avatar)
//   Future<void> updatePhotoUrl(String? photoUrl, {bool updateAuthToo = false}) async {
//     await _fs.updateProfile(uid, {'photoUrl': photoUrl});

//     if (updateAuthToo) {
//       await _auth.currentUser?.updatePhotoURL(photoUrl);
//     }
//   }

//   /// Quick fetch (one-time) profile map
//   Future<Map<String, dynamic>?> getProfileOnce() async {
//     final doc = await _fs.userDoc(uid).get();
//     return doc.data();
//   }
// }

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:habits_app/models/users.dart';
import 'package:habits_app/services/firestore_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static UserService get instance => _instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreService _fs = FirestoreService.instance;

  // Remove the direct Firestore instance since we'll use Fs service

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
      final fn = firstName?.trim() ?? '';
      final ln = lastName?.trim() ?? '';
      final dn = displayName?.trim() ?? '';
      final gn = gender?.trim() ?? '';
      final ph = phone?.trim() ?? '';
      final bioText = bio?.trim() ?? '';

      final data = <String, dynamic>{};
      if (fn.isNotEmpty) data['firstName'] = fn;
      if (ln.isNotEmpty) data['lastName'] = ln;
      if (dn.isNotEmpty) data['displayName'] = dn;
      if (gn.isNotEmpty) data['gender'] = gn;
      if (ph.isNotEmpty) data['phone'] = ph;
      if (bioText.isNotEmpty) data['bio'] = bioText;

      // If no explicit displayName provided, derive one from first/last.
      if (data['displayName'] == null) {
        final combined = '$fn $ln'.trim();
        if (combined.isNotEmpty) {
          data['displayName'] = combined;
        }
      }

      // Always update the lastUpdated timestamp
      data['lastUpdated'] = FieldValue.serverTimestamp();

      if (data.isNotEmpty) {
        // Use merge to avoid failures when the user doc does not yet exist.
        await _fs.userDoc(uid).set(data, SetOptions(merge: true));
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
      // Create a reference to the storage location
      final ref = _storage.ref().child(
        'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Upload the file
      final uploadTask = await ref.putFile(file);

      // Get the download URL
      final url = await uploadTask.ref.getDownloadURL();

      // Update the user document with the new photo URL
      await _fs.userDoc(uid).update({
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
      await _fs.userDoc(uid).update({
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
  /// Generic method for uploading any type of file
  Future<String> uploadFile({
    required String uid,
    required File file,
    required String folder, // e.g., 'avatars', 'covers', 'documents'
    String? customFileName,
  }) async {
    try {
      final fileName =
          customFileName ??
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
