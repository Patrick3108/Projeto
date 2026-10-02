import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';

class VisorDiagnosticoMotores extends StatelessWidget {
  final TelemetriaController controller;

  const VisorDiagnosticoMotores({super.key, required this.controller});

  // --- DICIONÁRIO DE ERROS EZKONTROL / GOLDEN MOTOR ---
  String _traduzirErro(int codigo) {
    if (codigo == 0) return "SISTEMA OK";
    
    switch (codigo) {
      case 1: return "FALHA SENSOR HALL";
      case 2: return "FALHA NO ACELERADOR (Manete)";
      case 3: return "SOBRETENSÃO (Overvoltage)";
      case 4: return "TENSÃO BAIXA (Undervoltage)";
      case 5: return "MOTOR BLOQUEADO (Stall/Jam)";
      case 6: return "SUPERAQUECIMENTO ESC";
      case 7: return "SUPERAQUECIMENTO MOTOR";
      case 8: return "SOBRECORRENTE (Overcurrent)";
      case 14: return "FALHA COMUNICAÇÃO CAN";
      default: return "FALHA DESCONHECIDA (Cód: $codigo)";
    }
  }

  Widget _construirPainelMotor(String titulo, int erro) {
    bool emAlerta = erro != 0;
    Color corPrincipal = emAlerta ? Colors.redAccent : Colors.greenAccent;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corPrincipal, width: emAlerta ? 4 : 1),
          boxShadow: emAlerta 
              ? [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)] 
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: Colors.white24, thickness: 2),
            ),
            
            const SizedBox(height: 20),
            
            // ESTADO GERAL DO CONTROLADOR
            Icon(
              emAlerta ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: corPrincipal,
              size: 72,
            ),
            
            const SizedBox(height: 30),
            
            // DIAGNÓSTICO E CÓDIGOS DE ERRO
            const Text("ESTADO DO EZKONTROL", style: TextStyle(fontSize: 16.0, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              _traduzirErro(erro),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: emAlerta ? 30.0 : 28.0, 
                fontWeight: FontWeight.bold, 
                color: corPrincipal
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.erroMotorBb,
        controller.erroMotorBe,
      ]),
      builder: (context, child) {
        return Column(
          children: [
            const Text(
              'DIAGNÓSTICO DE MOTORES (EZKONTROL)', 
              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: Colors.cyanAccent)
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _construirPainelMotor(
                    "MOTOR BOMBORDO (BB)", 
                    controller.erroMotorBb.value
                  ),
                  _construirPainelMotor(
                    "MOTOR BORESTE (BE)", 
                    controller.erroMotorBe.value
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}