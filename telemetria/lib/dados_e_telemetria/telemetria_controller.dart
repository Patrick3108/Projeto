import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:typed_data'; 
// Importação absoluta apontando para a raiz lib/
import 'package:telemetria/gps_state.dart'; 

import 'can_network_service.dart';
import 'uavcan_parser.dart';

class TelemetriaController {
  final CanNetworkService canService;

  // === TELA 1: MOTORES ===
  final ValueNotifier<double> rpmBb = ValueNotifier(0.0);
  final ValueNotifier<double> rpmBe = ValueNotifier(0.0);
  final ValueNotifier<double> aceleradorBb = ValueNotifier(0.0);
  final ValueNotifier<double> aceleradorBe = ValueNotifier(0.0);
  final ValueNotifier<double> tempBb = ValueNotifier(0.0);
  final ValueNotifier<double> tempBe = ValueNotifier(0.0);
  final ValueNotifier<double> tempEscBb = ValueNotifier(0.0);
  final ValueNotifier<double> tempEscBe = ValueNotifier(0.0);
  final ValueNotifier<double> correnteBb = ValueNotifier(0.0);
  final ValueNotifier<double> correnteBe = ValueNotifier(0.0);
  final ValueNotifier<double> velocidade = ValueNotifier(0.0);

  // === TELA 2: SISTEMA ELÉTRICO ===
  final ValueNotifier<double> tensaoBateria = ValueNotifier(0.0);
  final ValueNotifier<double> correnteBateria = ValueNotifier(0.0);
  final ValueNotifier<double> tensaoString1 = ValueNotifier(0.0);
  final ValueNotifier<double> correnteString1 = ValueNotifier(0.0);
  final ValueNotifier<double> tensaoString2 = ValueNotifier(0.0);
  final ValueNotifier<double> correnteString2 = ValueNotifier(0.0);
  final ValueNotifier<double> tensaoString3 = ValueNotifier(0.0);
  final ValueNotifier<double> correnteString3 = ValueNotifier(0.0);
  final ValueNotifier<double> correnteTotalStrings = ValueNotifier(0.0);
  final ValueNotifier<double> tensaoMppt1 = ValueNotifier(0.0);
  final ValueNotifier<double> correnteMppt1 = ValueNotifier(0.0);
  final ValueNotifier<double> tensaoMppt2 = ValueNotifier(0.0);
  final ValueNotifier<double> correnteMppt2 = ValueNotifier(0.0);
  final ValueNotifier<double> potenciaMppt1 = ValueNotifier(0.0);
  final ValueNotifier<double> potenciaMppt2 = ValueNotifier(0.0);

  // === TELA 3: DIAGNÓSTICO MPPT ===
  final ValueNotifier<int> estadoMppt1 = ValueNotifier(0);
  final ValueNotifier<int> erroMppt1 = ValueNotifier(0);
  final ValueNotifier<int> estadoMppt2 = ValueNotifier(0);
  final ValueNotifier<int> erroMppt2 = ValueNotifier(0);

  // === TELA 4: DIAGNÓSTICO MOTORES ===
  final ValueNotifier<int> erroMotorBb = ValueNotifier(0);
  final ValueNotifier<int> erroMotorBe = ValueNotifier(0);

  TelemetriaController(this.canService) {
    _ouvirRedeCan();
  }

  void iniciar() async {
    await _animacaoDePartida();
    canService.conectar();
  }

  void parar() => canService.desconectar();

  Future<void> _animacaoDePartida() async {
    int passos = 25;
    int tempoPasso = 50; 

    for (int i = 0; i <= passos; i++) {
      _aplicarValoresAnimacao(i / passos);
      await Future.delayed(Duration(milliseconds: tempoPasso));
    }
    for (int i = passos; i >= 0; i--) {
      _aplicarValoresAnimacao(i / passos);
      await Future.delayed(Duration(milliseconds: tempoPasso));
    }
    
    _aplicarValoresAnimacao(0.0);
  }

  void _aplicarValoresAnimacao(double fator) {
    rpmBb.value = 5000.0 * fator;
    rpmBe.value = 5000.0 * fator;
    aceleradorBb.value = 100.0 * fator;
    aceleradorBe.value = 100.0 * fator;
    correnteBb.value = 80.0 * fator;
    correnteBe.value = 80.0 * fator;
    tempBb.value = 0.0 + (110.0 * fator); 
    tempBe.value = 0.0 + (110.0 * fator);
    tempEscBb.value = 0.0 + (110.0 * fator);
    tempEscBe.value = 0.0 + (110.0 * fator);
    
    tensaoBateria.value = 40.0 + (18.0 * fator); 
    correnteBateria.value = 130.0 * fator;
  }

  void _ouvirRedeCan() {
    canService.canFramesStream.listen((framebruto) {
      if (framebruto is! String) return;

      UavcanData? dados = UavcanParser.decodificarFrame(framebruto);
      if (dados != null) {
        _distribuirDadosUavcan(dados);
      }

      _processarGpsDireto(framebruto);
    });
  }

  void _processarGpsDireto(String framebruto) {
    try {
      final regex = RegExp(r'(?:[a-zA-Z0-9]+)?\s*([0-9A-Fa-f]{7,8})[\s#]+(?:\[\d+\]\s*)?([0-9A-Fa-f\s]+)');
      final match = regex.firstMatch(framebruto);
      
      if (match != null) {
        int canId = int.parse(match.group(1)!, radix: 16);
        String hexData = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
        
        List<int> payload = [];
        for (int i = 0; i < hexData.length; i += 2) {
          payload.add(int.parse(hexData.substring(i, i + 2), radix: 16));
        }

        int subjectId = (canId >> 8) & 0x1FFF;

        if (subjectId == 4001 || subjectId == 4002 || subjectId == 4003) {
          if (payload.length >= 4) {
            Uint8List bytes = Uint8List.fromList(payload.sublist(0, 4));
            ByteData byteData = ByteData.sublistView(bytes);
            double valorFloat = byteData.getFloat32(0, Endian.little);

            if (subjectId == 4001) {
              gpsState.latitude.value = valorFloat;
            } else if (subjectId == 4002) {
              gpsState.longitude.value = valorFloat;
            } else if (subjectId == 4003 && payload.length >= 5) {
              gpsState.speed.value = valorFloat;
              gpsState.satellites.value = payload[4]; 
            }
          }
        }
      }
    } catch (e) {
      // Ignora falhas silenciosamente
    }
  }

  void _distribuirDadosUavcan(UavcanData dados) {
    switch (dados.subjectId) {
      case UavcanParser.idRpmBb: rpmBb.value = dados.valor; break;
      case UavcanParser.idCorrenteBb: correnteBb.value = dados.valor; break;
      case UavcanParser.idTempBb: tempBb.value = dados.valor; break;
      case UavcanParser.idTempEscBb: tempEscBb.value = dados.valor; break;
      case UavcanParser.idAceleradorBb: aceleradorBb.value = dados.valor; break;
      case UavcanParser.idErroMotorBb: erroMotorBb.value = dados.valor.toInt(); break;
      
      case UavcanParser.idRpmBe: rpmBe.value = dados.valor; break;
      case UavcanParser.idCorrenteBe: correnteBe.value = dados.valor; break;
      case UavcanParser.idTempBe: tempBe.value = dados.valor; break;
      case UavcanParser.idTempEscBe: tempEscBe.value = dados.valor; break;
      case UavcanParser.idAceleradorBe: aceleradorBe.value = dados.valor; break;
      case UavcanParser.idErroMotorBe: erroMotorBe.value = dados.valor.toInt(); break;

      case UavcanParser.idTensaoBateria: tensaoBateria.value = dados.valor; break;
      case UavcanParser.idCorrenteBateria: correnteBateria.value = dados.valor; break;
      
      case UavcanParser.idTensaoMppt1: tensaoMppt1.value = dados.valor; break;
      case UavcanParser.idCorrenteMppt1: correnteMppt1.value = dados.valor; break;
      case UavcanParser.idPotenciaMppt1: potenciaMppt1.value = dados.valor; break;
      case UavcanParser.idEstadoMppt1: estadoMppt1.value = dados.valor.toInt(); break;
      case UavcanParser.idErroMppt1: erroMppt1.value = dados.valor.toInt(); break;

      case UavcanParser.idTensaoMppt2: tensaoMppt2.value = dados.valor; break;
      case UavcanParser.idCorrenteMppt2: correnteMppt2.value = dados.valor; break;
      case UavcanParser.idPotenciaMppt2: potenciaMppt2.value = dados.valor; break;
      case UavcanParser.idEstadoMppt2: estadoMppt2.value = dados.valor.toInt(); break;
      case UavcanParser.idErroMppt2: erroMppt2.value = dados.valor.toInt(); break;
    }
  }
}