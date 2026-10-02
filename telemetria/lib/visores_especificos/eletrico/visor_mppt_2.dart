import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorMppt2 extends StatelessWidget {
  final TelemetriaController controller;
  const VisorMppt2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.tensaoMppt2, 
        controller.correnteMppt2,
        controller.potenciaMppt2
      ]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'MPPT 2',
          valorPrimario: '${controller.tensaoMppt2.value.toStringAsFixed(1)} V',
          valorSecundario: '${controller.correnteMppt2.value.toStringAsFixed(1)} A',
          valorTerciario: '${controller.potenciaMppt2.value.toStringAsFixed(0)} W',
          corDestaque: Colors.deepOrange,
        );
      },
    );
  }
}