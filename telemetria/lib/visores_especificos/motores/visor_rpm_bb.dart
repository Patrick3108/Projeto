import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-rpm.dart';

class VisorRpmBb extends StatelessWidget {
  final TelemetriaController controller;

  const VisorRpmBb({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // É AQUI QUE A MÁGICA ACONTECE!
    // O ValueListenableBuilder "abraça" o seu mostrador e fica a vigiar a variável rpmBb.
    return ValueListenableBuilder<double>(
      valueListenable: controller.rpmBb, 
      builder: (context, valorRpm, child) {
        
        // Sempre que o CAN Bus atualizar o 'rpmBb' no Controller,
        // o Flutter entra aqui automaticamente e redesenha o mostrador com o novo valor.
        return MostradorRpm(
          titulo: 'BOMBORDO',
          corDestaque: Colors.greenAccent, 
          rpm: valorRpm, // <- O ponteiro recebe a injeção do valor ao vivo
          velocidade: controller.velocidade.value, 
        );
        
      },
    );
  }
}