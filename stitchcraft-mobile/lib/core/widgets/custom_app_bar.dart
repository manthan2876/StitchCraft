import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/sync_service.dart';
import 'package:stitchcraft/core/services/profile_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawerButton;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showDrawerButton = false,
    this.bottom,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

class _CustomAppBarState extends State<CustomAppBar> {
  final _syncService = SyncService();
  final _profileService = ProfileService();
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  String? _avatarUrl;
  String _initials = 'MR';

  @override
  void initState() {
    super.initState();
    _loadAppBarData();
  }

  Future<void> _loadAppBarData() async {
    // 1. Fetch Sync Status
    final status = await _syncService.getSyncStatus();
    // 2. Fetch User Profile
    final profile = await _profileService.fetchProfile();
    final prefs = await SharedPreferences.getInstance();
    
    if (mounted) {
      setState(() {
        _pendingSyncCount = status['pendingCount'] ?? 0;
        if (profile != null) {
          _avatarUrl = profile['avatar'] as String?;
          final name = profile['name'] as String? ?? 'Masterji Ramesh';
          _initials = name
              .split(' ')
              .map((n) => n.isNotEmpty ? n[0] : '')
              .join('')
              .toUpperCase();
        } else {
          _avatarUrl = prefs.getString('userAvatar');
          final name = prefs.getString('userName') ?? 'Masterji';
          _initials = name.isNotEmpty ? name[0].toUpperCase() : 'M';
        }
      });
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      await _syncService.syncAll();
      await _loadAppBarData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync Complete! All local records synchronized.'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Failed: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      bottom: widget.bottom,
      leading: widget.showDrawerButton
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          : null,
      actions: [
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Badge(
                  label: Text('$_pendingSyncCount'),
                  isLabelVisible: _pendingSyncCount > 0,
                  child: const Icon(Icons.sync),
                ),
          onPressed: _isSyncing ? null : _triggerSync,
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, '/profile');
            _loadAppBarData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.brandPurple,
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                    ? Text(
                        _initials.substring(0, _initials.length > 2 ? 2 : _initials.length),
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
