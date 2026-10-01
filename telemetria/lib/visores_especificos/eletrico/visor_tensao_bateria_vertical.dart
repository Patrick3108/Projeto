import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-barra-vertical.dart';

class VisorTensaoBateriaVertical extends StatelessWidget {
  final TelemetriaController controller;

  const VisorTensaoBateriaVertical({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.tensaoBateria,
      builder: (context, valor, child) {
        return MostradorBarraVertical(
          titulo: 'TENSÃO BAT',
          unidade: 'V',
          corDestaque: Colors.blueAccent,
          valor: valor,
        );
      },
    );
  }
}