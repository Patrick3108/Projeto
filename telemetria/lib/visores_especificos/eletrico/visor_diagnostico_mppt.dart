import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';

class VisorDiagnosticoMppt extends StatelessWidget {
  final TelemetriaController controller;

  const VisorDiagnosticoMppt({super.key, required this.controller});

  // --- DICIONÁRIO DE ESTADOS DO VICTRON ---
  String _traduzirEstado(int codigo) {
    switch (codigo) {
      case 0: return "DESLIGADO (S/ Tensão Solar)";
      case 3: return "BULK (Carga Bruta)";
      case 4: return "ABSORPTION (Absorção)";
      case 5: return "FLOAT (Flutuação)";
      default: return "CÓD. DESCONHECIDO ($codigo)";
    }
  }

  // --- DICIONÁRIO DE ERROS DO VICTRON ---
  String _traduzirErro(int codigo) {
    if (codigo == 0) return "SISTEMA OK";
    
    switch (codigo) {
      case 2: return "SOBRETENSÃO BATERIA (Overvoltage)";
      case 17: return "SUPERAQUECIMENTO (Overtemperature)";
      case 21: return "FALHA SENSOR DE CORRENTE";
      case 26: return "TERMINAIS INVERTIDOS";
      case 33: return "SOBRETENSÃO SOLAR (PV Overvoltage)";
      default: return "FALHA CRÍTICA (Cód: $codigo)";
    }
  }

  Widget _construirPainelMppt(String titulo, int estado, int erro) {
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
            
            // ESTADO DE OPERAÇÃO
            const Text("MODO DE OPERAÇÃO", style: TextStyle(fontSize: 16.0, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _traduzirEstado(estado),
              style: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // DIAGNÓSTICO E CÓDIGOS DE ERRO
            const Text("DIAGNÓSTICO ATUAL", style: TextStyle(fontSize: 16.0, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _traduzirErro(erro),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: emAlerta ? 32.0 : 28.0, 
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
        controller.estadoMppt1,
        controller.erroMppt1,
        controller.estadoMppt2,
        controller.erroMppt2,
      ]),
      builder: (context, child) {
        return Column(
          children: [
            const Text(
              'DIAGNÓSTICO DE CONTROLADORES MPPT', 
              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: Colors.blueAccent)
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _construirPainelMppt(
                    "MPPT 1 (2S1P Rígido)", 
                    controller.estadoMppt1.value, 
                    controller.erroMppt1.value
                  ),
                  _construirPainelMppt(
                    "MPPT 2 (7S2P Flexível)", 
                    controller.estadoMppt2.value, 
                    controller.erroMppt2.value
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