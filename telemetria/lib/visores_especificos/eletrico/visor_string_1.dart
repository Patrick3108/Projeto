import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorString1 extends StatelessWidget {
  final TelemetriaController controller;
  const VisorString1({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller.tensaoString1, controller.correnteString1]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'ST 1',
          valorPrimario: '${controller.tensaoString1.value.toStringAsFixed(1)} V',
          valorSecundario: '${controller.correnteString1.value.toStringAsFixed(1)} A',
          corDestaque: Colors.amber,
        );
      },
    );
  }
}