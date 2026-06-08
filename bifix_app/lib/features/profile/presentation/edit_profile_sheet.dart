import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

/// Sheet to edit the current user's name and phone.
Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const _EditProfileSheet(),
    ),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            user.copyWith(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Editar perfil',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
