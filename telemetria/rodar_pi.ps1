Write-Host "1. Compilando o app nativamente (Bundle)..." -ForegroundColor Cyan
flutter build bundle

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilacao. Abortando." -ForegroundColor Red
    exit
}

Write-Host "2. Preparando a pasta no Raspberry Pi..." -ForegroundColor Cyan
ssh arariboia@10.80.65.35 "rm -rf /tmp/telemetria_app && mkdir -p /tmp/telemetria_app"

Write-Host "3. Enviando apenas os arquivos do app via SSH..." -ForegroundColor Cyan
scp -r build\flutter_assets arariboia@10.80.65.35:/tmp/telemetria_app/

Write-Host "4. Verificando o motor do Flutter diretamente no Raspberry Pi..." -ForegroundColor Cyan
# O script roda um comando rápido no Pi para garantir que o motor e o icudtl.dat estão na pasta correta
ssh arariboia@10.80.65.35 @"
if [ ! -f /tmp/telemetria_app/flutter_assets/libflutter_engine.so ]; then
    echo 'Procurando motor no Raspberry Pi...'
    # Se o flutter-pi instalou os arquivos no sistema, copiamos de lá para a pasta do app
    if [ -f /usr/local/lib/libflutter_engine.so ]; then
        cp /usr/local/lib/libflutter_engine.so /tmp/telemetria_app/flutter_assets/
    fi
fi
if [ ! -f /tmp/telemetria_app/flutter_assets/icudtl.dat ]; then
    # Procura o icudtl.dat no sistema do Pi ou baixa uma cópia limpa se faltar
    find /usr -name icudtl.dat 2>/dev/null | head -n 1 | xargs -I {} cp {} /tmp/telemetria_app/flutter_assets/
fi
"@

Write-Host "5. Iniciando o app na tela do Raspberry Pi..." -ForegroundColor Cyan
ssh arariboia@10.80.65.35 "flutter-pi /tmp/telemetria_app/flutter_assets"