import 'package:flutter/material.dart';

class MostradorLinha extends StatelessWidget {
  final String titulo;
  final String valorPrimario;
  final String? valorSecundario; // Opcional (usado para Corrente, caso haja Tensão)
  final Color corDestaque;

  const MostradorLinha({
    super.key,
    required this.titulo,
    required this.valorPrimario,
    this.valorSecundario,
    required this.corDestaque,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: corDestaque, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 20.0, color: Colors.grey, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(valorPrimario, style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: corDestaque)),
              if (valorSecundario != null) ...[
                const SizedBox(width: 16),
                const Text("|", style: TextStyle(fontSize: 28.0, color: Colors.white24)),
                const SizedBox(width: 16),
                Text(valorSecundario!, style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: corDestaque)),
              ]
            ],
          ),
        ],
      ),
    );
  }
}