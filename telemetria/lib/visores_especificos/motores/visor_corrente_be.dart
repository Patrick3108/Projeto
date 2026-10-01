import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-barra-vertical.dart';

class VisorCorrenteBe extends StatelessWidget {
  final TelemetriaController controller;

  const VisorCorrenteBe({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.correnteBe,
      builder: (context, valor, child) {
        return MostradorBarraVertical(
          titulo: 'CORRENTE BE',
          unidade: 'A',
          corDestaque: Colors.greenAccent,
          valor: valor,
        );
      },
    );
  }
}