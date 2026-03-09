#!/bin/bash

# Cores para output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arquivo para armazenar PIDs dos processos
PID_FILE=".dev-session-pids"
SESSION_FILE=".dev-session-info"

# Docker Compose - escolha otimizado ou padrão
# Pode ser configurado via variável de ambiente: ATD_DOCKER_MODE=optimized ou standard
DOCKER_MODE="${ATD_DOCKER_MODE:-standard}"
if [ "$DOCKER_MODE" = "optimized" ]; then
    DOCKER_COMPOSE_FILE="docker-compose.optimized.yml"
    DOCKER_PROFILE="minimal"  # minimal, backend, ou full
else
    DOCKER_COMPOSE_FILE="docker-compose.yml"
    DOCKER_PROFILE=""
fi

# Função para limpar ao sair
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Parando todos os serviços...${NC}"

    if [ -f "$PID_FILE" ]; then
        while read line; do
            name=$(echo "$line" | cut -d: -f1)
            pid=$(echo "$line" | cut -d: -f2)

            if ps -p $pid > /dev/null 2>&1; then
                echo -e "  ${CYAN}→${NC} Parando $name (PID: $pid)"
                kill -TERM $pid 2>/dev/null || kill -9 $pid 2>/dev/null
            fi
        done < "$PID_FILE"

        rm -f "$PID_FILE"
    fi

    rm -f "$SESSION_FILE"
    echo -e "${GREEN}✓ Todos os serviços foram parados${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Função para iniciar serviço em background
start_service() {
    local name=$1
    local dir=$2
    local cmd=$3
    local port=$4

    echo -e "${CYAN}→${NC} Iniciando $name..."

    cd "$dir"
    eval "$cmd" > /tmp/atd-${name}.log 2>&1 &
    local pid=$!

    echo "${name}:${pid}:${port}" >> "../../../$PID_FILE"
    echo -e "  ${GREEN}✓${NC} $name iniciado (PID: $pid)"

    cd - > /dev/null
}

# Função para verificar portas em uso
check_ports() {
    local ports=("$@")
    local conflicts=()

    for port in "${ports[@]}"; do
        if lsof -ti:$port > /dev/null 2>&1; then
            conflicts+=($port)
        fi
    done

    if [ ${#conflicts[@]} -gt 0 ]; then
        echo -e "${RED}⚠  Conflito de portas detectado!${NC}"
        echo -e "As seguintes portas já estão em uso: ${conflicts[*]}"
        echo ""
        echo -e "Deseja parar os processos nessas portas? (y/N)"
        read -r response

        if [[ "$response" =~ ^[Yy]$ ]]; then
            for port in "${conflicts[@]}"; do
                echo -e "${YELLOW}→${NC} Parando processo na porta $port..."
                kill $(lsof -ti:$port) 2>/dev/null
            done
            sleep 2
        else
            echo -e "${RED}✗ Abortando setup${NC}"
            exit 1
        fi
    fi
}

# Função para mostrar status de memória
show_memory_usage() {
    echo ""
    echo -e "${BLUE}📊 Uso de Memória:${NC}"

    if [ -f "$PID_FILE" ]; then
        local total_mem=0

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
    fi
}

# Função para mostrar logs
show_logs() {
    echo ""
    echo -e "${BLUE}📋 Logs disponíveis em:${NC}"

    if [ -f "$PID_FILE" ]; then
        while read line; do
            name=$(echo "$line" | cut -d: -f1)
            echo -e "  ${CYAN}→${NC} $name: tail -f /tmp/atd-${name}.log"
        done < "$PID_FILE"
    fi
}

# Função para iniciar Docker services
start_docker_services() {
    local services=("$@")

    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠  Nenhum serviço Docker necessário${NC}"
        return
    fi

    echo -e "${BLUE}🐳 Iniciando serviços Docker...${NC}"
    echo -e "${CYAN}ℹ  Modo: $DOCKER_MODE${NC}"

    # Verifica se docker-compose está disponível
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗ docker-compose não encontrado${NC}"
        echo -e "${YELLOW}ℹ  Instale docker-compose ou inicie os serviços manualmente${NC}"
        return
    fi

    if [ "$DOCKER_MODE" = "optimized" ]; then
        # Modo otimizado - PostgreSQL único sempre incluso no profile
        echo -e "${GREEN}✓ Usando Docker Compose Otimizado${NC}"
        echo -e "${YELLOW}ℹ  PostgreSQL único com todos databases (economia de ~1.2 GB)${NC}"

        # Determinar profile baseado nos serviços solicitados
        local needs_opensearch=false
        local needs_redis=false

        for service in "${services[@]}"; do
            case $service in
                opensearch-cms) needs_opensearch=true ;;
                redis*) needs_redis=true ;;
            esac
        done

        if [ "$needs_opensearch" = true ]; then
            DOCKER_PROFILE="full"
        elif [ "$needs_redis" = true ]; then
            DOCKER_PROFILE="backend"
        else
            DOCKER_PROFILE="minimal"
        fi

        echo -e "${CYAN}→${NC} Profile: $DOCKER_PROFILE"

        if [ -n "$DOCKER_PROFILE" ] && [ "$DOCKER_PROFILE" != "minimal" ]; then
            docker-compose -f "$DOCKER_COMPOSE_FILE" --profile "$DOCKER_PROFILE" up -d 2>/dev/null
        else
            docker-compose -f "$DOCKER_COMPOSE_FILE" up -d 2>/dev/null
        fi
    else
        # Modo padrão - inicia serviços específicos
        for service in "${services[@]}"; do
            echo -e "${CYAN}→${NC} Iniciando $service..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" up -d $service 2>/dev/null
        done
    fi

    echo -e "${GREEN}✓ Serviços Docker iniciados${NC}"
    sleep 3
}

# Menu interativo
show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🚀 Autódromo 2.0 - Setup Modular         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Escolha o contexto de desenvolvimento:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} UI + Builder ${YELLOW}(leve)${NC}"
    echo -e "     → UI + General API + Renderer (federation)"
    echo -e "     → RAM estimada: ~1.5 GB"
    echo ""
    echo -e "  ${CYAN}2)${NC} Auth & Usuários ${YELLOW}(muito leve)${NC}"
    echo -e "     → General API + UI"
    echo -e "     → RAM estimada: ~800 MB"
    echo ""
    echo -e "  ${CYAN}3)${NC} Publishing & Templates ${YELLOW}(moderado)${NC}"
    echo -e "     → Hosting API + Worker + Renderer + UI"
    echo -e "     → RAM estimada: ~2 GB"
    echo ""
    echo -e "  ${CYAN}4)${NC} CMS Completo ${YELLOW}(moderado)${NC}"
    echo -e "     → CMS API + Worker + UI"
    echo -e "     → RAM estimada: ~1.8 GB"
    echo ""
    echo -e "  ${CYAN}5)${NC} CRM ${YELLOW}(leve)${NC}"
    echo -e "     → CRM API + UI"
    echo -e "     → RAM estimada: ~1 GB"
    echo ""
    echo -e "  ${CYAN}6)${NC} Backend Completo ${YELLOW}(pesado)${NC}"
    echo -e "     → Todas APIs + Workers"
    echo -e "     → RAM estimada: ~3 GB"
    echo ""
    echo -e "  ${CYAN}7)${NC} Fullstack ${RED}(muito pesado)${NC}"
    echo -e "     → TUDO (igual make dev)"
    echo -e "     → RAM estimada: ~4+ GB"
    echo ""
    echo -e "  ${CYAN}8)${NC} Personalizado"
    echo -e "     → Escolha serviços individualmente"
    echo ""
    echo -e "  ${CYAN}9)${NC} Builder + CMS ${YELLOW}(leve - otimizado)${NC}"
    echo -e "     → UI + General API + Renderer (static) + CMS API"
    echo -e "     → Sem workers, sem OpenSearch, sem LocalStack"
    echo -e "     → RAM estimada: ~1.5 GB"
    echo ""
    echo -e "  ${CYAN}10)${NC} Builder + CMS + Hosting ${YELLOW}(moderado - completo)${NC}"
    echo -e "     → UI + General API + CMS API + Hosting API + Worker + Renderer (static)"
    echo -e "     → Tudo que você precisa para desenvolvimento completo"
    echo -e "     → RAM estimada: ~2.5 GB"
    echo ""
    echo -e "  ${CYAN}0)${NC} Sair"
    echo ""
    echo -n -e "${GREEN}Escolha uma opção [0-10]: ${NC}"
}

# Configurações para cada perfil
setup_ui_builder() {
    echo -e "${BLUE}🎨 Configurando: UI + Builder${NC}"

    check_ports 3000 3005 5500
    start_docker_services postgres-general

    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
    start_service "General-API" "apps/atd-workspace-general-api" "yarn dev" "3005"

    # Renderer em modo build (mais leve)
    echo -e "${CYAN}→${NC} Configurando Renderer (module federation)..."
    if [ ! -d "apps/atd-workspace-renderer/dist" ]; then
        echo -e "${YELLOW}  ℹ  Building renderer pela primeira vez...${NC}"
        cd apps/atd-workspace-renderer
        npm run publish-federation > /tmp/atd-renderer-build.log 2>&1
        cd - > /dev/null
    fi

    # Servir renderer estático (muito mais leve que dev)
    cd apps/atd-workspace-renderer/dist
    nohup npx http-server -p 5500 --cors > /tmp/atd-renderer-static.log 2>&1 &
    echo "Renderer-Static:$!:5500" >> "../../../$PID_FILE"
    cd - > /dev/null

    echo -e "  ${GREEN}✓${NC} Renderer servido estaticamente (PID: $!)"
}

setup_auth_users() {
    echo -e "${BLUE}🔐 Configurando: Auth & Usuários${NC}"

    check_ports 3000 3005
    start_docker_services postgres-general

    start_service "General-API" "apps/atd-workspace-general-api" "yarn dev" "3005"
    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
}

setup_publishing() {
    echo -e "${BLUE}🏗️  Configurando: Publishing & Templates${NC}"

    check_ports 3000 3001 5500
    start_docker_services postgres-hosting redis

    start_service "Hosting-API" "apps/atd-workspace-hosting/api" "PORT=3001 pnpm dev" "3001"
    start_service "Hosting-Worker" "apps/atd-workspace-hosting/api" "pnpm worker" "-"
    start_service "Renderer" "apps/atd-workspace-hosting/renderer" "pnpm dev" "5500"
    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
}

setup_cms() {
    echo -e "${BLUE}📦 Configurando: CMS Completo${NC}"

    check_ports 3000 3011
    start_docker_services postgres-cms redis-cms-batch redis-cms-search opensearch-cms

    start_service "CMS-API" "apps/atd-workspace-cms-api" "npm run dev" "3011"
    start_service "CMS-Worker" "apps/atd-workspace-cms-api" "npm run dev:worker" "-"
    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
}

setup_crm() {
    echo -e "${BLUE}👥 Configurando: CRM${NC}"

    check_ports 3000 3010
    start_docker_services postgres-crm

    start_service "CRM-API" "apps/atd-workspace-crm" "npm run dev" "3010"
    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
}

setup_backend() {
    echo -e "${BLUE}🔧 Configurando: Backend Completo${NC}"

    check_ports 3001 3005 3010 3011 5500
    start_docker_services postgres-general postgres-hosting postgres-cms postgres-crm redis redis-cms-batch redis-cms-search opensearch-cms

    start_service "General-API" "apps/atd-workspace-general-api" "yarn dev" "3005"
    start_service "Hosting-API" "apps/atd-workspace-hosting/api" "PORT=3001 pnpm dev" "3001"
    start_service "Hosting-Worker" "apps/atd-workspace-hosting/api" "pnpm worker" "-"
    start_service "Renderer" "apps/atd-workspace-hosting/renderer" "pnpm dev" "5500"
    start_service "CMS-API" "apps/atd-workspace-cms-api" "npm run dev" "3011"
    start_service "CMS-Worker" "apps/atd-workspace-cms-api" "npm run dev:worker" "-"
    start_service "CRM-API" "apps/atd-workspace-crm" "npm run dev" "3010"
}

setup_fullstack() {
    echo -e "${BLUE}🌟 Configurando: Fullstack (TUDO)${NC}"

    check_ports 3000 3001 3005 3010 3011 5500
    start_docker_services postgres-general postgres-hosting postgres-cms postgres-crm redis redis-cms-batch redis-cms-search opensearch-cms

    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
    start_service "General-API" "apps/atd-workspace-general-api" "yarn dev" "3005"
    start_service "Hosting-API" "apps/atd-workspace-hosting/api" "PORT=3001 pnpm dev" "3001"
    start_service "Hosting-Worker" "apps/atd-workspace-hosting/api" "pnpm worker" "-"
    start_service "Renderer" "apps/atd-workspace-hosting/renderer" "pnpm dev" "5500"
    start_service "CMS-API" "apps/atd-workspace-cms-api" "npm run dev" "3011"
    start_service "CMS-Worker" "apps/atd-workspace-cms-api" "npm run dev:worker" "-"
    start_service "CRM-API" "apps/atd-workspace-crm" "npm run dev" "3010"
}

setup_custom() {
    echo -e "${BLUE}⚙️  Configurando: Personalizado${NC}"
    echo ""

    # Lista de serviços disponíveis
    declare -A services
    services=(
        ["UI"]="apps/atd-workspace-ui:npm run dev:3000:postgres-general"
        ["General-API"]="apps/atd-workspace-general-api:yarn dev:3005:postgres-general"
        ["Hosting-API"]="apps/atd-workspace-hosting/api:PORT=3001 pnpm dev:3001:postgres-hosting,redis"
        ["Hosting-Worker"]="apps/atd-workspace-hosting/api:pnpm worker:-:postgres-hosting,redis"
        ["Renderer"]="apps/atd-workspace-hosting/renderer:pnpm dev:5500:postgres-hosting"
        ["CMS-API"]="apps/atd-workspace-cms-api:npm run dev:3011:postgres-cms,redis-cms-batch,redis-cms-search,opensearch-cms"
        ["CMS-Worker"]="apps/atd-workspace-cms-api:npm run dev:worker:-:postgres-cms,redis-cms-batch,redis-cms-search"
        ["CRM-API"]="apps/atd-workspace-crm:npm run dev:3010:postgres-crm"
    )

    echo -e "${GREEN}Serviços disponíveis:${NC}"
    local i=1
    local service_names=()

    for service_name in "${!services[@]}"; do
        service_names+=("$service_name")
        local info=${services[$service_name]}
        local port=$(echo "$info" | cut -d: -f3)

        if [ "$port" != "-" ]; then
            echo -e "  ${CYAN}$i)${NC} $service_name (porta $port)"
        else
            echo -e "  ${CYAN}$i)${NC} $service_name"
        fi
        ((i++))
    done

    echo ""
    echo -e "${YELLOW}Digite os números dos serviços separados por espaço${NC}"
    echo -n -e "${GREEN}Exemplo: 1 2 4 → ${NC}"
    read -r selection

    # Coletar serviços selecionados
    local selected_services=()
    local selected_ports=()
    local docker_services=()

    for num in $selection; do
        if [ "$num" -gt 0 ] && [ "$num" -le "${#service_names[@]}" ]; then
            local idx=$((num - 1))
            local service_name="${service_names[$idx]}"
            local info="${services[$service_name]}"

            selected_services+=("$service_name:$info")

            local port=$(echo "$info" | cut -d: -f3)
            if [ "$port" != "-" ]; then
                selected_ports+=("$port")
            fi

            local deps=$(echo "$info" | cut -d: -f4)
            IFS=',' read -ra deps_array <<< "$deps"
            for dep in "${deps_array[@]}"; do
                if [[ ! " ${docker_services[@]} " =~ " ${dep} " ]]; then
                    docker_services+=("$dep")
                fi
            done
        fi
    done

    # Verificar portas
    if [ ${#selected_ports[@]} -gt 0 ]; then
        check_ports "${selected_ports[@]}"
    fi

    # Iniciar Docker services
    start_docker_services "${docker_services[@]}"

    # Iniciar serviços selecionados
    for service_info in "${selected_services[@]}"; do
        local service_name=$(echo "$service_info" | cut -d: -f1)
        local dir=$(echo "$service_info" | cut -d: -f2)
        local cmd=$(echo "$service_info" | cut -d: -f3)
        local port=$(echo "$service_info" | cut -d: -f4)

        start_service "$service_name" "$dir" "$cmd" "$port"
    done
}

setup_builder_cms() {
    echo -e "${BLUE}🎨 Configurando: Builder + CMS (Otimizado)${NC}"
    echo -e "${YELLOW}ℹ  Sem workers, sem OpenSearch, sem LocalStack${NC}"
    echo ""

    check_ports 3000 3005 3011 5500
    start_docker_services postgres-general postgres-cms

    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
    start_service "General-API" "apps/atd-workspace-general-api" "yarn dev" "3005"
    start_service "CMS-API" "apps/atd-workspace-cms-api" "npm run dev" "3011"

    # Renderer em modo build (mais leve) - Usando standalone renderer
    echo -e "${CYAN}→${NC} Configurando Renderer (module federation - static)..."
    if [ ! -d "apps/atd-workspace-renderer/dist" ]; then
        echo -e "${YELLOW}  ℹ  Building renderer pela primeira vez...${NC}"
        cd apps/atd-workspace-renderer
        npm run publish-federation > /tmp/atd-renderer-build.log 2>&1
        cd - > /dev/null
    fi

    # Servir renderer estático (muito mais leve que dev)
    echo -e "${CYAN}→${NC} Servindo Renderer estaticamente..."
    cd apps/atd-workspace-renderer/dist
    nohup npx http-server -p 5500 --cors > /tmp/atd-renderer-static.log 2>&1 &
    echo "Renderer-Static:$!:5500" >> "../../../$PID_FILE"
    cd - > /dev/null

    echo -e "  ${GREEN}✓${NC} Renderer servido estaticamente (PID: $!)"
    echo ""
    echo -e "${GREEN}✓ Configuração otimizada para Builder + CMS${NC}"
    echo -e "${YELLOW}ℹ  Renderer em modo static (~80 MB ao invés de ~800 MB)${NC}"
    echo -e "${YELLOW}ℹ  CMS sem worker (filas não serão processadas)${NC}"
}

setup_builder_cms_hosting() {
    echo -e "${BLUE}🎨 Configurando: Builder + CMS + Hosting (Completo)${NC}"
    echo -e "${YELLOW}ℹ  Setup completo com todas funcionalidades${NC}"
    echo ""

    check_ports 3000 3001 3005 3011 5500
    start_docker_services postgres-general postgres-cms postgres-hosting redis

    start_service "UI" "apps/atd-workspace-ui" "npm run dev" "3000"
    start_service "General-API" "apps/atd-workspace-general-api" "yarn dev" "3005"
    start_service "CMS-API" "apps/atd-workspace-cms-api" "npm run dev" "3011"
    start_service "Hosting-API" "apps/atd-workspace-hosting/api" "PORT=3001 pnpm dev" "3001"
    start_service "Hosting-Worker" "apps/atd-workspace-hosting/api" "pnpm worker" "-"

    # Renderer em modo build (mais leve) - Usando standalone renderer
    echo -e "${CYAN}→${NC} Configurando Renderer (module federation - static)..."
    if [ ! -d "apps/atd-workspace-renderer/dist" ]; then
        echo -e "${YELLOW}  ℹ  Building renderer pela primeira vez...${NC}"
        cd apps/atd-workspace-renderer
        npm run publish-federation > /tmp/atd-renderer-build.log 2>&1
        cd - > /dev/null
    fi

    # Servir renderer estático (muito mais leve que dev)
    echo -e "${CYAN}→${NC} Servindo Renderer estaticamente..."
    cd apps/atd-workspace-renderer/dist
    nohup npx http-server -p 5500 --cors > /tmp/atd-renderer-static.log 2>&1 &
    echo "Renderer-Static:$!:5500" >> "../../../$PID_FILE"
    cd - > /dev/null

    echo -e "  ${GREEN}✓${NC} Renderer servido estaticamente (PID: $!)"
    echo ""
    echo -e "${GREEN}✓ Configuração completa: Builder + CMS + Hosting${NC}"
    echo -e "${YELLOW}ℹ  Renderer em modo static (~80 MB ao invés de ~800 MB)${NC}"
    echo -e "${YELLOW}ℹ  Hosting Worker ativo (processa filas de publicação)${NC}"
    echo -e "${CYAN}ℹ  Endpoints disponíveis:${NC}"
    echo -e "    - UI Builder:    http://localhost:3000"
    echo -e "    - General API:   http://localhost:3005"
    echo -e "    - Hosting API:   http://localhost:3001"
    echo -e "    - CMS API:       http://localhost:3011"
    echo -e "    - Renderer:      http://localhost:5500"
}

# Main loop
main() {
    # Limpar sessão anterior se existir
    rm -f "$PID_FILE" "$SESSION_FILE"

    show_menu
    read -r choice

    case $choice in
        1) setup_ui_builder ;;
        2) setup_auth_users ;;
        3) setup_publishing ;;
        4) setup_cms ;;
        5) setup_crm ;;
        6) setup_backend ;;
        7) setup_fullstack ;;
        8) setup_custom ;;
        9) setup_builder_cms ;;
        10) setup_builder_cms_hosting ;;
        0) echo -e "${GREEN}👋 Até logo!${NC}"; exit 0 ;;
        *) echo -e "${RED}✗ Opção inválida${NC}"; exit 1 ;;
    esac

    # Aguardar serviços iniciarem
    echo ""
    echo -e "${YELLOW}⏳ Aguardando serviços iniciarem...${NC}"
    sleep 5

    # Mostrar informações da sessão
    clear
    echo -e "${GREEN}✓ Setup concluído!${NC}"
    echo ""

    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          🚀 Serviços Rodando                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -f "$PID_FILE" ]; then
        while read line; do
            name=$(echo "$line" | cut -d: -f1)
            port=$(echo "$line" | cut -d: -f3)

            if [ "$port" != "-" ]; then
                echo -e "  ${GREEN}✓${NC} $name → ${CYAN}http://localhost:$port${NC}"
            else
                echo -e "  ${GREEN}✓${NC} $name"
            fi
        done < "$PID_FILE"
    fi

    show_memory_usage
    show_logs

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Comandos úteis:${NC}"
    echo -e "  ${CYAN}Ctrl+C${NC}           - Para todos os serviços"
    echo -e "  ${CYAN}make dev-status${NC}  - Ver status e memória"
    echo -e "  ${CYAN}make dev-logs${NC}    - Ver todos os logs"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Salvar informações da sessão
    echo "started:$(date +%s)" > "$SESSION_FILE"
    echo "profile:$choice" >> "$SESSION_FILE"

    # Aguardar até Ctrl+C
    echo -e "${BLUE}Pressione Ctrl+C para parar todos os serviços...${NC}"
    echo ""

    # Loop infinito para manter script rodando e monitorar processos
    while true; do
        sleep 5

        # Verificar se algum processo morreu
        if [ -f "$PID_FILE" ]; then
            while read line; do
                name=$(echo "$line" | cut -d: -f1)
                pid=$(echo "$line" | cut -d: -f2)

                if ! ps -p $pid > /dev/null 2>&1; then
                    echo ""
                    echo -e "${RED}⚠  AVISO: $name (PID: $pid) parou inesperadamente${NC}"
                    echo -e "${YELLOW}   Ver logs: tail -f /tmp/atd-${name}.log${NC}"
                fi
            done < "$PID_FILE"
        fi
    done
}

# Executar
main
