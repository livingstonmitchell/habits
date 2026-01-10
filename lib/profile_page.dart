// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:habits_app/auth/login_screen.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../services/auth_service.dart';
// import '../services/user_service.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   Future<void> _onLogout(BuildContext context) async {
//     try {
//       //Confirm first
//       final safeToLogout = await showDialog(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: Text('Logout'),
//           content: Text('Are you sure you want to log out?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () => Navigator.pop(ctx, true),
//               child: Text('Yes'),
//             ),
//           ],
//         ),
//       );

//       // Check if widget is still mounted after dialog
//       if (!mounted || safeToLogout != true) return;

//       // Show loading indicator
//       if (mounted) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => const AlertDialog(
//             content: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 16),
//                 Text('Logging out...'),
//               ],
//             ),
//           ),
//         );
//       }

//       await AuthService.instance.signOut();

//       // Pop loading dialog if still mounted
//       if (mounted && Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }

//       // Navigate to login screen after logout
//       if (mounted) {
//         Navigator.of(
//           context,
//         ).pushNamedAndRemoveUntil('/login', (route) => false);
//       }
//     } catch (e) {
//       // Pop loading dialog if it exists and widget is still mounted
//       if (mounted && Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }

//       if (mounted) {
//         _showSnackBar(context, 'Error logging out: $e');
//       }
//     }
//   }

//   // Helper method to show snack bars
//   void _showSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   // Alias for compatibility with existing code
//   void displaySnackBar(BuildContext context, String message) {
//     _showSnackBar(context, message);
//   }

//   //Update Profile
//   Future<void> _updateProfile() async {
//     setState(() => _busy = true);
//     try {
//       final user = AuthService.instance.currentUser;
//       if (user == null) return; // User logged out during operation

//       await UserService.instance.updateMyProfile(
//         user.uid,
//         firstName: _firstName.text.trim(),
//         lastName: _lastName.text.trim(),
//         phone: _phone.text.trim(),
//         bio: _bio.text.trim(),
//       );
//       if (mounted) {
//         displaySnackBar(context, 'Profile updated!');
//       }
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   //Upload/Select image
//   Future<void> _onPickPhoto() async {
//     setState(() => _busy = true);
//     try {
//       // Request appropriate permissions
//       // Try photos first (iOS and Android 13+), then storage (older Android)
//       bool hasPermission = false;

//       if (Platform.isIOS) {
//         final status = await Permission.photos.request();
//         hasPermission = status.isGranted;
//       } else if (Platform.isAndroid) {
//         // Try photos permission first (Android 13+)
//         var status = await Permission.photos.request();
//         if (status.isGranted) {
//           hasPermission = true;
//         } else {
//           // Fall back to storage permission (older Android)
//           status = await Permission.storage.request();
//           hasPermission = status.isGranted;
//         }
//       } else {
//         // Other platforms - proceed without explicit permission check
//         hasPermission = true;
//       }

//       if (!hasPermission) {
//         if (mounted) {
//           displaySnackBar(
//             context,
//             'Photo permission is required to select images',
//           );
//         }
//         setState(() => _busy = false);
//         return;
//       }

//       final picker = ImagePicker();
//       final file = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//         maxWidth: 800,
//         maxHeight: 800,
//       );

//       if (file == null) {
//         setState(() => _busy = false);
//         return;
//       }

//       // Upload image directly without cropping
//       await _uploadProfileImage(File(file.path));
//     } catch (e) {
//       if (mounted) {
//         displaySnackBar(context, 'Error picking image: $e');
//       }
//       setState(() => _busy = false);
//     }
//   }

//   Future<void> _uploadProfileImage(File imageFile) async {
//     try {
//       final user = AuthService.instance.currentUser;
//       if (user == null) return; // User logged out during operation

//       await UserService.instance.uploadProfilePhoto(
//         uid: user.uid,
//         file: imageFile,
//       );

//       if (mounted) {
//         displaySnackBar(context, 'Profile photo updated!');
//       }
//     } catch (e) {
//       if (mounted) {
//         displaySnackBar(context, 'Error updating photo: $e');
//       }
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   // Cover image upload functionality
//   Future<void> _onPickCoverImage() async {
//     setState(() => _coverBusy = true);
//     try {
//       // Request appropriate permissions
//       // Try photos first (iOS and Android 13+), then storage (older Android)
//       bool hasPermission = false;

//       if (Platform.isIOS) {
//         final status = await Permission.photos.request();
//         hasPermission = status.isGranted;
//       } else if (Platform.isAndroid) {
//         // Try photos permission first (Android 13+)
//         var status = await Permission.photos.request();
//         if (status.isGranted) {
//           hasPermission = true;
//         } else {
//           // Fall back to storage permission (older Android)
//           status = await Permission.storage.request();
//           hasPermission = status.isGranted;
//         }
//       } else {
//         // Other platforms - proceed without explicit permission check
//         hasPermission = true;
//       }

//       if (!hasPermission) {
//         if (mounted) {
//           displaySnackBar(
//             context,
//             'Photo permission is required to select images',
//           );
//         }
//         setState(() => _coverBusy = false);
//         return;
//       }

//       final picker = ImagePicker();
//       final file = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//         maxWidth: 1200,
//         maxHeight: 800,
//       );

//       if (file == null) {
//         setState(() => _coverBusy = false);
//         return;
//       }

//       // Upload cover image without cropping (landscape format)
//       final user = AuthService.instance.currentUser;
//       if (user == null) {
//         setState(() => _coverBusy = false);
//         return; // User logged out during operation
//       }

//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('covers')
//           .child('${user.uid}.jpg');

//       final uploadTask = storageRef.putFile(File(file.path));
//       final snapshot = await uploadTask;
//       final downloadUrl = await snapshot.ref.getDownloadURL();

//       // Update Firestore with cover URL
//       await UserService.instance.updateCoverImage(user.uid, downloadUrl);

//       if (mounted) {
//         displaySnackBar(context, 'Cover image updated!');
//       }
//     } catch (e) {
//       if (mounted) {
//         displaySnackBar(context, 'Error updating cover image: $e');
//       }
//     } finally {
//       if (mounted) setState(() => _coverBusy = false);
//     }
//   }

//   final _bio = TextEditingController();
//   final _phone = TextEditingController();
//   final _firstName = TextEditingController();
//   final _lastName = TextEditingController();

//   String? _photoUrl;
//   String? _coverUrl; // Add cover image URL
//   bool _busy = false;
//   bool _coverBusy = false; // Separate loading state for cover image

//   // Stream subscription for cleanup
//   StreamSubscription? _userDataSubscription;

//   // Helper method to get the profile image URL with fallback logic
//   String? get _profileImageUrl {
//     final user = AuthService.instance.currentUser;
//     // Priority: custom uploaded photo -> Google photo -> null (shows placeholder)
//     return _photoUrl ?? user?.photoURL;
//   }

//   @override
//   void initState() {
//     super.initState();
//     final user = AuthService.instance.currentUser;
//     if (user != null) {
//       _userDataSubscription = UserService.instance
//           .getUserStream(user.uid)
//           .listen(
//             (doc) {
//               final data = doc.data();
//               if (data != null && mounted) {
//                 _firstName.text = (data['firstName'] ?? '') as String;
//                 _lastName.text = (data['lastName'] ?? '') as String;
//                 _bio.text = (data['bio'] ?? '') as String;
//                 _phone.text = (data['phone'] ?? '') as String;
//                 setState(() {
//                   _photoUrl = data['photoUrl'] as String?;
//                   _coverUrl =
//                       data['coverUrl'] as String?; // Listen for cover URL
//                 });
//               }
//             },
//             onError: (error) {
//               // Handle permission errors during logout gracefully
//               if (error.toString().contains('permission-denied')) {
//                 // User logged out, stop listening
//                 return;
//               }
//             },
//           );
//     }
//   }

//   @override
//   void dispose() {
//     _userDataSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = AuthService.instance.currentUser;

//     // If user is null, redirect to login
//     if (user == null) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 12),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (_) => const LoginScreen()),
//                 ),
//                 child: const Text('Sign in again'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // Collapsible cover image with SliverAppBar
//           SliverAppBar(
//             backgroundColor: Color(0xFF2C3E50),
//             foregroundColor: Colors.white,
//             expandedHeight: 250.0,
//             floating: false,
//             pinned: true,
//             actions: [
//               IconButton(
//                 onPressed: () async {
//                   try {
//                     await _onLogout(context);
//                   } catch (e) {
//                     // Handle any errors silently for the app bar button
//                   }
//                 },
//                 icon: Icon(Icons.logout),
//               ),
//             ],
//             flexibleSpace: FlexibleSpaceBar(
//               title: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text('My Profile'),
//               ),
//               background: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Cover image or placeholder
//                   _coverUrl != null
//                       ? Image.network(
//                           _coverUrl!,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return _buildCoverPlaceholder();
//                           },
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Container(
//                               color: Colors.grey.shade200,
//                               child: Center(
//                                 child: CircularProgressIndicator(
//                                   value:
//                                       loadingProgress.expectedTotalBytes != null
//                                       ? loadingProgress.cumulativeBytesLoaded /
//                                             loadingProgress.expectedTotalBytes!
//                                       : null,
//                                 ),
//                               ),
//                             );
//                           },
//                         )
//                       : _buildCoverPlaceholder(),
//                   // Gradient overlay for better text readability
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Color(0xFF2C3E50).withOpacity(0.3),
//                           Colors.black.withOpacity(0.5),
//                         ],
//                       ),
//                     ),
//                   ),
//                   // Change cover button for current user
//                   Positioned(
//                     bottom: 16,
//                     right: 16,
//                     child: FloatingActionButton(
//                       heroTag: "profile_cover_fab",
//                       mini: true,
//                       backgroundColor: Color(0xFF3498DB),
//                       foregroundColor: Colors.white,
//                       onPressed: _coverBusy ? null : _onPickCoverImage,
//                       child: _coverBusy
//                           ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                           : Icon(Icons.camera_alt, size: 20),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Profile content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // User notifications for flags/suspensions
//                   const SizedBox(height: 16),
//                   // Profile image section
//                   Center(
//                     child: SizedBox(
//                       width: 160,
//                       height: 160,
//                       child: AspectRatio(
//                         aspectRatio: 1.0,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: Theme.of(context).primaryColor,
//                               width: 2,
//                             ),
//                           ),
//                           child: ClipOval(
//                             child: _busy
//                                 ? Container(
//                                     color: Colors.grey.shade200,
//                                     child: const Center(
//                                       child: CircularProgressIndicator(),
//                                     ),
//                                   )
//                                 : _profileImageUrl != null
//                                 ? Image.network(
//                                     _profileImageUrl!,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Container(
//                                         color: Colors.grey.shade200,
//                                         child: const Icon(
//                                           Icons.person,
//                                           size: 60,
//                                           color: Colors.grey,
//                                         ),
//                                       );
//                                     },
//                                     loadingBuilder: (context, child, loadingProgress) {
//                                       if (loadingProgress == null) return child;
//                                       return Container(
//                                         color: Colors.grey.shade200,
//                                         child: Center(
//                                           child: CircularProgressIndicator(
//                                             value:
//                                                 loadingProgress
//                                                         .expectedTotalBytes !=
//                                                     null
//                                                 ? loadingProgress
//                                                           .cumulativeBytesLoaded /
//                                                       loadingProgress
//                                                           .expectedTotalBytes!
//                                                 : null,
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   )
//                                 : Container(
//                                     color: Colors.grey.shade200,
//                                     child: const Icon(
//                                       Icons.person,
//                                       size: 60,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Center(
//                     child: Column(
//                       children: [
//                         TextButton.icon(
//                           icon: const Icon(Icons.camera_alt),
//                           onPressed: _busy ? null : _onPickPhoto,
//                           label: Text(
//                             _busy
//                                 ? 'Uploading...'
//                                 : _photoUrl != null
//                                 ? 'Change Profile Image'
//                                 : AuthService.instance.currentUser?.photoURL !=
//                                       null
//                                 ? 'Upload Custom Image'
//                                 : 'Add Profile Image',
//                           ),
//                         ),
//                         // Show source indicator when using Google photo
//                         if (_photoUrl == null &&
//                             AuthService.instance.currentUser?.photoURL != null)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 4),
//                             child: Text(
//                               '',
//                               style: Theme.of(context).textTheme.bodySmall
//                                   ?.copyWith(
//                                     color: Colors.grey[600],
//                                     fontSize: 12,
//                                   ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   // User info section
//                   Text('Name: ${_firstName.text} ${_lastName.text}'),
//                   const SizedBox(height: 8),
//                   Text('Email: ${user.email}'),
//                   const SizedBox(height: 24),
//                   // Editable fields
//                   TextField(
//                     controller: _firstName,
//                     decoration: const InputDecoration(
//                       labelText: 'First Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _lastName,
//                     decoration: const InputDecoration(
//                       labelText: 'Last Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _phone,
//                     decoration: const InputDecoration(
//                       labelText: 'Phone #',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _bio,
//                     maxLength: 100,
//                     decoration: const InputDecoration(
//                       labelText: 'Bio',
//                       hintText: 'Tell us about yourself...',
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 3,
//                     keyboardType: TextInputType.multiline,
//                   ),
//                   const SizedBox(height: 24),
//                   // Action buttons
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _busy ? null : _updateProfile,
//                       child: _busy
//                           ? const CircularProgressIndicator()
//                           : const Text('Save Profile'),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () async {
//                         await AuthService.instance.sendPasswordReset(
//                           user.email!,
//                         );
//                         if (mounted) {
//                           displaySnackBar(
//                             context,
//                             'Password reset email sent!',
//                           );
//                         }
//                       },
//                       child: const Text('Send Password Reset Email'),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: TextButton(
//                       onPressed: () => _onLogout(context),
//                       child: const Text('Logout'),
//                     ),
//                   ),

//                   const SizedBox(height: 24), // Extra bottom padding
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCoverPlaceholder() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Theme.of(context).primaryColor.withOpacity(0.8),
//             Theme.of(context).primaryColor.withOpacity(0.4),
//           ],
//         ),
//       ),
//       child: Center(
//         child: Icon(
//           Icons.landscape,
//           size: 60,
//           color: Colors.white.withOpacity(0.7),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:habits_app/utils/theme.dart';

// Ensure these imports match your project structure exactly
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 1. CONTROLLERS
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();

  // 2. STATE VARIABLES
  bool _isBusy = false;
  bool _isCoverBusy = false;
  String? _photoUrl;
  String? _coverUrl;
  StreamSubscription? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _initUserStream();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  // 3. LOGIC METHODS
  void _initUserStream() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _userDataSubscription = UserService.instance
          .getUserStream(user.uid)
          .listen((doc) {
            final data = doc.data();
            if (data != null && mounted) {
              setState(() {
                _firstName.text = data['firstName'] ?? '';
                _lastName.text = data['lastName'] ?? '';
                _bio.text = data['bio'] ?? '';
                _phone.text = data['phone'] ?? '';
                _photoUrl = data['photoUrl'];
                _coverUrl = data['coverUrl'];
              });
            }
          });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isBusy = true);
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      await UserService.instance.updateMyProfile(
        user.uid,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
      );
      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _pickImage(bool isCover) async {
    if (isCover)
      setState(() => _isCoverBusy = true);
    else
      setState(() => _isBusy = true);

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;

      final user = AuthService.instance.currentUser;
      if (user == null) return;

      if (isCover) {
        final ref = FirebaseStorage.instance.ref().child(
          'covers/${user.uid}.jpg',
        );
        await ref.putFile(File(file.path));
        final url = await ref.getDownloadURL();
        await UserService.instance.updateCoverImage(user.uid, url);
      } else {
        await UserService.instance.uploadProfilePhoto(
          uid: user.uid,
          file: File(file.path),
        );
      }
      _showSnackBar('Image updated!');
    } catch (e) {
      _showSnackBar('Upload failed: $e');
    } finally {
      if (mounted)
        setState(() {
          _isBusy = false;
          _isCoverBusy = false;
        });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // 4. BUILD METHOD
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final profileImg = _photoUrl ?? user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildAvatar(profileImg),
                    const SizedBox(height: 15),
                    _buildUserInfo(user?.email),
                    const SizedBox(height: 30),
                    _buildFormSection(),
                    const SizedBox(height: 20),
                    _buildActionSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'profile-fab',
        onPressed: _isBusy ? null : _handleSave,
        label: _isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text("Save Changes"),
        icon: const Icon(Icons.save),
      ),
    );
  }

  // 5. UI HELPER WIDGETS
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_coverUrl != null)
              Image.network(_coverUrl!, fit: BoxFit.cover)
            else
              Container(color: AppColors.primary),
            Container(color: Colors.black26),
            Positioned(
              bottom: 60,
              right: 10,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                onPressed: () => _pickImage(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 56,
            backgroundImage: url != null ? NetworkImage(url) : null,
            child: url == null ? const Icon(Icons.person, size: 50) : null,
          ),
        ),
        CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 18,
          child: IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
            onPressed: () => _pickImage(false),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(String? email) {
    return Column(
      children: [
        Text(
          "${_firstName.text} ${_lastName.text}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(email ?? '', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(_firstName, "First Name", Icons.person_outline),
          _buildTextField(_lastName, "Last Name", Icons.person_outline),
          _buildTextField(
            _phone,
            "Phone",
            Icons.phone_android,
            type: TextInputType.phone,
          ),
          _buildTextField(_bio, "Bio", Icons.notes, lines: 3),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.blue),
            title: const Text("Reset Password"),
            onTap: () => AuthService.instance.sendPasswordReset(
              AuthService.instance.currentUser!.email!,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int lines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}
