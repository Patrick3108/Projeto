import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';

class VisorAutonomia extends StatelessWidget {
  final TelemetriaController controller;
  final double capacidadeBateriaAh = 40.0; // Ajuste para a capacidade real do barco

  const VisorAutonomia({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.correnteBateria,
      builder: (context, correnteBateria, child) {
        String textoAutonomia = "--h --m";
        Color corStatus = Colors.greenAccent;
        
        // Remove pequenas flutuações e ruídos perto do 0 absoluto
        double correnteAbs = correnteBateria.abs();

        if (correnteAbs > 0.5) {
          double horasRestantes = capacidadeBateriaAh / correnteAbs;
          int horas = horasRestantes.floor();
          int minutos = ((horasRestantes - horas) * 60).round();
          
          if (correnteBateria < 0) {
            // Se negativo, o sistema solar está a injetar mais do que o barco gasta
            textoAutonomia = "+${horas}h ${minutos}m"; 
            corStatus = Colors.blueAccent;
          } else {
            // Consumo normal
            textoAutonomia = "${horas}h ${minutos}m";
            if (horasRestantes < 0.5) corStatus = Colors.redAccent; 
            else if (horasRestantes < 1.0) corStatus = Colors.orangeAccent;
          }
        } else {
          // Barco parado ou painel solar a empatar com o consumo (zero a zero)
          textoAutonomia = "STDBY";
          corStatus = Colors.grey;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: corStatus, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("AUTONOMIA LiFePO4: ", style: TextStyle(fontSize: 22.0, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(textoAutonomia, style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: corStatus)),
            ],
          ),
        );
      },
    );
  }
}