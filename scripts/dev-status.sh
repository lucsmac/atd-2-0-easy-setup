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
    echo -e "${CYAN}ℹ  Execute 'make dev-modular' para iniciar${NC}"
    exit 0
fi

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     📊 Status da Sessão de Desenvolvimento    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Mostrar informações da sessão
if [ -f "$SESSION_FILE" ]; then
    started=$(grep "started:" "$SESSION_FILE" | cut -d: -f2)
    profile=$(grep "profile:" "$SESSION_FILE" | cut -d: -f2)

    if [ -n "$started" ]; then
        current=$(date +%s)
        uptime=$((current - started))
        hours=$((uptime / 3600))
        minutes=$(((uptime % 3600) / 60))

        echo -e "${CYAN}Tempo ativo:${NC} ${hours}h ${minutes}m"
    fi

    if [ -n "$profile" ]; then
        case $profile in
            1) profile_name="UI + Builder" ;;
            2) profile_name="Auth & Usuários" ;;
            3) profile_name="Publishing & Templates" ;;
            4) profile_name="CMS Completo" ;;
            5) profile_name="CRM" ;;
            6) profile_name="Backend Completo" ;;
            7) profile_name="Fullstack" ;;
            8) profile_name="Personalizado" ;;
            9) profile_name="Builder + CMS (Otimizado)" ;;
            10) profile_name="Builder + CMS + Hosting (Completo)" ;;
            *) profile_name="Desconhecido" ;;
        esac
        echo -e "${CYAN}Perfil:${NC} $profile_name"
    fi

    echo ""
fi

# Mostrar serviços rodando
echo -e "${GREEN}Serviços Ativos:${NC}"
echo ""

running_count=0
stopped_count=0

while read line; do
    name=$(echo "$line" | cut -d: -f1)
    pid=$(echo "$line" | cut -d: -f2)
    port=$(echo "$line" | cut -d: -f3)

    if ps -p $pid > /dev/null 2>&1; then
        status="${GREEN}✓ Rodando${NC}"
        ((running_count++))

        if [ "$port" != "-" ]; then
            echo -e "  $status  $name (PID: $pid) → ${CYAN}http://localhost:$port${NC}"
        else
            echo -e "  $status  $name (PID: $pid)"
        fi
    else
        status="${RED}✗ Parado${NC}"
        ((stopped_count++))

        echo -e "  $status  $name (PID: $pid)"
    fi
done < "$PID_FILE"

echo ""
echo -e "${CYAN}Total:${NC} $running_count rodando, $stopped_count parados"

# Mostrar uso de memória
echo ""
echo -e "${BLUE}📊 Uso de Memória:${NC}"
echo ""

total_mem=0

while read line; do
    name=$(echo "$line" | cut -d: -f1)
    pid=$(echo "$line" | cut -d: -f2)

    if ps -p $pid > /dev/null 2>&1; then
        mem=$(ps -p $pid -o rss= | awk '{print $1}')
        mem_mb=$((mem / 1024))
        total_mem=$((total_mem + mem))

        printf "  %-25s %6d MB\n" "$name" "$mem_mb"
    fi
done < "$PID_FILE"

total_mb=$((total_mem / 1024))
echo -e "${CYAN}  ─────────────────────────────────${NC}"
printf "  ${GREEN}%-25s %6d MB${NC}\n" "TOTAL" "$total_mb"

# Mostrar uso total do sistema
echo ""
echo -e "${BLUE}🖥️  Sistema:${NC}"

if command -v free &> /dev/null; then
    total_system=$(free -m | awk 'NR==2{print $2}')
    used_system=$(free -m | awk 'NR==2{print $3}')
    percent=$((used_system * 100 / total_system))

    echo -e "  Memória Total: ${total_system} MB"
    echo -e "  Memória Usada: ${used_system} MB (${percent}%)"
fi

# Mostrar CPU
if command -v top &> /dev/null; then
    echo ""
    echo -e "${BLUE}⚡ Top 5 Processos por CPU:${NC}"
    echo ""

    top_output=$(mktemp)
    top -b -n 1 > "$top_output"

    while read line; do
        pid=$(echo "$line" | cut -d: -f2)

        if ps -p $pid > /dev/null 2>&1; then
            name=$(echo "$line" | cut -d: -f1)
            cpu=$(ps -p $pid -o %cpu= | awk '{print $1}')

            printf "  %-25s %6s%%\n" "$name" "$cpu"
        fi
    done < "$PID_FILE" | sort -k2 -rn | head -5

    rm -f "$top_output"
fi

# Mostrar logs disponíveis
echo ""
echo -e "${BLUE}📋 Logs Disponíveis:${NC}"
echo ""

while read line; do
    name=$(echo "$line" | cut -d: -f1)
    pid=$(echo "$line" | cut -d: -f2)

    if ps -p $pid > /dev/null 2>&1; then
        log_file="/tmp/atd-${name}.log"

        if [ -f "$log_file" ]; then
            size=$(du -h "$log_file" | cut -f1)
            echo -e "  ${CYAN}→${NC} $name ($size): ${YELLOW}tail -f /tmp/atd-${name}.log${NC}"
        fi
    fi
done < "$PID_FILE"

# Comandos úteis
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Comandos Úteis:${NC}"
echo -e "  ${CYAN}make dev-logs${NC}     - Ver todos os logs em tempo real"
echo -e "  ${CYAN}make dev-stop${NC}     - Parar todos os serviços"
echo -e "  ${CYAN}make dev-restart${NC}  - Reiniciar todos os serviços"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
