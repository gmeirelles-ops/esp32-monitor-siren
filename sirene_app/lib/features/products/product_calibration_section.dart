import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';
import 'device_calibration.dart';

/// Seção de autocalibração na tela Editar produto.
class ProductCalibrationSection extends StatelessWidget {
  const ProductCalibrationSection({
    super.key,
    required this.selectedDeviceName,
    required this.selectedDeviceId,
    required this.deviceOnline,
    required this.deviceEstado,
    required this.calibrating,
    required this.onRecalibrate,
    required this.onDevicePicker,
    this.buttonLabel = 'Recalibrar peça padrão',
  });

  final String? selectedDeviceName;
  final String? selectedDeviceId;
  final bool deviceOnline;
  final String? deviceEstado;
  final bool calibrating;
  final VoidCallback onRecalibrate;
  final VoidCallback onDevicePicker;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final canCalibrate = DeviceCalibration.canCalibrate(
      deviceOnline: deviceOnline,
      estado: deviceEstado,
    );
    final deviceLabel = selectedDeviceId != null
        ? DeviceCalibration.deviceLabel(
            selectedDeviceName,
            selectedDeviceId,
            deviceOnline,
            deviceEstado,
          )
        : 'Selecione um dispositivo';

    return Card(
      color: DipontoColors.cardElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Autocalibração',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Dispositivo',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DipontoColors.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              subtitle: Text(deviceLabel),
              trailing: IconButton(
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: DipontoColors.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: onDevicePicker,
              ),
              onTap: onDevicePicker,
            ),
            const SizedBox(height: 4),
            Text(
              DeviceCalibration.estadoHint(deviceEstado, deviceOnline),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: deviceOnline ? DipontoColors.primaryLight : DipontoColors.error,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (canCalibrate && !calibrating) ? onRecalibrate : null,
              style: FilledButton.styleFrom(
                backgroundColor: DipontoColors.primary,
                foregroundColor: DipontoColors.onPrimary,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: calibrating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bolt),
              label: Text(calibrating ? 'Calibrando…' : buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
