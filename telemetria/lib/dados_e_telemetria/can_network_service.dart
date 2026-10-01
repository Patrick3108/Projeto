import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CanNetworkService {
  final String interfaceName;
  final StreamController<dynamic> _frameController = StreamController.broadcast();
  Process? _candumpProcess;

  CanNetworkService(this.interfaceName);

  Stream<dynamic> get canFramesStream => _frameController.stream;

  void conectar() async {
    debugPrint("Iniciando ponte com o Linux (candump) na interface: $interfaceName");
    try {
      // Inicia o candump como um processo "invisível" no Linux
      _candumpProcess = await Process.start('candump', [interfaceName]);

      // Escuta tudo o que a rede CAN capturar em tempo real
      _candumpProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String linha) {
        
        // GRITA na tela assim que o dado chegar do barramento!
        debugPrint("CHEGOU DADO: $linha");
        
        // Envia o dado para os visores do painel
        _frameController.add(linha);
      });

      _candumpProcess!.stderr.transform(utf8.decoder).listen((String erro) {
        debugPrint("Erro no barramento: $erro");
      });

    } catch (e) {
      debugPrint("Erro ao tentar ler o barramento CAN: $e");
    }
  }

  void desconectar() {
    _candumpProcess?.kill();
    _frameController.close();
  }

  // Método auxiliar para injetar dados falsos
  void simularRecebimento(dynamic frameFalso) {
    _frameController.add(frameFalso);
  }
}

void debugPrint(String msg) => print("[CAN] $msg");