import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorString2 extends StatelessWidget {
  final TelemetriaController controller;
  const VisorString2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller.tensaoString2, controller.correnteString2]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'ST 2',
          valorPrimario: '${controller.tensaoString2.value.toStringAsFixed(1)} V',
          valorSecundario: '${controller.correnteString2.value.toStringAsFixed(1)} A',
          corDestaque: Colors.amber,
        );
      },
    );
  }
}