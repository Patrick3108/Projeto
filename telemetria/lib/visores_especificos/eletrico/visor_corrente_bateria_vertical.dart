import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../templates_visuais/mostrador-barra-vertical.dart';

class VisorCorrenteBateriaVertical extends StatelessWidget {
  final TelemetriaController controller;

  const VisorCorrenteBateriaVertical({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.correnteBateria,
      builder: (context, valorReal, child) {
        
        bool isCarregando = valorReal < -0.1; // Se a corrente for negativa
        double valorAbsoluto = valorReal.abs(); // O gráfico da barra exige números positivos

        return MostradorBarraVertical(
          titulo: isCarregando ? 'CARGA BATERIA' : 'USO BATERIA',
          unidade: 'A',
          corDestaque: isCarregando ? Colors.greenAccent : Colors.orangeAccent,
          valor: valorAbsoluto, // Passamos o valor sem o sinal para preencher a barra
        );
      },
    );
  }
}