#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}⏳ Aguardando serviços Docker ficarem prontos...${NC}"
echo ""

MAX_ATTEMPTS=30
ATTEMPT=0

# Função para verificar serviço
check_service() {
    local SERVICE_NAME=$1
    local CHECK_COMMAND=$2

    echo -n -e "${YELLOW}→${NC} $SERVICE_NAME: "

    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if eval "$CHECK_COMMAND" &> /dev/null; then
            echo -e "${GREEN}✓ Pronto${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        ((ATTEMPT++))
    done

    echo -e "${RED}✗ Timeout${NC}"
    return 1
}

# PostgreSQL General
ATTEMPT=0
check_service "PostgreSQL (General)" "docker exec atd-postgres-general pg_isready -U atd -d atd_general"

# PostgreSQL Hosting
ATTEMPT=0
check_service "PostgreSQL (Hosting)" "docker exec atd-postgres-hosting pg_isready -U atd -d atd_hosting"

# Redis
ATTEMPT=0
check_service "Redis" "docker exec atd-redis redis-cli ping"

# LocalStack
ATTEMPT=0
check_service "LocalStack (AWS)" "curl -s http://localhost:4566/_localstack/health"

echo ""
echo -e "${GREEN}✓ Todos os serviços estão prontos!${NC}"
