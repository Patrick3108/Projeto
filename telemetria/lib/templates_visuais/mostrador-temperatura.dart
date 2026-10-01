import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MostradorTemperatura extends StatelessWidget {
  final String titulo;
  final Color corDestaque;
  final bool isBb; 
  final double temperatura; // <- Valor recebido de fora

  const MostradorTemperatura({
    super.key,
    required this.titulo,
    required this.corDestaque,
    required this.isBb,
    required this.temperatura,
  });

  @override
  Widget build(BuildContext context) {
    double startAngle = isBb ? 125 : 305;
    double endAngle = isBb ? 235 : 415;
    bool isInversed = !isBb;

    return Container(
      width: double.infinity,
      height: 230, 
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), 
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 90,
            startAngle: startAngle, 
            endAngle: endAngle,   
            isInversed: isInversed,
            interval: 10,    
            showLabels: true,
            showTicks: true,
            minorTicksPerInterval: 0,
            labelsPosition: ElementsPosition.outside,
            ticksPosition: ElementsPosition.outside,
            radiusFactor: 1.08,
            axisLineStyle: const AxisLineStyle(thickness: 5),
            axisLabelStyle: const GaugeTextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.bold),
            ranges: <GaugeRange>[
              GaugeRange(startValue: 0, endValue: 45, color: Colors.blue, startWidth: 5, endWidth: 5),
              GaugeRange(startValue: 45, endValue: 60, color: Colors.green, startWidth: 5, endWidth: 5),
              GaugeRange(startValue: 60, endValue: 90, color: Colors.red, startWidth: 5, endWidth: 5),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: temperatura, 
                enableAnimation: true, 
                needleColor: corDestaque,
                needleLength: 0.55, 
              )
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  titulo, 
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white70),
                ), 
                angle: 90,
                positionFactor: 0.22, 
              ),
              GaugeAnnotation(
                widget: Text(
                  '${temperatura.toStringAsFixed(1)}°C', 
                  style: TextStyle(fontSize: 23.5, fontWeight: FontWeight.bold, color: corDestaque),
                ), 
                angle: 90,
                positionFactor: 0.45, 
              )
            ],
          ),
        ],
      ),
    );
  }
}