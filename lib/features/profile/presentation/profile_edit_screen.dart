import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../domain/cyclist_profile.dart';
import '../domain/training_zones.dart';
import 'profile_providers.dart';
import 'widgets/birth_date_field.dart';
import 'zones_providers.dart';

/// Edición de todo el perfil en un solo lugar: identidad (foto, nombre,
/// ciudad, bio) y datos deportivos (peso, FTP, FC máx/reposo, fecha de
/// nacimiento). Ninguno de los datos deportivos es obligatorio.
///
/// Si al guardar cambió el FTP o la FC, las zonas de entrenamiento se
/// recalculan solas con los datos nuevos.
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
  final _weightCtrl = TextEditingController();
  final _ftpCtrl = TextEditingController();
  final _maxHrCtrl = TextEditingController();
  final _restingHrCtrl = TextEditingController();

  String? _avatarPath;
  DateTime? _birthDate;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    _weightCtrl.dispose();
    _ftpCtrl.dispose();
    _maxHrCtrl.dispose();
    _restingHrCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(CyclistProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = profile.name;
    _cityCtrl.text = profile.city ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _weightCtrl.text = profile.weightKg?.toString() ?? '';
    _ftpCtrl.text = profile.ftpWatts?.toString() ?? '';
    _maxHrCtrl.text = profile.maxHr?.toString() ?? '';
    _restingHrCtrl.text = profile.restingHr?.toString() ?? '';
    _avatarPath = profile.avatarPath;
    _birthDate = profile.birthDate;
  }

  int? get _estimatedMaxHr => _birthDate == null
      ? null
      : CyclistProfile(name: '', birthDate: _birthDate).estimatedMaxHrFromAge;

  void _useEstimatedMaxHr() {
    final estimate = _estimatedMaxHr;
    if (estimate == null) {
      _snack('Pon tu fecha de nacimiento para calcular el estimado.');
      return;
    }
    setState(() => _maxHrCtrl.text = estimate.toString());
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AvatarConfirmScreen(imageFile: newFile),
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _avatarPath = newFile.path);
    } else if (await newFile.exists()) {
      await newFile.delete();
    }
  }

  Future<void> _submit(CyclistProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    int? pi(TextEditingController c) => int.tryParse(c.text.trim());

    // Se construye a mano (no con copyWith) para poder VACIAR un dato a
    // null cuando el usuario borra el campo.
    final updated = CyclistProfile(
      name: _nameCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      ftpWatts: pi(_ftpCtrl),
      maxHr: pi(_maxHrCtrl),
      restingHr: pi(_restingHrCtrl),
      birthDate: _birthDate,
      avatarPath: _avatarPath,
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );

    await ref.read(profileProvider.notifier).saveProfile(updated);

    // Si cambió algún dato que alimenta las zonas, se recalculan solas.
    final zonesChanged =
        updated.ftpWatts != current.ftpWatts ||
        updated.maxHr != current.maxHr ||
        updated.restingHr != current.restingHr;
    if (zonesChanged) {
      await ref
          .read(zonesProvider.notifier)
          .saveZones(TrainingZones.computeDefaults(updated));
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (zonesChanged) _snack('Zonas recalculadas con tus datos nuevos.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Editar perfil')),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CcColors.orange),
        ),
        error: (error, _) => Center(
          child: Text(
            'No se pudo cargar tu perfil:\n$error',
            style: const TextStyle(color: CcColors.inkDim),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Completa primero tu perfil.',
                  style: TextStyle(color: CcColors.inkDim),
                ),
              ),
            );
          }
          _initFromProfile(profile);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: CcColors.orange.withValues(
                              alpha: 0.14,
                            ),
                            backgroundImage: _avatarPath != null
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: CcColors.orange,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CcColors.orange,
                                border: Border.all(
                                  color: CcColors.bg,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  _SectionLabel('IDENTIDAD'),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _nameCtrl,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                    hint: '¿Cómo te decimos?',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _cityCtrl,
                    label: 'Ciudad (opcional)',
                    icon: Icons.location_on_outlined,
                    hint: 'Bogotá',
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _bioCtrl,
                    label: 'Biografía (opcional)',
                    icon: Icons.notes_outlined,
                    hint: 'Escalador de fin de semana',
                  ),

                  const SizedBox(height: 26),
                  _SectionLabel('DATOS DEPORTIVOS'),
                  const SizedBox(height: 4),
                  Text(
                    'Todo opcional. Lo que dejes vacío se apaga (sin FTP no '
                    'hay zonas de potencia, etc.).',
                    style: CcType.label(size: 11, color: CcColors.inkFaint),
                  ),
                  const SizedBox(height: 14),
                  BirthDateField(
                    value: _birthDate,
                    onChanged: (d) => setState(() => _birthDate = d),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _weightCtrl,
                    label: 'Peso (opcional)',
                    icon: Icons.monitor_weight_outlined,
                    hint: 'Ej. 72',
                    suffixText: 'kg',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _rangeD(v, 20, 250, 'Peso inválido'),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _ftpCtrl,
                    label: 'FTP (opcional)',
                    icon: Icons.bolt_outlined,
                    hint: 'Ej. 220',
                    suffixText: 'W',
                    keyboardType: TextInputType.number,
                    validator: (v) => _rangeI(v, 1, 600, 'FTP inválido'),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _maxHrCtrl,
                    label: 'FC máxima (opcional)',
                    icon: Icons.favorite_border,
                    hint: 'Ej. 190',
                    suffixText: 'lpm',
                    keyboardType: TextInputType.number,
                    validator: (v) => _rangeI(v, 100, 230, 'FC inválida'),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _useEstimatedMaxHr,
                      style: TextButton.styleFrom(
                        foregroundColor: CcColors.blue,
                      ),
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: Text(
                        _estimatedMaxHr == null
                            ? 'No la sé — calcular con mi edad'
                            : 'No la sé — usar estimado ($_estimatedMaxHr lpm)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: _restingHrCtrl,
                    label: 'FC en reposo (opcional)',
                    icon: Icons.bedtime_outlined,
                    hint: 'Ej. 55',
                    suffixText: 'lpm',
                    keyboardType: TextInputType.number,
                    validator: (v) => _rangeI(v, 30, 120, 'FC inválida'),
                  ),

                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: _saving ? null : () => _submit(profile),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String? _rangeI(String? v, int lo, int hi, String msg) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < lo || n > hi) return msg;
    return null;
  }

  static String? _rangeD(String? v, double lo, double hi, String msg) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null || n < lo || n > hi) return msg;
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: CcType.label(
        size: 11,
        color: CcColors.inkFaint,
      ).copyWith(letterSpacing: 1.2),
    );
  }
}

/// Confirma la foto recién elegida en grande (con zoom) antes de
/// aplicarla como avatar.
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
                      ),
                      child: const Text('Elegir otra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: CcColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Usar esta foto'),
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
