#!/bin/bash

# ==========================================
# CONFIGURAÇÕES DO AMBIENTE
# ==========================================
RPI_USER="arariboia"                     # Usuário do Raspberry Pi (ex: pi, root)
RPI_IP="10.88.1.35"             # IP do seu Raspberry Pi na rede
LOCAL_PATH="./build/linux/arm64/release/bundle" # Caminho local do build do Flutter (ajuste a arquitetura se necessário)
REMOTE_PATH="/home/arariboia/meu_app_flutter"    # Onde o aplicativo deve ficar no Raspberry Pi
APP_NAME="seu_app_flutter"        # Nome do executável gerado pelo Flutter

# Cores para saída no terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem cor

echo -e "${YELLOW}==> Verificando conexão com o Raspberry Pi ($RPI_IP)...${NC}"
if ! ping -c 1 -w 3 "$RPI_IP" > /dev/null 2>&1; then
    echo -e "${RED}Erro: Não foi possível alcançar o Raspberry Pi no IP $RPI_IP.${NC}"
    exit 1
fi

echo -e "${YELLOW}==> Verificando estrutura de pastas no Raspberry Pi...${NC}"
# Garante que o diretório de destino existe no Raspberry
ssh "$RPI_USER@$RPI_IP" "mkdir -p $REMOTE_PATH"

echo -e "${YELLOW}==> Verificando se os arquivos principais estão no Raspberry...${NC}"
# Verifica se o executável principal existe no destino remoto
if ssh "$RPI_USER@$RPI_IP" "[ -f $REMOTE_PATH/$APP_NAME ]"; then
    echo -e "${GREEN}Sucesso: O executável do Flutter está no lugar correto.${NC}"
else
    echo -e "${RED}Aviso: O executável não foi encontrado no Raspberry Pi.${NC}"
    echo -e "${YELLOW}==> Iniciando correção: Copiando arquivos do Flutter para o Raspberry...${NC}"
    
    # Verifica se o build local existe antes de enviar
    if [ ! -d "$LOCAL_PATH" ]; then
        echo -e "${RED}Erro: Pasta de build local ($LOCAL_PATH) não encontrada. Execute 'flutter build' primeiro.${NC}"
        exit 1
    }

    # Copia os arquivos usando rsync via SSH
    rsync -avz --progress "$LOCAL_PATH/" "$RPI_USER@$RPI_IP:$REMOTE_PATH/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Correção concluída: Arquivos copiados com sucesso para o Raspberry Pi!${NC}"
        
        # Garante permissão de execução no binário
        ssh "$RPI_USER@$RPI_IP" "chmod +x $REMOTE_PATH/$APP_NAME"
    else
        echo -e "${RED}Erro ao copiar os arquivos via rsync.${NC}"
        exit 1
    fi
fi

# Verificação específica de telas/assets se necessário
echo -e "${YELLOW}==> Verificando integridade dos assets...${NC}"
if ssh "$RPI_USER@$RPI_IP" "[ -d $REMOTE_PATH/data/flutter_assets ]"; then
    echo -e "${GREEN}Assets de tela validados com sucesso no Raspberry Pi.${NC}"
else
    echo -e "${RED}Aviso: Pasta de assets ausente. Reenviando pacote completo...${NC}"
    rsync -avz "$LOCAL_PATH/" "$RPI_USER@$RPI_IP:$REMOTE_PATH/"
fi

echo -e "${GREEN}==> Processo finalizado com sucesso!${NC}"