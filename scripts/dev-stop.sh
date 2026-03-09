#!/bin/bash

# Cores para output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PID_FILE=".dev-session-pids"
SESSION_FILE=".dev-session-info"

if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}⚠  Nenhuma sessão de desenvolvimento ativa${NC}"
    exit 0
fi

echo -e "${BLUE}🛑 Parando serviços de desenvolvimento...${NC}"
echo ""

stopped=0
failed=0

while read line; do
    name=$(echo "$line" | cut -d: -f1)
    pid=$(echo "$line" | cut -d: -f2)

    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${CYAN}→${NC} Parando $name (PID: $pid)..."

        # Tentar parar gracefully primeiro
        kill -TERM $pid 2>/dev/null

        # Aguardar até 5 segundos
        count=0
        while ps -p $pid > /dev/null 2>&1 && [ $count -lt 5 ]; do
            sleep 1
            ((count++))
        done

        # Se ainda estiver rodando, force kill
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}  ⚠  Forçando parada...${NC}"
            kill -9 $pid 2>/dev/null
            sleep 1
        fi

        if ! ps -p $pid > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $name parado"
            ((stopped++))
        else
            echo -e "  ${RED}✗${NC} Falha ao parar $name"
            ((failed++))
        fi
    else
        echo -e "${YELLOW}→${NC} $name já está parado (PID: $pid)"
    fi
done < "$PID_FILE"

# Limpar arquivos de sessão
rm -f "$PID_FILE"
rm -f "$SESSION_FILE"

# Limpar logs antigos (opcional)
if [ -n "$1" ] && [ "$1" = "--clean-logs" ]; then
    echo ""
    echo -e "${YELLOW}🧹 Limpando logs...${NC}"
    rm -f /tmp/atd-*.log
    echo -e "${GREEN}✓ Logs limpos${NC}"
fi

echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os serviços foram parados ($stopped serviços)${NC}"
else
    echo -e "${YELLOW}⚠  $stopped serviços parados, $failed falharam${NC}"
fi

# Perguntar se quer parar Docker também
echo ""
echo -n -e "${YELLOW}Deseja parar os serviços Docker também? (y/N): ${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🐳 Parando serviços Docker...${NC}"

    if command -v docker-compose &> /dev/null; then
        docker-compose stop
        echo -e "${GREEN}✓ Serviços Docker parados${NC}"
    else
        echo -e "${RED}✗ docker-compose não encontrado${NC}"
    fi
fi
