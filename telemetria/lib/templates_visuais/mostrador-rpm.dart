import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MostradorRpm extends StatelessWidget {
  final String titulo;
  final Color corDestaque;
  final double rpm;        // <- Valor recebido de fora
  final double velocidade; // <- Valor recebido de fora

  const MostradorRpm({
    super.key,
    required this.titulo,
    required this.corDestaque,
    required this.rpm,
    required this.velocidade,
  });

  @override
  Widget build(BuildContext context) {
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
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 5,
                  interval: 0.5, 
                  showLabels: true,
                  showTicks: true,
                  minorTicksPerInterval: 1, 
                  labelsPosition: ElementsPosition.outside,
                  ticksPosition: ElementsPosition.outside,
                  radiusFactor: 1.24,
                  axisLineStyle: const AxisLineStyle(thickness: 5), 
                  axisLabelStyle: const GaugeTextStyle(fontSize: 21.0, color: Colors.white, fontWeight: FontWeight.bold),
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: rpm / 1000.0, 
                      enableAnimation: true, 
                      needleColor: corDestaque,
                      needleLength: 0.70, 
                    )
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titulo, 
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'x1000 RPM', 
                            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${velocidade.toStringAsFixed(1)} NÓS', 
                            style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${rpm.toStringAsFixed(0)} RPM', 
                            style: TextStyle(fontSize: 23.5, fontWeight: FontWeight.bold, color: corDestaque),
                          ),
                        ],
                      ), 
                      angle: 90,
                      positionFactor: 0.52, 
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}