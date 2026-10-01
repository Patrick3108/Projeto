// Estrutura limpa para transportar os dados do motor
class GoldenMotorData {
  final String motor; // "BB" (Bombordo) ou "BE" (Boreste)
  final double? rpm;
  final double? corrente;
  final double? temperatura;

  GoldenMotorData({
    required this.motor,
    this.rpm,
    this.corrente,
    this.temperatura,
  });
}

class GoldenMotorParser {
  static GoldenMotorData? decodificarFrame(dynamic framebruto) {
    if (framebruto is! String) return null;

    try {
      List<String> partes = framebruto.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
      if (partes.length < 4) return null;

      String idHex = partes[1].toUpperCase();
      List<String> payloadHex = partes.sublist(3);

      // Ignora pacotes de erro ou o "0x55" de handshake
      if (payloadHex.length < 8 || payloadHex[0] == "55") return null;

      // ==============================================================
      // MENSAGEM I - RPM e Corrente (ID: 1801D0EF e 1801F0EF)
      // ==============================================================
      if (idHex == "1801D0EF" || idHex == "1801F0EF") {
        String motor = (idHex == "1801D0EF") ? "BB" : "BE";

        int b2 = int.parse(payloadHex[2], radix: 16);
        int b3 = int.parse(payloadHex[3], radix: 16);
        double correnteCalc = (((b3 << 8) | b2) * 0.1) - 3200.0;

        int b6 = int.parse(payloadHex[6], radix: 16);
        int b7 = int.parse(payloadHex[7], radix: 16);
        double rpmCalc = (((b7 << 8) | b6) * 1.0) - 32000.0;

        return GoldenMotorData(
          motor: motor,
          rpm: rpmCalc,
          corrente: correnteCalc,
        );
      }

      // ==============================================================
      // MENSAGEM II - Temperatura (ID: 1802D0EF e 1802F0EF)
      // ==============================================================
      if (idHex == "1802D0EF" || idHex == "1802F0EF") {
        String motor = (idHex == "1802D0EF") ? "BB" : "BE";

        int b1 = int.parse(payloadHex[1], radix: 16);
        double tempCalc = b1 - 40.0;

        return GoldenMotorData(
          motor: motor,
          temperatura: tempCalc,
        );
      }
    } catch (e) {
      // Ignora lixo na rede silenciosamente
    }
    return null;
  }
}