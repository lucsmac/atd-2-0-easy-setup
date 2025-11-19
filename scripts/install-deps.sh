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

echo -e "${BLUE}📦 Instalando dependências...${NC}"
echo ""

REPO_COUNT=$(jq '.repositories | length' "$CONFIG_FILE")

for ((i=0; i<$REPO_COUNT; i++)); do
    NAME=$(jq -r ".repositories[$i].name" "$CONFIG_FILE")
    DIR=$(jq -r ".repositories[$i].directory" "$CONFIG_FILE")
    PKG_MANAGER=$(jq -r ".repositories[$i].packageManager" "$CONFIG_FILE")

    echo -e "${YELLOW}→${NC} Instalando dependências de ${GREEN}$NAME${NC} (usando $PKG_MANAGER)..."

    if [ ! -d "$DIR" ]; then
        echo -e "  ${RED}✗${NC} Diretório não encontrado: $DIR"
        echo -e "  ${BLUE}ℹ${NC} Execute 'make clone' primeiro"
        continue
    fi

    cd "$DIR"

    case "$PKG_MANAGER" in
        npm)
            npm install --legacy-peer-deps
            ;;
        yarn)
            yarn install
            ;;
        pnpm)
            pnpm install
            ;;
        *)
            echo -e "  ${RED}✗${NC} Gerenciador de pacotes desconhecido: $PKG_MANAGER"
            cd - > /dev/null
            continue
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} Dependências instaladas!"
    else
        echo -e "  ${RED}✗${NC} Erro ao instalar dependências"
        cd - > /dev/null
        exit 1
    fi

    cd - > /dev/null
    echo ""
done

echo -e "${GREEN}✓ Todas as dependências foram instaladas!${NC}"
