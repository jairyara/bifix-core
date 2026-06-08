import 'package:flutter/material.dart';

/// Large selectable card used in onboarding and the profile mode switcher.
/// Carries the framing for each riding mode (privacy vs assistant).
class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.badge,
    required this.title,
    required this.description,
    required this.bullets,
    this.selected = false,
    this.footnote,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;

  /// Short framing label, e.g. "Privacidad" / "Asistente".
  final String badge;
  final String title;
  final String description;
  final List<String> bullets;
  final bool selected;
  final String? footnote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.08)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(height: 6),
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: accent),
                ],
              ),
              const SizedBox(height: 12),
              Text(description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              for (final b in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(b,
                              style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                ),
              if (footnote != null) ...[
                const SizedBox(height: 4),
                Text(footnote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
