import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorTemperaturasBb extends StatelessWidget {
  final TelemetriaController controller;
  const VisorTemperaturasBb({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller.tempBb, controller.tempEscBb]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'TEMP BB (MOT | ESC)',
          valorPrimario: '${controller.tempBb.value.toStringAsFixed(0)}°C',
          valorSecundario: '${controller.tempEscBb.value.toStringAsFixed(0)}°C',
          corDestaque: Colors.redAccent,
        );
      },
    );
  }
}