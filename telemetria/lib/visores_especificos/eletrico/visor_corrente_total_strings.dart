import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorCorrenteTotalStrings extends StatelessWidget {
  final TelemetriaController controller;
  const VisorCorrenteTotalStrings({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.correnteTotalStrings,
      builder: (context, valor, child) {
        return MostradorLinha(
          titulo: 'GERAÇÃO',
          valorPrimario: '${valor.toStringAsFixed(1)} A',
          corDestaque: Colors.yellow,
        );
      },
    );
  }
}