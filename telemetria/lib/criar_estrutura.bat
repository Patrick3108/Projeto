@echo off
echo Criando estrutura de pastas dentro de lib...

mkdir lib\dados_e_telemetria
mkdir lib\templates_visuais
mkdir lib\visores_especificos\motores
mkdir lib\visores_especificos\eletrico
mkdir lib\visores_especificos\geral

echo Criando arquivos em dados_e_telemetria...
type nul > lib\dados_e_telemetria\telemetria_controller.dart
type nul > lib\dados_e_telemetria\can_network_service.dart
type nul > lib\dados_e_telemetria\uavcan_parser.dart

echo Criando arquivos em visores_especificos/motores...
type nul > lib\visores_especificos\motores\visor_rpm_bb.dart
type nul > lib\visores_especificos\motores\visor_rpm_be.dart
type nul > lib\visores_especificos\motores\visor_acelerador_bb.dart
type nul > lib\visores_especificos\motores\visor_acelerador_be.dart
type nul > lib\visores_especificos\motores\visor_temperatura_bb.dart
type nul > lib\visores_especificos\motores\visor_temperatura_be.dart
type nul > lib\visores_especificos\motores\visor_corrente_bb.dart
type nul > lib\visores_especificos\motores\visor_corrente_be.dart

echo Criando arquivos em visores_especificos/eletrico...
type nul > lib\visores_especificos\eletrico\visor_string_1.dart
type nul > lib\visores_especificos\eletrico\visor_string_2.dart
type nul > lib\visores_especificos\eletrico\visor_string_3.dart
type nul > lib\visores_especificos\eletrico\visor_corrente_total_strings.dart
type nul > lib\visores_especificos\eletrico\visor_bateria.dart
type nul > lib\visores_especificos\eletrico\visor_mppt_1.dart
type nul > lib\visores_especificos\eletrico\visor_mppt_2.dart

echo Criando arquivos em visores_especificos/geral...
type nul > lib\visores_especificos\geral\visor_autonomia.dart

echo.
echo Estrutura criada com sucesso! 
echo Agora, mova os arquivos originais "mostrador-..." para dentro da pasta lib\templates_visuais.
echo Mantenha o main.dart solto na raiz da pasta lib.
pause