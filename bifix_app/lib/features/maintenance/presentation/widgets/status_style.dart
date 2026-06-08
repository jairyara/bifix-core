import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/maintenance.dart';

/// Visual style (color, icon, label) for a maintenance status.
class StatusStyle {
  const StatusStyle(this.color, this.icon, this.label);
  final Color color;
  final IconData icon;
  final String label;

  static StatusStyle of(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.overdue:
        return const StatusStyle(
            Color(0xFFD32F2F), Icons.error, 'Vencido');
      case MaintenanceStatus.dueSoon:
        return const StatusStyle(
            AppTheme.ambarAlerta, Icons.warning_amber_rounded, 'Próximo');
      case MaintenanceStatus.ok:
        return const StatusStyle(
            AppTheme.verdeExito, Icons.check_circle, 'Al día');
    }
  }
}

/// Icon representing a maintenance task by its id.
IconData iconForTask(String taskId) {
  switch (taskId) {
    case 'chain-lube':
      return Icons.link;
    case 'brakes':
      return Icons.disc_full;
    case 'tires':
      return Icons.tire_repair;
    case 'battery':
      return Icons.battery_charging_full;
    case 'drivetrain':
      return Icons.settings;
    case 'general':
      return Icons.build_circle;
    default:
      return Icons.handyman;
  }
}
