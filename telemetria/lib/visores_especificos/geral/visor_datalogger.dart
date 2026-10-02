import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../dados_e_telemetria/telemetria_controller.dart';
import '../../dados_e_telemetria/uavcan_parser.dart';

class VisorDatalogger extends StatefulWidget {
  final TelemetriaController controller;

  const VisorDatalogger({super.key, required this.controller});

  @override
  State<VisorDatalogger> createState() => _VisorDataloggerState();
}

class _VisorDataloggerState extends State<VisorDatalogger> {
  final List<String> _logTerminal = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _canSubscription;

  bool _gravandoLog = false;
  File? _arquivoCompleto;
  File? _arquivoErros;
  int _contadorPartes = 1;
  String _pastaDestino = '';

  @override
  void initState() {
    super.initState();
    _canSubscription = widget.controller.canService.canFramesStream.listen((frame) {
      if (frame is String) {
        _processarNovoFrame(frame);
      }
    });
  }

  @override
  void dispose() {
    _canSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _processarNovoFrame(String frameBruto) {
    String horaAtual = DateTime.now().toString().substring(11, 23); 
    String linhaTerminal = "[$horaAtual] $frameBruto";

    setState(() {
      _logTerminal.add(linhaTerminal);
      if (_logTerminal.length > 150) {
        _logTerminal.removeAt(0); 
      }
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    if (_gravandoLog) {
      _gravarNoDisco(horaAtual, frameBruto);
    }
  }

  Future<void> _gravarNoDisco(String hora, String frameBruto) async {
    if (_arquivoCompleto == null || _arquivoErros == null) return;

    String linhaCsv = "$hora,$frameBruto\n";

    await _arquivoCompleto!.writeAsString(linhaCsv, mode: FileMode.append);

    var dadosDecodificados = UavcanParser.decodificarFrame(frameBruto);
    if (dadosDecodificados != null) {
      bool isErro = (
        (dadosDecodificados.subjectId == UavcanParser.idErroMppt1 ||
         dadosDecodificados.subjectId == UavcanParser.idErroMppt2 ||
         dadosDecodificados.subjectId == UavcanParser.idErroMotorBb ||
         dadosDecodificados.subjectId == UavcanParser.idErroMotorBe) 
         && dadosDecodificados.valor > 0 
      );

      if (isErro) {
        await _arquivoErros!.writeAsString(linhaCsv, mode: FileMode.append);
      }
    }

    int tamanho = await _arquivoCompleto!.length();
    if (tamanho > 2097152) { // 2 MB
      _rotacionarArquivos();
    }
  }

  void _alternarGravacao() async {
    if (_gravandoLog) {
      setState(() {
        _gravandoLog = false;
        _logTerminal.add("--- GRAVAÇÃO PARADA ---");
      });
    } else {
      _contadorPartes = 1;
      _pastaDestino = Directory.current.path; 
      await _criarNovosArquivos();
      
      setState(() {
        _gravandoLog = true;
        _logTerminal.add("--- INICIANDO GRAVAÇÃO EM: $_pastaDestino ---");
      });
    }
  }

  Future<void> _criarNovosArquivos() async {
    String timestamp = DateTime.now().toString().substring(0, 19).replaceAll(":", "-").replaceAll(" ", "_");
    
    _arquivoCompleto = File('$_pastaDestino/log_completo_${timestamp}_parte$_contadorPartes.csv');
    _arquivoErros = File('$_pastaDestino/log_erros_${timestamp}_parte$_contadorPartes.csv');

    await _arquivoCompleto!.writeAsString("Hora,Pacote_CAN\n");
    await _arquivoErros!.writeAsString("Hora,Pacote_CAN_Erro\n");
  }

  Future<void> _rotacionarArquivos() async {
    _contadorPartes++;
    setState(() {
      _logTerminal.add("--- LIMITE DE 2MB ATINGIDO. CRIANDO PARTE $_contadorPartes ---");
    });
    await _criarNovosArquivos();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _alternarGravacao,
                icon: Icon(_gravandoLog ? Icons.stop : Icons.fiber_manual_record, size: 28),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gravandoLog ? Colors.redAccent : Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                label: Text(
                  _gravandoLog ? "PARAR GRAVAÇÃO" : "INICIAR DATALOGGER (.CSV)",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 30),
              if (_gravandoLog)
                const Row(
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(width: 16),
                    Text(
                      "GRAVANDO DADOS...",
                      style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logTerminal.length,
              itemBuilder: (context, index) {
                return Text(
                  _logTerminal[index],
                  style: const TextStyle(
                    color: Colors.greenAccent, 
                    fontFamily: 'Courier', 
                    fontSize: 16,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}