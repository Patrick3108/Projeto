import 'package:flutter/material.dart';

class MostradorBarraVertical extends StatelessWidget {
  final String titulo;
  final String unidade;
  final Color corDestaque;
  final double valor; // <- Agora ele recebe o valor de fora

  const MostradorBarraVertical({
    super.key,
    required this.titulo,
    required this.unidade,
    required this.corDestaque,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    // Definindo limites genéricos para barras verticais (Manetes / Correntes)
    double min = 0;
    double max = unidade == '%' ? 100.0 : 150.0;
    double percentual = ((valor - min) / (max - min)).clamp(0.0, 1.0);
    
    return Container(
      width: double.infinity,
      height: 230, 
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
                SizedBox(
                  width: 34.0,
                  height: 122.0, 
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentual,
                        backgroundColor: Colors.grey[800],
                        color: corDestaque,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${valor.toStringAsFixed(0)} $unidade',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: corDestaque),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Text(
              titulo, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}