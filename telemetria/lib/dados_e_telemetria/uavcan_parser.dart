import 'dart:typed_data';

class UavcanData {
  final int subjectId;
  final double valor;

  UavcanData({
    required this.subjectId,
    required this.valor,
  });
}

class UavcanParser {// ==============================================================
  // Subject IDs - Energia
  // ==============================================================
  static const int idTensaoBateria = 100;
  static const int idCorrenteBateria = 101;
  
  static const int idTensaoMppt1 = 200;
  static const int idCorrenteMppt1 = 201;
  static const int idPotenciaMppt1 = 204; 
  static const int idEstadoMppt1 = 206; 
  static const int idErroMppt1 = 207;
  
  static const int idTensaoMppt2 = 202; 
  static const int idCorrenteMppt2 = 203; 
  static const int idPotenciaMppt2 = 205;
  static const int idEstadoMppt2 = 208;
  static const int idErroMppt2 = 209;

  // ==============================================================
  // Subject IDs - Motores
  // ==============================================================
  static const int idRpmBb = 300;
  static const int idCorrenteBb = 301;
  static const int idTempBb = 302;
  static const int idAceleradorBb = 303;
  static const int idTempEscBb = 304;
  static const int idErroMotorBb = 305; // <-- NOVO

  static const int idRpmBe = 310;
  static const int idCorrenteBe = 311;
  static const int idTempBe = 312;
  static const int idAceleradorBe = 313;
  static const int idTempEscBe = 314;
  static const int idErroMotorBe = 315; // <-- NOVO

  static UavcanData? decodificarFrame(dynamic framebruto) {
    if (framebruto is! String) return null;

    try {
      List<String> partes = framebruto.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
      if (partes.length < 4) return null;

      String idHex = partes[1].toUpperCase();
      if (idHex.length != 8) return null; // Exige ID Estendido do UAVCAN

      int canId = int.parse(idHex, radix: 16);
      int subjectId = (canId >> 7) & 0x1FFF;

      List<String> payloadHex = partes.sublist(3);
      
      // O padrão que usaremos (Float32) ocupa exatamente 4 bytes
      if (payloadHex.length >= 4) {
        int byte0 = int.parse(payloadHex[0], radix: 16);
        int byte1 = int.parse(payloadHex[1], radix: 16);
        int byte2 = int.parse(payloadHex[2], radix: 16);
        int byte3 = int.parse(payloadHex[3], radix: 16);

        // Traduz os 4 bytes brutos para um número com vírgula real (IEEE 754)
        var bytes = Uint8List.fromList([byte0, byte1, byte2, byte3]);
        var byteData = ByteData.view(bytes.buffer);
        double valorFinal = byteData.getFloat32(0, Endian.little);

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