import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/cyclist_profile.dart';
import 'profile_providers.dart';

/// Edición de los datos "visuales" del perfil (foto, ciudad, bio,
/// nombre). Separada a propósito del `OnboardingScreen` -- ese sigue
/// siendo solo para los datos numéricos que alimentan el motor difuso
/// (FTP, FC, zonas); mezclar ambos hacía que "editar perfil" se sintiera
/// como "editar una actividad", que era justo el problema original.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _avatarPath;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(CyclistProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = profile.name;
    _cityCtrl.text = profile.city ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _avatarPath = profile.avatarPath;
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(docsDir.path, 'profile_avatar'));
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final ext = p.extension(picked.path);
    final newPath = p.join(
      avatarsDir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    final newFile = await File(picked.path).copy(newPath);

    if (!mounted) return;

    // Antes: la foto se aplicaba directo, y la única "confirmación"
    // era que la miniatura circular pequeña cambiaba -- fácil de no
    // notar bien cuál quedó. Ahora se muestra en grande antes de
    // aplicarla, con opción de usarla o descartarla.
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AvatarConfirmScreen(imageFile: newFile),
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _avatarPath = newFile.path);
    } else {
      // Si cancela, borramos la copia para no dejar basura en disco.
      if (await newFile.exists()) {
        await newFile.delete();
      }
    }
  }

  /// Se construye el `CyclistProfile` directamente (no con `copyWith`)
  /// para poder guardar ciudad/bio como null cuando el usuario borra el
  /// texto -- `copyWith` usa el patrón `?? this.x`, que no distingue
  /// entre "no tocar este campo" y "vaciarlo a propósito".
  Future<void> _submit(CyclistProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = CyclistProfile(
      name: _nameCtrl.text.trim(),
      weightKg: current.weightKg,
      ftpWatts: current.ftpWatts,
      maxHr: current.maxHr,
      restingHr: current.restingHr,
      avatarPath: _avatarPath,
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );

    await ref.read(profileProvider.notifier).saveProfile(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Editar perfil',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'No se pudo cargar tu perfil:\n$error',
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Completa primero el onboarding inicial.',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
            );
          }
          _initFromProfile(profile);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            backgroundImage: _avatarPath != null
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 52,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameCtrl,
                    style:
                        const TextStyle(color: AppColors.textPrimaryOnPanel),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      labelStyle:
                          TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityCtrl,
                    style:
                        const TextStyle(color: AppColors.textPrimaryOnPanel),
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      labelStyle:
                          TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    maxLength: 150,
                    style:
                        const TextStyle(color: AppColors.textPrimaryOnPanel),
                    decoration: const InputDecoration(
                      labelText: 'Biografía',
                      labelStyle:
                          TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _submit(profile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pantalla de confirmación: muestra la foto recién elegida en
/// grande (con zoom) antes de aplicarla como avatar. Resuelve el
/// problema de "elijo una foto y no puedo ver bien cuál quedó".
class _AvatarConfirmScreen extends StatelessWidget {
  final File imageFile;
  const _AvatarConfirmScreen({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const Spacer(),
                  const Text(
                    '¿Usar esta foto?',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(child: Image.file(imageFile)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Elegir otra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Usar esta foto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
