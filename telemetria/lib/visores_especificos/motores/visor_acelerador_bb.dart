import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-barra-vertical.dart';

class VisorAceleradorBb extends StatelessWidget {
  final TelemetriaController controller;

  const VisorAceleradorBb({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.aceleradorBb,
      builder: (context, valor, child) {
        return MostradorBarraVertical(
          titulo: 'MANETE BB',
          unidade: '%',
          corDestaque: Colors.white,
          valor: valor,
        );
      },
    );
  }
}