#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Verificando pré-requisitos..."
echo ""

ALL_OK=true

# Verificar Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${GREEN}✓${NC} Docker:   $DOCKER_VERSION"
else
    echo -e "${RED}✗${NC} Docker não encontrado. Instale: https://docs.docker.com/get-docker/"
    ALL_OK=false
fi

# Verificar Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
    else
        COMPOSE_VERSION=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
    fi
    echo -e "${GREEN}✓${NC} Docker Compose: $COMPOSE_VERSION"
else
    echo -e "${RED}✗${NC} Docker Compose não encontrado"
    ALL_OK=false
fi

# Verificar Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js:  $NODE_VERSION"
else
    echo -e "${RED}✗${NC} Node.js não encontrado. Instale: https://nodejs.org/"
    ALL_OK=false
fi

# Verificar npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm:      $NPM_VERSION"
else
    echo -e "${YELLOW}⚠${NC} npm não encontrado (geralmente vem com Node.js)"
fi

# Verificar yarn
if command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn --version)
    echo -e "${GREEN}✓${NC} yarn:     $YARN_VERSION"
else
    echo -e "${YELLOW}⚠${NC} yarn não encontrado. Instalando..."
    npm install -g yarn
fi

# Verificar pnpm
if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    echo -e "${GREEN}✓${NC} pnpm:     $PNPM_VERSION"
else
    echo -e "${YELLOW}⚠${NC} pnpm não encontrado. Instalando..."
    npm install -g pnpm
fi

# Verificar Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✓${NC} Git:      $GIT_VERSION"
else
    echo -e "${RED}✗${NC} Git não encontrado. Instale: https://git-scm.com/"
    ALL_OK=false
fi

# Verificar Make
if command -v make &> /dev/null; then
    MAKE_VERSION=$(make --version | head -n 1 | awk '{print $3}')
    echo -e "${GREEN}✓${NC} Make:     $MAKE_VERSION"
else
    echo -e "${RED}✗${NC} Make não encontrado"
    echo -e "   ${YELLOW}macOS:${NC} xcode-select --install"
    echo -e "   ${YELLOW}Ubuntu/Debian:${NC} sudo apt-get install build-essential"
    echo -e "   ${YELLOW}Windows:${NC} choco install make (via Chocolatey) ou use WSL2"
    ALL_OK=false
fi

echo ""
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}✓ Todos os pré-requisitos atendidos!${NC}"
    exit 0
else
    echo -e "${RED}✗ Alguns pré-requisitos não foram atendidos. Por favor, instale-os e tente novamente.${NC}"
    exit 1
fi
