#!/bin/bash

# Cores para output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PID_FILE=".dev-session-pids"

if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}⚠  Nenhuma sessão de desenvolvimento ativa${NC}"
    echo -e "${CYAN}ℹ  Execute 'make dev-modular' para iniciar${NC}"
    exit 0
fi

# Se um serviço específico foi passado como argumento
if [ -n "$1" ]; then
    service_name="$1"
    log_file="/tmp/atd-${service_name}.log"

    if [ -f "$log_file" ]; then
        echo -e "${BLUE}📋 Logs de $service_name${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        tail -f "$log_file"
    else
        echo -e "${RED}✗ Log não encontrado: $log_file${NC}"
        exit 1
    fi
    exit 0
fi

# Mostrar menu de serviços
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          📋 Visualizar Logs                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Escolha o serviço:${NC}"
echo ""

declare -a services
i=1

while read line; do
    name=$(echo "$line" | cut -d: -f1)
    pid=$(echo "$line" | cut -d: -f2)

    if ps -p $pid > /dev/null 2>&1; then
        services+=("$name")
        echo -e "  ${CYAN}$i)${NC} $name ${GREEN}(rodando)${NC}"
    else
        services+=("$name")
        echo -e "  ${CYAN}$i)${NC} $name ${RED}(parado)${NC}"
    fi

    ((i++))
done < "$PID_FILE"

echo ""
echo -e "  ${CYAN}0)${NC} Ver todos em paralelo (multitail)"
echo ""
echo -n -e "${GREEN}Escolha [0-${#services[@]}]: ${NC}"

read -r choice

if [ "$choice" -eq 0 ]; then
    # Ver todos os logs em paralelo
    echo -e "${BLUE}📋 Visualizando todos os logs...${NC}"
    echo -e "${YELLOW}Use Ctrl+C para sair${NC}"
    echo ""

    log_files=()

    while read line; do
        name=$(echo "$line" | cut -d: -f1)
        log_file="/tmp/atd-${name}.log"

        if [ -f "$log_file" ]; then
            log_files+=("$log_file")
        fi
    done < "$PID_FILE"

    if [ ${#log_files[@]} -eq 0 ]; then
        echo -e "${RED}✗ Nenhum log encontrado${NC}"
        exit 1
    fi

    # Verificar se multitail está disponível
    if command -v multitail &> /dev/null; then
        multitail "${log_files[@]}"
    else
        # Fallback: usar tail -f com múltiplos arquivos
        echo -e "${YELLOW}ℹ  multitail não encontrado, usando tail -f${NC}"
        echo -e "${CYAN}  Dica: instale multitail para melhor experiência${NC}"
        echo ""

        tail -f "${log_files[@]}"
    fi

elif [ "$choice" -gt 0 ] && [ "$choice" -le "${#services[@]}" ]; then
    # Ver log específico
    idx=$((choice - 1))
    service_name="${services[$idx]}"
    log_file="/tmp/atd-${service_name}.log"

    if [ -f "$log_file" ]; then
        echo -e "${BLUE}📋 Logs de $service_name${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Use Ctrl+C para sair${NC}"
        echo ""

        tail -f "$log_file"
    else
        echo -e "${RED}✗ Log não encontrado: $log_file${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Opção inválida${NC}"
    exit 1
fi
