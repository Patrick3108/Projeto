import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-barra-vertical.dart';

class VisorCorrenteBb extends StatelessWidget {
  final TelemetriaController controller;

  const VisorCorrenteBb({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.correnteBb,
      builder: (context, valor, child) {
        return MostradorBarraVertical(
          titulo: 'CORRENTE BB',
          unidade: 'A',
          corDestaque: Colors.redAccent,
          valor: valor,
        );
      },
    );
  }
}