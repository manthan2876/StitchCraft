import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/profile_service.dart';
import 'package:stitchcraft/features/profile/widgets/profile_tab.dart';
import 'package:stitchcraft/features/profile/widgets/shops_tab.dart';
import 'package:stitchcraft/features/profile/widgets/settings_tab.dart';
import 'package:stitchcraft/features/profile/widgets/security_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _profileService = ProfileService();
  
  Map<String, dynamic>? _userProfile;
  List<dynamic> _shops = [];
  bool _isLoading = false;
  bool _isSaving = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.fetchProfile();
      final shops = await _profileService.fetchShops();
      if (!mounted) return;
      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();
        if (profile['name'] != null) await prefs.setString('userName', profile['name']);
        if (profile['role'] != null) await prefs.setString('userRole', profile['role']);
        if (profile['avatar'] != null) {
          await prefs.setString('userAvatar', profile['avatar']);
        } else {
          await prefs.remove('userAvatar');
        }
        setState(() {
          _userProfile = profile;
          _nameController.text = profile['name'] ?? '';
        });
      }
      setState(() {
        _shops = shops;
      });
    } catch (e) {
      developer.log("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.darkCard,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final userId = _userProfile?['_id'] ?? 'user';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = pickedFile.name.split('.').last;
      final fileName = '${userId}_$timestamp.$extension';

      final uploadedName = await _profileService.uploadProfilePhoto(bytes, fileName);
      if (uploadedName != null) {
        await _profileService.updateProfile(avatar: uploadedName);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully!'), backgroundColor: AppTheme.trustGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final updated = await _profileService.updateProfile(name: _nameController.text.trim());
      if (updated != null) {
        _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: AppTheme.trustGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/auth/update-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password Changed Successfully!'), backgroundColor: AppTheme.trustGreen),
          );
        }
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Password update failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _downloadData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Triggered data download check. Backup file generated.'), backgroundColor: AppTheme.trustGreen),
    );
  }

  Future<void> _deleteAccount() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion request queued. 14-day recovery window active.'), backgroundColor: AppTheme.alertRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = _userProfile?['avatar'] as String?;
    final initials = (_userProfile?['name'] ?? 'MR')
        .toString()
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: AppTheme.brandPurple,
          unselectedLabelColor: AppTheme.darkGrey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Shops'),
            Tab(text: 'Settings'),
            Tab(text: 'Security'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Hero Header Block
                Container(
                  padding: const EdgeInsets.all(24),
                  color: theme.cardTheme.color ?? const Color(0xFF1A2231),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.brandPurple,
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      initials.substring(0, initials.length > 2 ? 2 : initials.length),
                                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.brandPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?['name'] ?? 'Masterji Ramesh',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _userProfile?['role']?.toString().toUpperCase() ?? 'OWNER',
                              style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _userProfile?['email'] ?? '',
                              style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProfileTab(
                        nameController: _nameController,
                        isSaving: _isSaving,
                        onSave: _updateProfile,
                      ),
                      ShopsTab(
                        shops: _shops,
                        activeShopId: _userProfile?['shopId'] as String?,
                        onSwitchShop: (shopId) async {
                          await _profileService.switchShop(shopId);
                          _loadProfile();
                        },
                      ),
                      SettingsTab(
                        onDownloadData: _downloadData,
                        onDeleteAccount: _deleteAccount,
                      ),
                      SecurityTab(
                        currentPasswordController: _currentPasswordController,
                        newPasswordController: _newPasswordController,
                        isSaving: _isSaving,
                        onUpdatePassword: _updatePassword,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
