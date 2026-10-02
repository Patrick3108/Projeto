import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// --- IMPORTS DA CAMADA DE DADOS ---
import 'dados_e_telemetria/can_network_service.dart';
import 'dados_e_telemetria/telemetria_controller.dart';

// --- IMPORTS DOS VISORES GERAIS ---
import 'visores_especificos/geral/visor_autonomia.dart';
import 'visores_especificos/geral/visor_datalogger.dart';

// --- IMPORTS DOS MOTORES ---
import 'visores_especificos/motores/visor_acelerador_bb.dart';
import 'visores_especificos/motores/visor_acelerador_be.dart';
import 'visores_especificos/motores/visor_rpm_bb.dart';
import 'visores_especificos/motores/visor_rpm_be.dart';
import 'visores_especificos/motores/visor_corrente_bb.dart';
import 'visores_especificos/motores/visor_corrente_be.dart';
import 'visores_especificos/motores/visor_temperaturas_bb.dart';
import 'visores_especificos/motores/visor_temperaturas_be.dart';
import 'visores_especificos/motores/visor_diagnostico_motores.dart';

// --- IMPORTS DO SISTEMA ELÉTRICO ---
import 'visores_especificos/eletrico/visor_string_1.dart';
import 'visores_especificos/eletrico/visor_string_2.dart';
import 'visores_especificos/eletrico/visor_string_3.dart';
import 'visores_especificos/eletrico/visor_corrente_total_strings.dart';
import 'visores_especificos/eletrico/visor_mppt_1.dart';
import 'visores_especificos/eletrico/visor_mppt_2.dart';
import 'visores_especificos/eletrico/visor_tensao_bateria_vertical.dart';
import 'visores_especificos/eletrico/visor_corrente_bateria_vertical.dart';
import 'visores_especificos/eletrico/visor_diagnostico_mppt.dart';

void main() {
  runApp(const PainelBimotorApp());
}

class PainelBimotorApp extends StatelessWidget {
  const PainelBimotorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telemetria Embarcação',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const PainelCockpit(),
    );
  }
}

class PainelCockpit extends StatefulWidget {
  const PainelCockpit({super.key});

  @override
  State<PainelCockpit> createState() => _PainelCockpitState();
}

class _PainelCockpitState extends State<PainelCockpit> {
  final PageController _pageController = PageController();
  int _paginaAtual = 0;
  
  late final CanNetworkService _canService;
  late final TelemetriaController _controller;

  @override
  void initState() {
    super.initState();
    _canService = CanNetworkService('can0'); 
    _controller = TelemetriaController(_canService);
    _controller.iniciar(); 
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.parar();
    super.dispose();
  }

  void _mudarPagina(int novaPagina) {
    _pageController.animateToPage(
      novaPagina,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 1024,
                    height: 600, 
                    child: Column(
                      children: [
                        // ==========================================
                        // TOPO FIXO
                        // ==========================================
                        Row(
                          children: [
                            const SizedBox(width: 80), 
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  VisorAutonomia(controller: _controller), 
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _paginaAtual == index ? Colors.cyanAccent : Colors.white24,
                                      ),
                                    )),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 80), 
                          ],
                        ),
                        const SizedBox(height: 2),

                        // ==========================================
                        // CORPO PRINCIPAL
                        // ==========================================
                        Expanded(
                          child: Row(
                            children: [
                              // BOTÃO ESQUERDO
                              SizedBox(
                                width: 80, height: double.infinity,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) {
                                    int alvo = _paginaAtual > 0 ? _paginaAtual - 1 : 4;
                                    _mudarPagina(alvo);
                                  },
                                  child: const Center(child: Icon(Icons.chevron_left, size: 56, color: Colors.cyanAccent)),
                                ),
                              ),

                              Expanded(
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (index) => setState(() => _paginaAtual = index),
                                  children: [
                                    // ==========================================
                                    // ECRÃ 1: MOTORES & ESTADO DA BATERIA
                                    // ==========================================
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(flex: 5, child: VisorAceleradorBb(controller: _controller)),
                                              const SizedBox(width: 4),
                                              Expanded(flex: 20, child: VisorRpmBb(controller: _controller)),
                                              const SizedBox(width: 4),
                                              Expanded(flex: 20, child: VisorRpmBe(controller: _controller)),
                                              const SizedBox(width: 4),
                                              Expanded(flex: 5, child: VisorAceleradorBe(controller: _controller)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Expanded(flex: 5, child: VisorCorrenteBb(controller: _controller)),
                                              const SizedBox(width: 4),
                                              Expanded(flex: 20, child: VisorTensaoBateriaVertical(controller: _controller)),
                                              const SizedBox(width: 4),
                                              Expanded(flex: 20, child: VisorCorrenteBateriaVertical(controller: _controller)),
                                              const SizedBox(width: 4),
                                              Expanded(flex: 5, child: VisorCorrenteBe(controller: _controller)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ==========================================
                                    // ECRÃ 2: GERAÇÃO SOLAR & TÉRMICAS
                                    // ==========================================
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          const Text('SISTEMA ELÉTRICO E TÉRMICAS', style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                          const SizedBox(height: 8),
                                          
                                          Expanded(
                                            child: FittedBox(
                                              fit: BoxFit.contain,
                                              alignment: Alignment.topCenter,
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 420,
                                                    child: Column(
                                                      children: [
                                                        VisorString1(controller: _controller),
                                                        const SizedBox(height: 16),
                                                        VisorString2(controller: _controller),
                                                        const SizedBox(height: 16),
                                                        VisorString3(controller: _controller),
                                                        const SizedBox(height: 16),
                                                        VisorCorrenteTotalStrings(controller: _controller),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 32),
                                                  SizedBox(
                                                    width: 420,
                                                    child: Column(
                                                      children: [
                                                        VisorMppt1(controller: _controller),
                                                        const SizedBox(height: 16),
                                                        VisorMppt2(controller: _controller),
                                                        const SizedBox(height: 16),
                                                        VisorTemperaturasBb(controller: _controller),
                                                        const SizedBox(height: 16),
                                                        VisorTemperaturasBe(controller: _controller),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // ==========================================
                                    // ECRÃ 3: DIAGNÓSTICO MPPTs
                                    // ==========================================
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: VisorDiagnosticoMppt(controller: _controller),
                                    ),

                                    // ==========================================
                                    // ECRÃ 4: DIAGNÓSTICO MOTORES
                                    // ==========================================
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: VisorDiagnosticoMotores(controller: _controller),
                                    ),

                                    // ==========================================
                                    // ECRÃ 5: DATALOGGER E REDE CAN
                                    // ==========================================
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: VisorDatalogger(controller: _controller),
                                    ),
                                  ],
                                ),
                              ),

                              // BOTÃO DIREITO
                              SizedBox(
                                width: 80, height: double.infinity,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) {
                                    int alvo = _paginaAtual < 4 ? _paginaAtual + 1 : 0;
                                    _mudarPagina(alvo);
                                  },
                                  child: const Center(child: Icon(Icons.chevron_right, size: 56, color: Colors.cyanAccent)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}