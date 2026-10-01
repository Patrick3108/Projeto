import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorTemperaturasBe extends StatelessWidget {
  final TelemetriaController controller;
  const VisorTemperaturasBe({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller.tempBe, controller.tempEscBe]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'TEMP BE (MOT | ESC)',
          valorPrimario: '${controller.tempBe.value.toStringAsFixed(0)}°C',
          valorSecundario: '${controller.tempEscBe.value.toStringAsFixed(0)}°C',
          corDestaque: Colors.greenAccent,
        );
      },
    );
  }
}