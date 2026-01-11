import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

// Make sure you are importing the correct AppColors for THIS project
// If your file is habits_tracker/core/theme/app_colors.dart, use that.


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();

  bool _isBusy = false;
  bool _isCoverBusy = false;
  String? _photoUrl;
  String? _coverUrl;
  StreamSubscription? _userDataSubscription;

  // ✅ controls how much the avatar overlaps the cover
  static const double _avatarRadius = 60;
  static const double _avatarOverlap = 44; // was -50 translate; now handled by layout

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

  void _initUserStream() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _userDataSubscription =
          UserService.instance.getUserStream(user.uid).listen((doc) {
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
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _pickImage(bool isCover) async {
    if (isCover) {
      setState(() => _isCoverBusy = true);
    } else {
      setState(() => _isBusy = true);
    }

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
        final ref = FirebaseStorage.instance.ref().child('covers/${user.uid}.jpg');
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
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final profileImg = _photoUrl ?? user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),

          // ✅ This makes sure content never hides under system UI / app bar
          SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ✅ Reserve space for the overlap (no more negative translate)
                    const SizedBox(height: _avatarOverlap),

                    _buildAvatar(profileImg),
                    const SizedBox(height: 15),
                    _buildUserInfo(user?.email),
                    const SizedBox(height: 24),

                    _buildFormSection(),
                    const SizedBox(height: 20),
                    _buildActionSection(),

                    // ✅ Extra bottom padding so FAB never covers fields
                    const SizedBox(height: 120),
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text("Save Changes"),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    // ✅ Make room for the avatar overlap by adding bottom padding in the header
    final double coverHeight = 240; // was 200

    return SliverAppBar(
      expandedHeight: coverHeight,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_coverUrl != null)
              Image.network(_coverUrl!, fit: BoxFit.cover)
            else
              Container(color: AppColors.primary),

            Container(color: Colors.black26),

            // ✅ leave space at bottom so avatar can overlap cleanly
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(height: _avatarOverlap + _avatarRadius),
            ),

            Positioned(
              bottom: _avatarOverlap + 10,
              right: 10,
              child: IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: _isCoverBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                onPressed: _isCoverBusy ? null : () => _pickImage(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: _avatarRadius,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: _avatarRadius - 4,
              backgroundImage: url != null ? NetworkImage(url) : null,
              child: url == null ? const Icon(Icons.person, size: 50) : null,
            ),
          ),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: IconButton(
              icon: _isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.edit, size: 18, color: Colors.white),
              onPressed: _isBusy ? null : () => _pickImage(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String? email) {
    final fullName = "${_firstName.text} ${_lastName.text}".trim();
    return Column(
      children: [
        Text(
          fullName.isEmpty ? "Your Name" : fullName,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildTextField(_firstName, "First Name", Icons.person_outline),
          _buildTextField(_lastName, "Last Name", Icons.person_outline),
          _buildTextField(_phone, "Phone", Icons.phone_android, type: TextInputType.phone),
          _buildTextField(_bio, "Bio", Icons.notes, lines: 3),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.blue),
            title: const Text("Reset Password"),
            onTap: () {
              final email = AuthService.instance.currentUser?.email;
              if (email == null) return;
              AuthService.instance.sendPasswordReset(email);
              _showSnackBar("Reset email sent.");
            },
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
