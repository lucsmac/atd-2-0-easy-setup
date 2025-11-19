#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="config/repos.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Arquivo de configuração não encontrado: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📝 Gerando arquivos .env...${NC}"
echo ""

REPO_COUNT=$(jq '.repositories | length' "$CONFIG_FILE")

for ((i=0; i<$REPO_COUNT; i++)); do
    NAME=$(jq -r ".repositories[$i].name" "$CONFIG_FILE")
    TEMPLATE=$(jq -r ".repositories[$i].envTemplate" "$CONFIG_FILE")
    DESTINATION=$(jq -r ".repositories[$i].envDestination" "$CONFIG_FILE")

    echo -e "${YELLOW}→${NC} Gerando .env para ${GREEN}$NAME${NC}..."

    if [ ! -f "$TEMPLATE" ]; then
        echo -e "  ${RED}✗${NC} Template não encontrado: $TEMPLATE"
        continue
    fi

    # Criar diretório de destino se não existir
    DEST_DIR=$(dirname "$DESTINATION")
    mkdir -p "$DEST_DIR"

    # Copiar template para destino
    if [ -f "$DESTINATION" ]; then
        echo -e "  ${YELLOW}⚠${NC} Arquivo .env já existe: $DESTINATION"
        echo -e "  ${BLUE}ℹ${NC} Use 'make env-regenerate' para sobrescrever"
    else
        cp "$TEMPLATE" "$DESTINATION"
        echo -e "  ${GREEN}✓${NC} Criado: $DESTINATION"
    fi

    echo ""
done

echo -e "${GREEN}✓ Arquivos .env gerados!${NC}"
echo -e "${YELLOW}⚠${NC} Lembre-se de configurar credenciais reais (Pusher, SMTP, etc.) nos arquivos .env"
