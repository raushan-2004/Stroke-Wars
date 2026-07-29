import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:stroke_wars/app/theme/app_theme.dart';
import 'package:stroke_wars/core/services/theme_service.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';
import 'package:stroke_wars/shared/design_language/widgets/avatars/avatar_framework.dart';

/// Screen allowing the player to customize their name, avatar, color theme, and brush.
class ProfileEditPage extends ConsumerStatefulWidget {
  /// Creates a [ProfileEditPage].
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late String _displayName;
  late String _selectedAvatarId;
  late String _selectedFrameId;
  late String _selectedTheme;
  late String _selectedAccent;
  late String _selectedBrush;
  String? _profilePicturePath;

  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final player = ref.read(playerServiceProvider)!;
    _displayName = player.displayName;
    _selectedAvatarId = player.cosmetics.avatarId;
    _selectedFrameId = player.cosmetics.avatarFrame;
    _selectedTheme = player.settings.themeMode;
    _selectedAccent = player.settings.accentColor;
    _selectedBrush = player.cosmetics.favoriteBrush;
    _profilePicturePath = player.profilePicturePath;

    _nameController.text = _displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (mounted) {
            SWToast.show(
              context,
              'Camera permission required to capture profile photo.',
            );
          }
          return;
        }
      } else {
        await Permission.photos.request();
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final localPath =
          '${directory.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy(localPath);

      setState(() {
        _profilePicturePath = savedFile.path;
      });
      if (mounted) {
        SWToast.show(context, 'Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        SWToast.show(context, 'Failed to pick image: $e');
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _profilePicturePath = null;
    });
    SWToast.show(context, 'Photo removed.');
  }

  Future<void> _saveChanges() async {
    if (_displayName.trim().isEmpty) {
      SWToast.show(context, 'Please enter a valid display name.');
      return;
    }

    final player = ref.read(playerServiceProvider)!;
    final updatedPlayer = player.copyWith(
      displayName: _displayName.trim(),
      profilePicturePath: _profilePicturePath,
      settings: player.settings.copyWith(
        themeMode: _selectedTheme,
        accentColor: _selectedAccent,
      ),
      cosmetics: player.cosmetics.copyWith(
        avatarId: _selectedAvatarId,
        avatarFrame: _selectedFrameId,
        theme: _selectedTheme,
        accentColor: _selectedAccent,
        favoriteBrush: _selectedBrush,
        favoriteColor: getAccentColorValue(_selectedAccent).toHexString(),
      ),
    );

    // Persist edits and sync ThemeNotifier
    await ref.read(playerServiceProvider.notifier).updatePlayer(updatedPlayer);

    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final selectedMode = _selectedTheme == 'dark'
        ? ThemeMode.dark
        : (_selectedTheme == 'light' ? ThemeMode.light : ThemeMode.system);
    await themeNotifier.setThemeMode(selectedMode);

    if (mounted) {
      Navigator.pop(context);
      SWToast.show(context, 'Profile changes saved!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final accents = ['purple', 'cyan', 'orange', 'pink', 'green', 'gold'];
    final brushes = ['paintbrush', 'marker', 'pencil', 'crayon'];

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text(
          'EDIT PROFILE',
          style: typography.heading.copyWith(letterSpacing: 1),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const SWIcon(SWIcons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.swSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SWAvatar(
                name: _displayName,
                avatarId: _selectedAvatarId,
                avatarFrameId: _selectedFrameId,
                profilePicturePath: _profilePicturePath,
                size: SWAvatarSize.large,
              ),
            ),
            SizedBox(height: context.swSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SWButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  text: 'CAMERA',
                  variant: SWButtonVariant.outlined,
                  icon: const SWIcon(Icons.camera_alt_rounded),
                ),
                SizedBox(width: context.swSpacing.md),
                SWButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  text: 'GALLERY',
                  variant: SWButtonVariant.outlined,
                  icon: const SWIcon(Icons.photo_library_rounded),
                ),
              ],
            ),
            if (_profilePicturePath != null) ...[
              SizedBox(height: context.swSpacing.sm),
              TextButton.icon(
                onPressed: _removePhoto,
                icon: Icon(Icons.delete_forever_rounded, color: colors.danger),
                label: Text(
                  'Remove photo',
                  style: TextStyle(color: colors.danger),
                ),
              ),
            ],
            SizedBox(height: context.swSpacing.xl),

            // Profile details input
            const SWSectionHeader(title: 'Display Moniker'),
            SizedBox(height: context.swSpacing.sm),
            SWTextField(
              controller: _nameController,
              hintText: 'Moniker...',
              onChanged: (val) => setState(() => _displayName = val),
            ),
            SizedBox(height: context.swSpacing.xl),

            // Avatar select grid
            const SWSectionHeader(title: 'Choose Avatar'),
            SizedBox(height: context.swSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: context.swSpacing.md,
                mainAxisSpacing: context.swSpacing.md,
              ),
              itemCount: AvatarFramework.avatars.length,
              itemBuilder: (context, index) {
                final def = AvatarFramework.avatars[index];
                final isSelected = def.id == _selectedAvatarId;
                return SWPressableScale(
                  onTap: () => setState(() => _selectedAvatarId = def.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? def.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: SWRadius.l,
                      border: Border.all(
                        color: isSelected ? def.color : colors.border,
                        width: isSelected ? 2.5.r : 1.5.r,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          def.icon,
                          size: 28.r,
                          color: isSelected ? def.color : colors.textMuted,
                        ),
                        SizedBox(height: context.swSpacing.xs),
                        Text(
                          def.name,
                          style: typography.caption.copyWith(
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted,
                            fontSize: 10.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: context.swSpacing.xl),

            // Cosmetic Frame Select
            const SWSectionHeader(title: 'Cosmetic Border Frame'),
            SizedBox(height: context.swSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: context.swSpacing.md,
                mainAxisSpacing: context.swSpacing.md,
                childAspectRatio: 2.2,
              ),
              itemCount: AvatarFramework.frames.length,
              itemBuilder: (context, index) {
                final frame = AvatarFramework.frames[index];
                final isSelected = frame.id == _selectedFrameId;
                return SWPressableScale(
                  onTap: () => setState(() => _selectedFrameId = frame.id),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.swSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: SWRadius.l,
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                        width: isSelected ? 2.r : 1.5.r,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        frame.name,
                        style: typography.title.copyWith(
                          color: isSelected
                              ? colors.textPrimary
                              : colors.textMuted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: context.swSpacing.xl),

            // Theme select
            const SWSectionHeader(title: 'UI Settings Theme'),
            SizedBox(height: context.swSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: SWPressableScale(
                    onTap: () => setState(() => _selectedTheme = 'dark'),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: context.swSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedTheme == 'dark'
                            ? colors.primary.withValues(alpha: 0.08)
                            : colors.surfaceContainer,
                        borderRadius: SWRadius.l,
                        border: Border.all(
                          color: _selectedTheme == 'dark'
                              ? colors.primary
                              : colors.border,
                          width: _selectedTheme == 'dark' ? 2.r : 1.r,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'DARK THEME',
                          style: typography.title.copyWith(
                            color: _selectedTheme == 'dark'
                                ? colors.textPrimary
                                : colors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.swSpacing.md),
                Expanded(
                  child: SWPressableScale(
                    onTap: () => setState(() => _selectedTheme = 'light'),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: context.swSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedTheme == 'light'
                            ? colors.primary.withValues(alpha: 0.08)
                            : colors.surfaceContainer,
                        borderRadius: SWRadius.l,
                        border: Border.all(
                          color: _selectedTheme == 'light'
                              ? colors.primary
                              : colors.border,
                          width: _selectedTheme == 'light' ? 2.r : 1.r,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'LIGHT THEME',
                          style: typography.title.copyWith(
                            color: _selectedTheme == 'light'
                                ? colors.textPrimary
                                : colors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.swSpacing.xl),

            // Accent color select
            const SWSectionHeader(title: 'Color Accent'),
            SizedBox(height: context.swSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: context.swSpacing.md,
              runSpacing: context.swSpacing.md,
              children: accents.map((accent) {
                final accentColor = getAccentColorValue(accent);
                final isSelected = _selectedAccent == accent;

                return SWPressableScale(
                  onTap: () => setState(() => _selectedAccent = accent),
                  child: Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colors.textPrimary
                            : Colors.transparent,
                        width: 3.r,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.5),
                                blurRadius: 10.r,
                                spreadRadius: 1.r,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20.r,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: context.swSpacing.xl),

            // Favorite Drawing Brush Choice
            const SWSectionHeader(title: 'Preferred Painting Brush'),
            SizedBox(height: context.swSpacing.sm),
            Wrap(
              spacing: context.swSpacing.sm,
              runSpacing: context.swSpacing.sm,
              alignment: WrapAlignment.center,
              children: brushes.map((brush) {
                final isSelected = _selectedBrush == brush;
                return SWPressableScale(
                  onTap: () => setState(() => _selectedBrush = brush),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.swSpacing.md,
                      vertical: context.swSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.1)
                          : colors.surfaceContainer,
                      borderRadius: SWRadius.xl,
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                        width: 1.5.r,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.brush_rounded,
                          size: 16.r,
                          color: isSelected ? colors.primary : colors.textMuted,
                        ),
                        SizedBox(width: context.swSpacing.xs),
                        Text(
                          brush.toUpperCase(),
                          style: typography.caption.copyWith(
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: context.swSpacing.xxl),

            // Save actions
            SWButton(onPressed: _saveChanges, text: 'SAVE CHANGES'),
            SizedBox(height: context.swSpacing.sm),
            SWButton(
              onPressed: () => Navigator.pop(context),
              text: 'CANCEL',
              variant: SWButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper extension to serialize color to hex string.
extension ColorToHexX on Color {
  /// Converts [Color] to string hex format `#RRGGBB`.
  String toHexString() {
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
