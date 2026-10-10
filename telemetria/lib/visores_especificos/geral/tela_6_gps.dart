import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Importação absoluta apontando para a raiz lib/
import 'package:telemetria/gps_state.dart';

class Tela6GPS extends StatefulWidget {
  const Tela6GPS({super.key});

  @override
  State<Tela6GPS> createState() => _Tela6GPSState();
}

class _Tela6GPSState extends State<Tela6GPS> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    gpsState.latitude.addListener(_atualizarMapa);
    gpsState.longitude.addListener(_atualizarMapa);
  }

  @override
  void dispose() {
    gpsState.latitude.removeListener(_atualizarMapa);
    gpsState.longitude.removeListener(_atualizarMapa);
    super.dispose();
  }

  void _atualizarMapa() {
    _mapController.move(
      LatLng(gpsState.latitude.value, gpsState.longitude.value), 
      16.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: gpsState.latitude,
            builder: (context, lat, child) {
              return ValueListenableBuilder<double>(
                valueListenable: gpsState.longitude,
                builder: (context, lon, child) {
                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(lat, lon),
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.desafiosolar.painel',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lon),
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.navigation, color: Colors.red, size: 50),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: gpsState.speed,
                    builder: (context, vel, child) {
                      return Text(
                        "${vel.toStringAsFixed(1)} km/h",
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: gpsState.satellites,
                    builder: (context, sats, child) {
                      return Text(
                        "Satélites: $sats",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}