import 'package:flutter/material.dart';

// O Mostrador digital pode receber valores de fontes globais ou ser integrado ao SocketCAN caso necessário
class MostradorDigital extends StatelessWidget {
  final String titulo;
  final double valor;
  final String unidade;
  final Color corDestaque;

  const MostradorDigital({
    super.key,
    required this.titulo,
    required this.valor,
    required this.unidade,
    required this.corDestaque,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 156, 
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), 
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(valor.toStringAsFixed(1), style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: corDestaque)),
                const SizedBox(height: 2),
                Text(unidade, style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Text(
              titulo, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}