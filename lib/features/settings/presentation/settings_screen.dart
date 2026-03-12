import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  bool _initialized = false;
  bool _lowLiteracyMode = false;
  String? _pdfSavePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session?.profile == null) return;
    final profile = session!.profile!.copyWith(
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      lowLiteracyMode: _lowLiteracyMode,
      pdfSavePath: _pdfSavePath,
      clearPdfSavePath: _pdfSavePath == null,
    );
    await ref.read(sessionProvider.notifier).updateProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _pickPdfLocation() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose PDF save location',
    );
    if (selectedDirectory != null) {
      setState(() => _pdfSavePath = selectedDirectory);
      // Auto-save the PDF location change
      await _savePdfLocation(selectedDirectory);
    }
  }

  void _clearPdfLocation() async {
    setState(() => _pdfSavePath = null);
    // Auto-save the cleared PDF location
    await _savePdfLocation(null);
  }

  Future<void> _savePdfLocation(String? path) async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session?.profile == null) return;
    final profile = session!.profile!.copyWith(
      pdfSavePath: path,
      clearPdfSavePath: path == null,
    );
    await ref.read(sessionProvider.notifier).updateProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(path != null ? 'PDF location saved' : 'PDF location reset to default')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? You will need to enter your details again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(sessionProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final profile = session.valueOrNull?.profile;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!_initialized && profile != null) {
      _initialized = true;
      _nameController.text = profile.name;
      _locationController.text = profile.location;
      _lowLiteracyMode = profile.lowLiteracyMode;
      _pdfSavePath = profile.pdfSavePath;
    }

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        // Header with avatar
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.leaf, AppTheme.freshGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.leaf.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile?.name.isNotEmpty == true
                        ? profile!.name[0].toUpperCase()
                        : 'F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile?.name ?? 'Farmer',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile?.location ?? 'Location',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDarkMode ? colorScheme.outline : AppTheme.sage),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? colorScheme.primaryContainer : AppTheme.lightGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: isDarkMode ? colorScheme.onPrimaryContainer : AppTheme.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profile Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Village / Location',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : AppTheme.sage.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.text_fields_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Large text mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                ),
                          ),
                          Text(
                            'Easier to read guidance',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _lowLiteracyMode,
                      onChanged: (value) => setState(() => _lowLiteracyMode = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: profile == null ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App Settings card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDarkMode ? const Color(0xFF333333) : AppTheme.sage),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF3D3D00) : AppTheme.lightGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: isDarkMode ? AppTheme.gold : AppTheme.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'App Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Theme toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : AppTheme.sage.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                ),
                          ),
                          Text(
                            isDarkMode ? 'Dark theme active' : 'Light theme active',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // PDF save location
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : AppTheme.sage.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PDF Save Location',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 15,
                                    ),
                              ),
                              Text(
                                _pdfSavePath ?? 'Downloads/MaizeGuard/reports',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickPdfLocation,
                            icon: const Icon(Icons.folder_open_rounded, size: 18),
                            label: const Text('Choose Folder'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                        if (_pdfSavePath != null) ...[
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            onPressed: _clearPdfLocation,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Reset to default',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDarkMode ? colorScheme.outline : AppTheme.sage),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? colorScheme.primaryContainer : AppTheme.sage,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: isDarkMode ? colorScheme.onPrimaryContainer : AppTheme.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Maize Guard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'All data stays on this device. No internet required for diagnosis.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sign out button
        OutlinedButton.icon(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade200),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? LinearGradient(
                  colors: [colorScheme.surface, colorScheme.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [AppTheme.lightGold, AppTheme.cream, AppTheme.sage],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(child: body),
      );
    }

    return Scaffold(body: body);
  }
}
