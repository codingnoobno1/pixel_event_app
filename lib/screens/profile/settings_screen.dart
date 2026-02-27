import 'package:flutter/material.dart';
// TODO: Import services/providers
// import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen for app preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoRefreshEnabled = true;
  int _refreshInterval = 30; // seconds
  String _theme = 'system'; // system, light, dark

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from local storage
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _notificationsEnabled = prefs.getBool('notifications') ?? true;
    //   _soundEnabled = prefs.getBool('sound') ?? true;
    //   _vibrationEnabled = prefs.getBool('vibration') ?? true;
    //   _autoRefreshEnabled = prefs.getBool('autoRefresh') ?? true;
    //   _refreshInterval = prefs.getInt('refreshInterval') ?? 30;
    //   _theme = prefs.getString('theme') ?? 'system';
    // });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    // TODO: Save setting to local storage
    // final prefs = await SharedPreferences.getInstance();
    // if (value is bool) {
    //   await prefs.setBool(key, value);
    // } else if (value is int) {
    //   await prefs.setInt(key, value);
    // } else if (value is String) {
    //   await prefs.setString(key, value);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive event updates and reminders'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSetting('notifications', value);
                },
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            title: 'Feedback',
            children: [
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound on scan success/failure'),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  _saveSetting('sound', value);
                },
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate on scan and interactions'),
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSetting('vibration', value);
                },
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            title: 'Data & Sync',
            children: [
              SwitchListTile(
                title: const Text('Auto Refresh'),
                subtitle: const Text('Automatically refresh event data'),
                value: _autoRefreshEnabled,
                onChanged: (value) {
                  setState(() => _autoRefreshEnabled = value);
                  _saveSetting('autoRefresh', value);
                },
              ),
              ListTile(
                title: const Text('Refresh Interval'),
                subtitle: Text('$_refreshInterval seconds'),
                trailing: DropdownButton<int>(
                  value: _refreshInterval,
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10s')),
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 60, child: Text('1m')),
                    DropdownMenuItem(value: 300, child: Text('5m')),
                  ],
                  onChanged: _autoRefreshEnabled
                      ? (value) {
                          if (value != null) {
                            setState(() => _refreshInterval = value);
                            _saveSetting('refreshInterval', value);
                          }
                        }
                      : null,
                ),
              ),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Remove cached event passes'),
                trailing: const Icon(Icons.delete_outline),
                onTap: _showClearCacheDialog,
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            title: 'Appearance',
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeLabel(_theme)),
                trailing: DropdownButton<String>(
                  value: _theme,
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _theme = value);
                      _saveSetting('theme', value);
                      // TODO: Apply theme change
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.info_outline),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
              ListTile(
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Open help page
                },
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            title: 'Account',
            children: [
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout, color: Colors.red),
                textColor: Colors.red,
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System Default';
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached event passes. You will need an internet connection to view them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Clear cache
      // await cacheService.clearCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Logout
      // await authService.logout();
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }
}
