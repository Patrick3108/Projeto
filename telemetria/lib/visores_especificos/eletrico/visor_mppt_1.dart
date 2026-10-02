import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-linha.dart';

class VisorMppt1 extends StatelessWidget {
  final TelemetriaController controller;
  const VisorMppt1({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Adicionamos a potência à lista de escuta para atualizar a interface ao mesmo tempo
      animation: Listenable.merge([
        controller.tensaoMppt1, 
        controller.correnteMppt1,
        controller.potenciaMppt1
      ]),
      builder: (context, child) {
        return MostradorLinha(
          titulo: 'MPPT 1',
          valorPrimario: '${controller.tensaoMppt1.value.toStringAsFixed(1)} V',
          valorSecundario: '${controller.correnteMppt1.value.toStringAsFixed(1)} A',
          valorTerciario: '${controller.potenciaMppt1.value.toStringAsFixed(0)} W', // Injeção dos Watts
          corDestaque: Colors.deepOrange,
        );
      },
    );
  }
}