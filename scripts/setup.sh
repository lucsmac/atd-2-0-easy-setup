#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║                                                       ║"
echo "║      Autódromo 2.0 - Setup Completo                  ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 1. Verificar pré-requisitos
echo -e "${BLUE}[1/7]${NC} Verificando pré-requisitos..."
./scripts/check-prerequisites.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Pré-requisitos não atendidos. Abortando.${NC}"
    exit 1
fi
echo ""

# 2. Clonar repositórios
echo -e "${BLUE}[2/7]${NC} Clonando repositórios..."
./scripts/clone-repos.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erro ao clonar repositórios. Abortando.${NC}"
    exit 1
fi
echo ""

# 3. Iniciar serviços Docker
echo -e "${BLUE}[3/7]${NC} Iniciando serviços Docker..."
docker-compose up -d
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erro ao iniciar serviços Docker. Abortando.${NC}"
    exit 1
fi
echo ""

# 4. Aguardar serviços ficarem prontos
echo -e "${BLUE}[4/7]${NC} Aguardando serviços ficarem prontos..."
./scripts/wait-for-services.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Timeout ao aguardar serviços. Verifique com 'docker-compose logs'${NC}"
    exit 1
fi
echo ""

# 5. Gerar arquivos .env
echo -e "${BLUE}[5/7]${NC} Gerando arquivos .env..."
./scripts/generate-env.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erro ao gerar arquivos .env. Abortando.${NC}"
    exit 1
fi
echo ""

# 6. Instalar dependências
echo -e "${BLUE}[6/7]${NC} Instalando dependências..."
./scripts/install-deps.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erro ao instalar dependências. Abortando.${NC}"
    exit 1
fi
echo ""

# 7. Configurações pós-instalação
echo -e "${BLUE}[7/7]${NC} Executando configurações pós-instalação..."

# General API - Prisma
echo -e "${YELLOW}→${NC} General API: Gerando Prisma client e executando migrations..."
cd apps/atd-workspace-general-api
if ! npx prisma generate; then
    echo -e "  ${RED}✗${NC} Erro ao gerar Prisma client (General API)"
    cd - > /dev/null
    exit 1
fi
if ! npx prisma migrate dev --name init; then
    echo -e "  ${RED}✗${NC} Erro ao executar migrations (General API)"
    cd - > /dev/null
    exit 1
fi
cd - > /dev/null
echo -e "  ${GREEN}✓${NC} General API configurado!"

# Hosting API - Fontes e Prisma
echo -e "${YELLOW}→${NC} Hosting API: Gerando fontes, Prisma client e executando migrations..."
cd apps/atd-workspace-hosting
if ! pnpm --filter static run fonts; then
    echo -e "  ${RED}✗${NC} Erro ao gerar fontes (Hosting)"
    cd - > /dev/null
    exit 1
fi
if ! pnpm --filter api run prepare; then
    echo -e "  ${RED}✗${NC} Erro ao executar prepare (Hosting API)"
    cd - > /dev/null
    exit 1
fi
if ! pnpm --filter api run migrate; then
    echo -e "  ${RED}✗${NC} Erro ao executar migrations (Hosting API)"
    cd - > /dev/null
    exit 1
fi
cd - > /dev/null
echo -e "  ${GREEN}✓${NC} Hosting API configurado!"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup completo!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}🚀 Para iniciar o desenvolvimento:${NC}"
echo -e "   ${YELLOW}make dev${NC}          # Inicia todas as aplicações"
echo -e "   ${YELLOW}make dev-ui${NC}       # Inicia apenas UI"
echo -e "   ${YELLOW}make dev-apis${NC}     # Inicia apenas APIs"
echo ""
echo -e "${CYAN}📚 Outros comandos úteis:${NC}"
echo -e "   ${YELLOW}make help${NC}         # Lista todos os comandos"
echo -e "   ${YELLOW}make status${NC}       # Verifica status dos serviços"
echo -e "   ${YELLOW}make logs${NC}         # Visualiza logs"
echo ""
echo -e "${YELLOW}⚠${NC}  Lembre-se de configurar credenciais reais em:"
echo -e "   - ${BLUE}apps/atd-workspace-ui/.env${NC} (Pusher)"
echo -e "   - ${BLUE}apps/atd-workspace-general-api/.env${NC} (SMTP, Pusher)"
echo -e "   - ${BLUE}apps/atd-workspace-hosting/api/.env${NC} (Pusher)"
echo ""
