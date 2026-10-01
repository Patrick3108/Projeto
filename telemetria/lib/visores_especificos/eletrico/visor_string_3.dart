import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorString3 extends StatelessWidget {
  final TelemetriaController controller;
  const VisorString3({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller.tensaoString3, controller.correnteString3]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'ST 3',
          valorPrimario: '${controller.tensaoString3.value.toStringAsFixed(1)} V',
          valorSecundario: '${controller.correnteString3.value.toStringAsFixed(1)} A',
          corDestaque: Colors.amber,
        );
      },
    );
  }
}