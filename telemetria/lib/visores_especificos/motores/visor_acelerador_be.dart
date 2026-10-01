import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-barra-vertical.dart';

class VisorAceleradorBe extends StatelessWidget {
  final TelemetriaController controller;

  const VisorAceleradorBe({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.aceleradorBe,
      builder: (context, valor, child) {
        return MostradorBarraVertical(
          titulo: 'MANETE BE',
          unidade: '%',
          corDestaque: Colors.white,
          valor: valor,
        );
      },
    );
  }
}