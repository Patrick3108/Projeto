import 'package:flutter/material.dart';

class GpsState {
  static final GpsState instance = GpsState._internal();
  GpsState._internal();

  // Coordenadas iniciais em Niterói
  final ValueNotifier<double> latitude = ValueNotifier(-22.905255);
  final ValueNotifier<double> longitude = ValueNotifier(-43.131685);
  final ValueNotifier<double> speed = ValueNotifier(0.0);
  final ValueNotifier<int> satellites = ValueNotifier(0);
}

final gpsState = GpsState.instance;