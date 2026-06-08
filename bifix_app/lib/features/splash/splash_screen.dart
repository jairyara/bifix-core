import 'package:flutter/material.dart';

/// Shown while the persisted session is restored on startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pedal_bike, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text('Vikla',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    )),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
