#!/bin/bash

# Script de teste para Docker Compose Otimizado
# Valida que todos os databases foram criados corretamente

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testando Docker Compose Otimizado...${NC}"
echo ""

# Verifica se está rodando
if ! docker ps | grep -q "atd-postgres-optimized"; then
    echo -e "${RED}✗ PostgreSQL otimizado não está rodando${NC}"
    echo -e "${YELLOW}ℹ  Execute: make services-optimized${NC}"
    exit 1
fi

echo -e "${GREEN}✓ PostgreSQL otimizado está rodando${NC}"
echo ""

# Testa conexão
echo -e "${CYAN}→${NC} Testando conexão..."
if ! docker exec atd-postgres-optimized pg_isready -U atd > /dev/null 2>&1; then
    echo -e "${RED}✗ PostgreSQL não está pronto${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL está pronto${NC}"
echo ""

# Verifica databases
echo -e "${CYAN}→${NC} Verificando databases criados..."
databases=$(docker exec atd-postgres-optimized psql -U atd -t -c "SELECT datname FROM pg_database WHERE datname LIKE 'atd_%';")

expected_dbs=("atd_general" "atd_hosting" "atd_cms" "atd_crm")
all_found=true

for db in "${expected_dbs[@]}"; do
    if echo "$databases" | grep -q "$db"; then
        echo -e "  ${GREEN}✓${NC} $db"
    else
        echo -e "  ${RED}✗${NC} $db (não encontrado)"
        all_found=false
    fi
done

echo ""

if [ "$all_found" = false ]; then
    echo -e "${RED}✗ Alguns databases não foram criados${NC}"
    echo -e "${YELLOW}ℹ  Execute: make services-optimized-reset && make services-optimized${NC}"
    exit 1
fi

# Testa connection strings
echo -e "${CYAN}→${NC} Testando connection strings..."

test_connection() {
    local db=$1
    if docker exec atd-postgres-optimized psql -U atd -d "$db" -c "SELECT 1" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} postgresql://atd:atd123@localhost:5432/$db"
        return 0
    else
        echo -e "  ${RED}✗${NC} postgresql://atd:atd123@localhost:5432/$db"
        return 1
    fi
}

all_connected=true
for db in "${expected_dbs[@]}"; do
    if ! test_connection "$db"; then
        all_connected=false
    fi
done

echo ""

# Verifica uso de memória
echo -e "${CYAN}→${NC} Verificando uso de memória..."
mem_usage=$(docker stats atd-postgres-optimized --no-stream --format "{{.MemUsage}}" 2>/dev/null)
if [ -n "$mem_usage" ]; then
    echo -e "  ${GREEN}✓${NC} Uso atual: $mem_usage"
else
    echo -e "  ${YELLOW}⚠${NC}  Não foi possível obter uso de memória"
fi

echo ""

# Resultado final
if [ "$all_found" = true ] && [ "$all_connected" = true ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Todos os testes passaram!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Databases disponíveis:${NC}"
    echo -e "  - postgresql://atd:atd123@localhost:5432/atd_general"
    echo -e "  - postgresql://atd:atd123@localhost:5432/atd_hosting"
    echo -e "  - postgresql://atd:atd123@localhost:5432/atd_cms"
    echo -e "  - postgresql://atd:atd123@localhost:5432/atd_crm"
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}✗ Alguns testes falharam${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
