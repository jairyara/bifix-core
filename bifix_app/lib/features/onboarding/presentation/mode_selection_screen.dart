import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../preferences/application/preferences_controller.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../preferences/presentation/mode_framing.dart';
import 'widgets/mode_card.dart';

/// Onboarding (and profile) screen where the user picks how the odometer is fed.
/// Reached automatically after registration, or from Perfil to switch modes.
class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(ridingModeProvider);
    final estimation = ModeFraming.of(RidingMode.estimation);
    final tracking = ModeFraming.of(RidingMode.tracking);

    Future<void> choose(RidingMode mode) async {
      if (mode == RidingMode.estimation) {
        // Estimation needs a daily profile → go to its setup step.
        context.push(Routes.onboardingEstimation);
        return;
      }
      await ref.read(preferencesControllerProvider.notifier).setMode(mode);
      if (!context.mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.home);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Cómo registramos tus km?'),
        automaticallyImplyLeading: context.canPop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Tu mantenimiento se calcula con los kilómetros que recorres. '
              'Elige cómo prefieres registrarlos:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ModeCard(
              icon: estimation.icon,
              accent: estimation.accent,
              badge: estimation.badge,
              title: estimation.title,
              description: estimation.tagline,
              bullets: estimation.bullets,
              selected: current == RidingMode.estimation,
              onTap: () => choose(RidingMode.estimation),
            ),
            const SizedBox(height: 16),
            ModeCard(
              icon: tracking.icon,
              accent: tracking.accent,
              badge: tracking.badge,
              title: tracking.title,
              description: tracking.tagline,
              bullets: tracking.bullets,
              footnote: tracking.footnote,
              selected: current == RidingMode.tracking,
              onTap: () => choose(RidingMode.tracking),
            ),
            const SizedBox(height: 24),
            Text(
              'Podrás cambiar de modo cuando quieras desde tu perfil.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
