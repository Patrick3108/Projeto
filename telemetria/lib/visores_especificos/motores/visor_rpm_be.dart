import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-rpm.dart';

class VisorRpmBe extends StatelessWidget {
  final TelemetriaController controller;

  const VisorRpmBe({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.rpmBe,
      builder: (context, rpm, child) {
        return MostradorRpm(
          titulo: 'BORESTE',
          corDestaque: Colors.greenAccent,
          rpm: rpm,
          velocidade: controller.velocidade.value,
        );
      },
    );
  }
}