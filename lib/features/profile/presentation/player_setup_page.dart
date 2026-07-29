import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:stroke_wars/core/services/theme_service.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/app/theme/app_theme.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';
import 'package:stroke_wars/shared/design_language/widgets/avatars/avatar_framework.dart';

/// Interactive onboarding page to create a local player profile on first launch.
class PlayerSetupPage extends ConsumerStatefulWidget {
  /// Creates a [PlayerSetupPage].
  const PlayerSetupPage({super.key});

  @override
  ConsumerState<PlayerSetupPage> createState() => _PlayerSetupPageState();
}

class _PlayerSetupPageState extends ConsumerState<PlayerSetupPage> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form states
  String _displayName = '';
  String _selectedAvatarId = 'robot';
  String _selectedTheme = 'dark';
  String _selectedAccent = 'purple';
  String? _profilePicturePath;

  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _randomNames = const [
    'NeonDoodler',
    'SketchFox',
    'PixelWizard',
    'PaintKnight',
    'BrushPirate',
    'ArtNinja',
    'DoodleKing',
    'GraffitiGhost',
    'StrokeMaster',
    'InkSamurai',
  ];

  @override
  void initState() {
    super.initState();
    _generateRandomName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateRandomName() {
    final rand = Random();
    final name =
        '${_randomNames[rand.nextInt(_randomNames.length)]}#${rand.nextInt(9000) + 1000}';
    setState(() {
      _displayName = name;
      _nameController.text = name;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Permission checks
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
        // Photo library checks
        if (Platform.isAndroid) {
          // Android 13+ photos check or fallback storage
          await Permission.photos.request();
        } else {
          await Permission.photos.request();
        }
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

  void _nextStep() {
    if (_currentStep == 1 && _displayName.trim().isEmpty) {
      SWToast.show(context, 'Please enter a valid display name.');
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveProfile() async {
    final playerService = ref.read(playerServiceProvider.notifier);
    await playerService.createPlayer(
      displayName: _displayName.trim(),
      avatarId: _selectedAvatarId,
      themeMode: _selectedTheme,
      accentColor: _selectedAccent,
      profilePicturePath: _profilePicturePath,
    );

    // Sync theme settings directly
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final selectedMode = _selectedTheme == 'dark'
        ? ThemeMode.dark
        : (_selectedTheme == 'light' ? ThemeMode.light : ThemeMode.system);
    await themeNotifier.setThemeMode(selectedMode);

    if (mounted) {
      context.goNamed('home');
      SWToast.show(
        context,
        'Profile set up successfully! Welcome, $_displayName.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.swSpacing.lg,
          vertical: context.swSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            SizedBox(height: context.swSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: typography.displayLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.swSpacing.sm),
                    Text(
                      _getStepSubtitle(),
                      style: typography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.swSpacing.xl),
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.swSpacing.lg),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final colors = context.swColors;
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: isActive ? colors.primary : colors.border,
              borderRadius: SWRadius.s,
            ),
          ),
        );
      }),
    );
  }

  String _getStepTitle() {
    return switch (_currentStep) {
      0 => 'CHOOSE AVATAR',
      1 => 'YOUR NAME',
      2 => 'SELECT THEME',
      3 => 'PROFILE PHOTO',
      _ => 'CHOOSE AVATAR',
    };
  }

  String _getStepSubtitle() {
    return switch (_currentStep) {
      0 => 'Select a built-in character to represent you.',
      1 => 'Enter your public display moniker.',
      2 => 'Choose your preferred visual styling and color accent.',
      3 => 'Capture or upload a custom gaming photo.',
      _ => '',
    };
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => _buildAvatarStep(),
      1 => _buildNameStep(),
      2 => _buildThemeStep(),
      3 => _buildPhotoStep(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildAvatarStep() {
    return GridView.builder(
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
                color: isSelected ? def.color : context.swColors.border,
                width: isSelected ? 2.5.r : 1.5.r,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: def.color.withValues(alpha: 0.25),
                        blurRadius: 10.r,
                        spreadRadius: 1.r,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  def.icon,
                  size: 32.r,
                  color: isSelected ? def.color : context.swColors.textMuted,
                ),
                SizedBox(height: context.swSpacing.xs),
                Text(
                  def.name,
                  style: context.swTypography.caption.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? context.swColors.textPrimary
                        : context.swColors.textMuted,
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameStep() {
    final colors = context.swColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SWTextField(
          controller: _nameController,
          hintText: 'Enter name...',
          onChanged: (val) => setState(() => _displayName = val),
        ),
        SizedBox(height: context.swSpacing.lg),
        SWButton(
          onPressed: _generateRandomName,
          text: 'RANDOM NAME',
          variant: SWButtonVariant.secondary,
          icon: SWIcon(Icons.shuffle_rounded, color: colors.secondary),
        ),
      ],
    );
  }

  Widget _buildThemeStep() {
    final colors = context.swColors;
    final typography = context.swTypography;

    final accents = ['purple', 'cyan', 'orange', 'pink', 'green', 'gold'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SWPressableScale(
                onTap: () => setState(() => _selectedTheme = 'dark'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: context.swSpacing.lg),
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
                  child: Column(
                    children: [
                      SWIcon(
                        Icons.dark_mode_rounded,
                        color: _selectedTheme == 'dark'
                            ? colors.primary
                            : colors.textMuted,
                        size: 32.r,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      Text(
                        'DARK MODE',
                        style: typography.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: context.swSpacing.md),
            Expanded(
              child: SWPressableScale(
                onTap: () => setState(() => _selectedTheme = 'light'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: context.swSpacing.lg),
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
                  child: Column(
                    children: [
                      SWIcon(
                        Icons.light_mode_rounded,
                        color: _selectedTheme == 'light'
                            ? colors.primary
                            : colors.textMuted,
                        size: 32.r,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      Text(
                        'LIGHT MODE',
                        style: typography.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.swSpacing.xl),
        Text(
          'FAVORITE ACCENT COLOR',
          style: typography.gameLabel.copyWith(color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
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
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.textPrimary : Colors.transparent,
                    width: 3.r,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 12.r,
                            spreadRadius: 2.r,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 24.r)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      children: [
        Center(
          child: SWAvatar(
            name: _displayName,
            avatarId: _selectedAvatarId,
            profilePicturePath: _profilePicturePath,
            size: SWAvatarSize.large,
          ),
        ),
        SizedBox(height: context.swSpacing.lg),
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
            icon: Icon(
              Icons.delete_forever_rounded,
              color: context.swColors.danger,
            ),
            label: Text(
              'Remove custom photo',
              style: TextStyle(color: context.swColors.danger),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: SWButton(
              onPressed: _prevStep,
              text: 'BACK',
              variant: SWButtonVariant.outlined,
            ),
          ),
        if (_currentStep > 0) SizedBox(width: context.swSpacing.md),
        Expanded(
          child: SWButton(
            onPressed: _nextStep,
            text: _currentStep == _totalSteps - 1
                ? 'READY TO PLAY'
                : 'CONTINUE',
          ),
        ),
      ],
    );
  }
}
