class UavcanData {
  final int subjectId;
  final double valor;

  UavcanData({
    required this.subjectId,
    required this.valor,
  });
}

class UavcanParser {
  // ==============================================================
  // Subject IDs - Energia
  // ==============================================================
  static const int idTensaoBateria = 100;
  static const int idCorrenteBateria = 101;
  static const int idTensaoMppt1 = 200;
  static const int idCorrenteMppt1 = 201;

  // ==============================================================
  // Subject IDs - Motores (Traduzidos pelo ESP32)
  // ==============================================================
  static const int idRpmBb = 300;
  static const int idCorrenteBb = 301;
  static const int idTempBb = 302;
  static const int idAceleradorBb = 303;
  static const int idTempEscBb = 304;


  static const int idRpmBe = 310;
  static const int idCorrenteBe = 311;
  static const int idTempBe = 312;
  static const int idAceleradorBe = 313;
  static const int idTempEscBe = 314;
  static UavcanData? decodificarFrame(dynamic framebruto) {
    if (framebruto is! String) return null;

    try {
      List<String> partes = framebruto.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
      if (partes.length < 4) return null;

      String idHex = partes[1].toUpperCase();
      
      // O UAVCAN utiliza exclusivamente IDs Estendidos (29 bits), com 8 caracteres em hexadecimal.
      if (idHex.length != 8) return null; 

      int canId = int.parse(idHex, radix: 16);

      // Extração do Subject ID (UAVCAN v1 / Cyphal)
      int subjectId = (canId >> 7) & 0x1FFF;

      List<String> payloadHex = partes.sublist(3);
      if (payloadHex.length >= 2) {
        
        // UAVCAN lê em Little Endian. 
        // Certifique-se que o código C++ do ESP32 envia os dados neste formato de 16 bits.
        int byte0 = int.parse(payloadHex[0], radix: 16);
        int byte1 = int.parse(payloadHex[1], radix: 16);

        // Se no ESP32 existirem valores negativos (ex: corrente de regeneração), 
        // precisará de tratar o valorBruto como Int16 com sinal.
        int valorBruto = (byte1 << 8) | byte0;
        
        // Aplique divisões caso o ESP32 envie o valor multiplicado (ex: 125 RPM = 1250)
        double valorFinal = valorBruto.toDouble();

        return UavcanData(
          subjectId: subjectId,
          valor: valorFinal,
        );
      }
    } catch (e) {
      // Ignora lixo na rede
    }
    return null;
  }
}