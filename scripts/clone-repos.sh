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

echo -e "${BLUE}📦 Clonando repositórios...${NC}"
echo ""

# Criar diretório apps se não existir
mkdir -p apps

# Ler configuração e clonar repos
REPO_COUNT=$(jq '.repositories | length' "$CONFIG_FILE")

for ((i=0; i<$REPO_COUNT; i++)); do
    NAME=$(jq -r ".repositories[$i].name" "$CONFIG_FILE")
    URL=$(jq -r ".repositories[$i].url" "$CONFIG_FILE")
    BRANCH=$(jq -r ".repositories[$i].branch" "$CONFIG_FILE")
    DIR=$(jq -r ".repositories[$i].directory" "$CONFIG_FILE")

    echo -e "${YELLOW}→${NC} Clonando ${GREEN}$NAME${NC}..."

    if [ -d "$DIR" ]; then
        echo -e "  ${YELLOW}⚠${NC} Diretório já existe: $DIR"
        echo -e "  ${BLUE}ℹ${NC} Atualizando repositório..."
        cd "$DIR"
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
        cd - > /dev/null
        echo -e "  ${GREEN}✓${NC} Atualizado!"
    else
        git clone --branch "$BRANCH" "$URL" "$DIR"
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} Clonado com sucesso!"
        else
            echo -e "  ${RED}✗${NC} Erro ao clonar $NAME"
            exit 1
        fi
    fi

    echo ""
done

echo -e "${GREEN}✓ Todos os repositórios foram clonados/atualizados!${NC}"
