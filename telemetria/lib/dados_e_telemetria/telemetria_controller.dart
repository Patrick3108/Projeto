import 'package:flutter/foundation.dart';
import 'dart:async';
import 'can_network_service.dart';
import 'uavcan_parser.dart';

class TelemetriaController {
  // Tornamos o serviço público (sem o "_") para o Datalogger poder escutar
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
    });
  }

  void _distribuirDadosUavcan(UavcanData dados) {
    switch (dados.subjectId) {
      // MOTORES
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

      // ELÉTRICO & DIAGNÓSTICO MPPT
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