.PHONY: help check setup clone update install install-ui install-general-api install-hosting install-cms install-crm install-renderer
.PHONY: services services-stop services-restart services-status services-logs services-reset
.PHONY: dev dev-ui dev-general-api dev-hosting-api dev-hosting-worker dev-hosting-renderer dev-cms dev-cms-worker dev-crm dev-renderer dev-apis dev-hosting
.PHONY: dev-renderer-federation serve-renderer-federation stop-renderer-federation build-renderer-federation
.PHONY: test test-ui test-general-api test-hosting test-cms test-crm test-renderer test-watch coverage
.PHONY: build build-ui build-general-api build-hosting build-cms build-crm build-renderer
.PHONY: db-migrate db-migrate-general db-migrate-hosting db-migrate-cms db-migrate-crm
.PHONY: db-studio-general db-studio-hosting db-studio-cms db-studio-crm db-reset db-reset-general db-reset-hosting db-reset-cms db-reset-crm db-seed
.PHONY: clean clean-ui clean-general-api clean-hosting clean-cms clean-crm clean-renderer clean-all purge
.PHONY: env-generate env-regenerate env-validate status logs lint lint-fix format format-check
.PHONY: docs docs-build docs-serve docs-open
.PHONY: storybook-ui storybook-renderer storybook-standalone-renderer storybook-build storybook-build-ui storybook-build-renderer storybook-build-standalone-renderer

# Cores para output (funciona em bash)
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ Ajuda

help: ## Exibe esta mensagem de ajuda
	@echo "$(BLUE)Autódromo 2.0 - Comandos Disponíveis$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup Inicial

check: ## Verifica pré-requisitos (Docker, Node.js, Git, Make)
	@./scripts/check-prerequisites.sh

setup: ## Setup completo: clona repos, instala deps, configura tudo
	@./scripts/setup.sh

clone: ## Clona todos os repositórios
	@./scripts/clone-repos.sh

update: ## Atualiza todos os repositórios (git pull)
	@./scripts/clone-repos.sh

reclone: ## Remove apps/ e clona novamente do zero
	@echo "$(RED)⚠  Removendo diretório apps/$(NC)"
	@rm -rf apps/
	@./scripts/clone-repos.sh

install: ## Instala dependências de todos os projetos
	@./scripts/install-deps.sh

install-ui: ## Instala deps apenas da UI
	@cd apps/atd-workspace-ui && npm install --legacy-peer-deps

install-general-api: ## Instala deps apenas da General API
	@cd apps/atd-workspace-general-api && yarn install

install-hosting: ## Instala deps apenas do Hosting
	@cd apps/atd-workspace-hosting && pnpm install

install-cms: ## Instala deps apenas da CMS API
	@cd apps/atd-workspace-cms-api && npm install

install-crm: ## Instala deps apenas da CRM API
	@cd apps/atd-workspace-crm && npm install

install-renderer: ## Instala deps apenas do Renderer standalone
	@cd apps/atd-workspace-renderer && npm install

##@ Serviços Docker

services: ## Inicia todos os serviços Docker (PostgreSQL x4, Redis x3, OpenSearch, LocalStack)
	@echo "$(BLUE)🐳 Iniciando serviços Docker...$(NC)"
	@docker-compose up -d
	@./scripts/wait-for-services.sh

services-stop: ## Para todos os serviços Docker
	@echo "$(YELLOW)⏸  Parando serviços Docker...$(NC)"
	@docker-compose stop

services-restart: ## Reinicia todos os serviços Docker
	@echo "$(YELLOW)🔄 Reiniciando serviços Docker...$(NC)"
	@docker-compose restart
	@./scripts/wait-for-services.sh

services-status: ## Verifica status dos serviços Docker
	@docker-compose ps

services-logs: ## Visualiza logs dos serviços Docker
	@docker-compose logs -f

services-reset: ## ⚠️  Reset completo dos serviços (apaga volumes!)
	@echo "$(RED)⚠️  ATENÇÃO: Isso irá apagar TODOS OS DADOS dos bancos!$(NC)"
	@read -p "Tem certeza? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker-compose down -v
	@echo "$(GREEN)✓ Serviços resetados$(NC)"

##@ Desenvolvimento

dev: services ## Inicia todas as aplicações (UI + APIs + Worker + Renderer)
	@echo "$(BLUE)🚀 Iniciando todas as aplicações...$(NC)"
	@echo "$(YELLOW)ℹ  Use Ctrl+C para parar todos os processos$(NC)"
	@echo ""
	@trap 'kill 0' EXIT; \
	(cd apps/atd-workspace-ui && npm run dev) & \
	(cd apps/atd-workspace-general-api && yarn dev) & \
	(cd apps/atd-workspace-hosting/api && PORT=3001 pnpm dev) & \
	(cd apps/atd-workspace-hosting/api && pnpm dev:worker) & \
	(cd apps/atd-workspace-hosting/renderer && pnpm dev) & \
	(cd apps/atd-workspace-cms-api && npm run dev) & \
	wait

dev-ui: services ## Inicia apenas UI (porta 3000)
	@echo "$(BLUE)🎨 Iniciando UI...$(NC)"
	@cd apps/atd-workspace-ui && npm run dev

dev-general-api: services ## Inicia apenas General API (porta 3005)
	@echo "$(BLUE)🔧 Iniciando General API...$(NC)"
	@cd apps/atd-workspace-general-api && yarn dev

dev-hosting-api: services ## Inicia apenas Hosting API (porta 3001)
	@echo "$(BLUE)🔧 Iniciando Hosting API...$(NC)"
	@cd apps/atd-workspace-hosting/api && PORT=3001 pnpm dev

dev-hosting-worker: services ## Inicia apenas Hosting Worker (BullMQ)
	@echo "$(BLUE)⚙️  Iniciando Hosting Worker...$(NC)"
	@cd apps/atd-workspace-hosting/api && pnpm worker

dev-hosting-renderer: services ## Inicia Hosting Renderer com Module Federation (porta 5500)
	@echo "$(BLUE)🎨 Iniciando Hosting Renderer com Module Federation...$(NC)"
	@echo "$(YELLOW)ℹ  Módulos federados disponíveis em: http://localhost:5500$(NC)"
	@echo "$(YELLOW)ℹ  Configure UI com: VITE_MODULE_FEDERATION_URL='http://localhost:5500/'$(NC)"
	@echo ""
	@cd apps/atd-workspace-hosting/renderer && pnpm dev-federation

dev-cms: services ## Inicia CMS API (porta 3011)
	@echo "$(BLUE)📦 Iniciando CMS API...$(NC)"
	@echo "$(YELLOW)ℹ  API disponível em: http://localhost:3011$(NC)"
	@echo "$(YELLOW)ℹ  BullBoard (filas): http://localhost:3011/admin/queues$(NC)"
	@echo "$(YELLOW)ℹ  OpenSearch Dashboards: http://localhost:5601$(NC)"
	@echo ""
	@cd apps/atd-workspace-cms-api && npm run dev

dev-cms-worker: services ## Inicia CMS Worker (processamento de filas BullMQ)
	@echo "$(BLUE)⚙️  Iniciando CMS Worker...$(NC)"
	@cd apps/atd-workspace-cms-api && npm run dev:worker

dev-crm: services ## Inicia CRM API (porta 3010)
	@echo "$(BLUE)👥 Iniciando CRM API...$(NC)"
	@echo "$(YELLOW)ℹ  API disponível em: http://localhost:3010$(NC)"
	@echo "$(YELLOW)ℹ  Swagger UI: http://localhost:3010/api-docs$(NC)"
	@echo ""
	@cd apps/atd-workspace-crm && npm run dev

dev-renderer: ## Inicia Renderer standalone (porta 3000)
	@echo "$(BLUE)🎨 Iniciando Renderer standalone...$(NC)"
	@echo "$(YELLOW)ℹ  Next.js disponível em: http://localhost:3000$(NC)"
	@echo ""
	@cd apps/atd-workspace-renderer && npm run dev

build-renderer-federation: ## Builda os módulos federados do Renderer (sem servir)
	@echo "$(BLUE)🔨 Buildando módulos federados do Renderer...$(NC)"
	@cd apps/atd-workspace-renderer && npm run publish-federation
	@echo "$(GREEN)✓ Build concluído em apps/atd-workspace-renderer/dist$(NC)"

dev-renderer-federation: build-renderer-federation serve-renderer-federation ## Builda e serve Module Federation (porta 5500)

serve-renderer-federation: ## Serve os módulos federados já buildados (porta 5500)
	@echo "$(BLUE)🚀 Servindo módulos federados do Renderer...$(NC)"
	@echo "$(YELLOW)ℹ  Servidor rodando em: http://localhost:5500$(NC)"
	@echo "$(YELLOW)ℹ  remoteEntry.js: http://localhost:5500/assets/remoteEntry.js$(NC)"
	@echo "$(YELLOW)ℹ  Para parar o servidor: make stop-renderer-federation$(NC)"
	@echo ""
	@if lsof -ti:5500 > /dev/null 2>&1; then \
		echo "$(RED)✗ Porta 5500 já está em uso$(NC)"; \
		echo "$(YELLOW)ℹ  Execute 'make stop-renderer-federation' para parar o servidor$(NC)"; \
		exit 1; \
	fi
	@cd apps/atd-workspace-renderer/dist && nohup http-server -p 5500 --cors > /tmp/renderer-federation.log 2>&1 & echo $$! > /tmp/renderer-federation.pid
	@sleep 2
	@if lsof -ti:5500 > /dev/null 2>&1; then \
		echo "$(GREEN)✓ Servidor iniciado com sucesso!$(NC)"; \
		echo "$(YELLOW)ℹ  Logs: tail -f /tmp/renderer-federation.log$(NC)"; \
	else \
		echo "$(RED)✗ Falha ao iniciar servidor$(NC)"; \
		cat /tmp/renderer-federation.log; \
		exit 1; \
	fi

stop-renderer-federation: ## Para o servidor de módulos federados
	@echo "$(BLUE)🛑 Parando servidor de módulos federados...$(NC)"
	@if [ -f /tmp/renderer-federation.pid ]; then \
		PID=$$(cat /tmp/renderer-federation.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			kill $$PID && echo "$(GREEN)✓ Servidor parado (PID: $$PID)$(NC)"; \
		else \
			echo "$(YELLOW)ℹ  Processo $$PID não está rodando$(NC)"; \
		fi; \
		rm -f /tmp/renderer-federation.pid; \
	else \
		if lsof -ti:5500 > /dev/null 2>&1; then \
			kill $$(lsof -ti:5500) && echo "$(GREEN)✓ Servidor na porta 5500 parado$(NC)"; \
		else \
			echo "$(YELLOW)ℹ  Nenhum servidor rodando na porta 5500$(NC)"; \
		fi; \
	fi
	@rm -f /tmp/renderer-federation.log

dev-apis: services ## Inicia TODAS as APIs (General + Hosting + CMS + CRM)
	@echo "$(BLUE)🔧 Iniciando todas as APIs...$(NC)"
	@echo "$(YELLOW)ℹ  General API: http://localhost:3005$(NC)"
	@echo "$(YELLOW)ℹ  Hosting API: http://localhost:3001$(NC)"
	@echo "$(YELLOW)ℹ  CMS API:     http://localhost:3011$(NC)"
	@echo "$(YELLOW)ℹ  CRM API:     http://localhost:3010$(NC)"
	@echo ""
	@trap 'kill 0' EXIT; \
	(cd apps/atd-workspace-general-api && yarn dev) & \
	(cd apps/atd-workspace-hosting/api && PORT=3001 pnpm dev) & \
	(cd apps/atd-workspace-hosting/api && pnpm worker) & \
	(cd apps/atd-workspace-cms-api && npm run dev) & \
	(cd apps/atd-workspace-crm && npm run dev) & \
	wait

dev-hosting: services ## Inicia Hosting API + Worker + Renderer
	@echo "$(BLUE)🏗️  Iniciando Hosting completo...$(NC)"
	@trap 'kill 0' EXIT; \
	(cd apps/atd-workspace-hosting/api && PORT=3001 pnpm dev) & \
	(cd apps/atd-workspace-hosting/api && pnpm worker) & \
	(cd apps/atd-workspace-hosting/renderer && pnpm dev) & \
	wait

##@ Testes

test: ## Executa testes de todos os projetos
	@echo "$(BLUE)🧪 Executando todos os testes...$(NC)"
	@$(MAKE) test-ui
	@$(MAKE) test-general-api
	@$(MAKE) test-hosting
	@$(MAKE) test-cms
	@$(MAKE) test-crm

test-ui: ## Testes da UI (Vitest)
	@echo "$(BLUE)🧪 Testando UI...$(NC)"
	@cd apps/atd-workspace-ui && npm test -- --run

test-ui-watch: ## Testes da UI em watch mode
	@cd apps/atd-workspace-ui && npm test

test-ui-e2e: ## Testes E2E da UI (Cypress)
	@cd apps/atd-workspace-ui && npm run cy:run-e2e

test-general-api: ## Testes da General API (Vitest)
	@echo "$(BLUE)🧪 Testando General API...$(NC)"
	@cd apps/atd-workspace-general-api && yarn test-ci

test-general-api-watch: ## Testes da General API em watch mode
	@cd apps/atd-workspace-general-api && yarn test

test-hosting: ## Testes do Hosting (API + Renderer)
	@echo "$(BLUE)🧪 Testando Hosting...$(NC)"
	@cd apps/atd-workspace-hosting && pnpm --filter api test-ci
	@cd apps/atd-workspace-hosting && pnpm --filter renderer unit-test-ci

test-hosting-api: ## Testes apenas Hosting API
	@cd apps/atd-workspace-hosting && pnpm --filter api test

test-hosting-renderer: ## Testes apenas Hosting Renderer
	@cd apps/atd-workspace-hosting && pnpm --filter renderer unit-test

test-cms: ## Testes da CMS API (Vitest)
	@echo "$(BLUE)🧪 Testando CMS API...$(NC)"
	@cd apps/atd-workspace-cms-api && npm run test-ci

test-cms-watch: ## Testes da CMS API em watch mode
	@cd apps/atd-workspace-cms-api && npm test

test-crm: ## Testes da CRM API (Vitest)
	@echo "$(BLUE)🧪 Testando CRM API...$(NC)"
	@cd apps/atd-workspace-crm && npm run test-ci

test-crm-watch: ## Testes da CRM API em watch mode
	@cd apps/atd-workspace-crm && npm test

test-renderer: ## Lint do Renderer standalone
	@echo "$(BLUE)🧪 Verificando Renderer standalone (lint)...$(NC)"
	@cd apps/atd-workspace-renderer && npm run lint

coverage: ## Gera relatórios de cobertura de todos os projetos
	@echo "$(BLUE)📊 Gerando relatórios de cobertura...$(NC)"
	@cd apps/atd-workspace-ui && npm run test-ci
	@cd apps/atd-workspace-general-api && yarn coverage
	@cd apps/atd-workspace-hosting && pnpm --filter api test-ci
	@cd apps/atd-workspace-hosting && pnpm --filter renderer unit-test-ci
	@cd apps/atd-workspace-cms-api && npm run test-ci
	@cd apps/atd-workspace-crm && npm run test-ci

##@ Build

build: ## Build de todos os projetos
	@echo "$(BLUE)🏗️  Building todos os projetos...$(NC)"
	@$(MAKE) build-ui
	@$(MAKE) build-general-api
	@$(MAKE) build-hosting
	@$(MAKE) build-cms
	@$(MAKE) build-crm

build-ui: ## Build apenas UI
	@echo "$(BLUE)🏗️  Building UI...$(NC)"
	@cd apps/atd-workspace-ui && npm run build

build-general-api: ## Build apenas General API
	@echo "$(BLUE)🏗️  Building General API...$(NC)"
	@cd apps/atd-workspace-general-api && yarn build

build-hosting: ## Build apenas Hosting
	@echo "$(BLUE)🏗️  Building Hosting...$(NC)"
	@cd apps/atd-workspace-hosting && pnpm --filter api build
	@cd apps/atd-workspace-hosting && pnpm --filter renderer build
	@cd apps/atd-workspace-hosting && pnpm --filter renderer publish-federation

build-cms: ## Build apenas CMS API
	@echo "$(BLUE)🏗️  Building CMS API...$(NC)"
	@cd apps/atd-workspace-cms-api && npm run build

build-crm: ## Build apenas CRM API
	@echo "$(BLUE)🏗️  Building CRM API...$(NC)"
	@cd apps/atd-workspace-crm && npm run build

build-renderer: ## Build do Renderer standalone (Next.js + Module Federation)
	@echo "$(BLUE)🏗️  Building Renderer standalone...$(NC)"
	@cd apps/atd-workspace-renderer && npm run build
	@cd apps/atd-workspace-renderer && npm run publish-federation

##@ Banco de Dados

db-migrate: ## Executa migrations em todos os bancos
	@$(MAKE) db-migrate-general
	@$(MAKE) db-migrate-hosting
	@$(MAKE) db-migrate-cms
	@$(MAKE) db-migrate-crm

db-migrate-general: ## Migration apenas General API
	@echo "$(BLUE)🗄️  Migrando General API database...$(NC)"
	@cd apps/atd-workspace-general-api && npx prisma migrate dev

db-migrate-hosting: ## Migration apenas Hosting API
	@echo "$(BLUE)🗄️  Migrando Hosting API database...$(NC)"
	@cd apps/atd-workspace-hosting && pnpm --filter api run migrate

db-migrate-cms: ## Migration apenas CMS API
	@echo "$(BLUE)🗄️  Migrando CMS API database...$(NC)"
	@cd apps/atd-workspace-cms-api && npx prisma migrate dev

db-migrate-crm: ## Migration apenas CRM API
	@echo "$(BLUE)🗄️  Migrando CRM API database...$(NC)"
	@cd apps/atd-workspace-crm && npx prisma migrate dev

db-studio-general: ## Abre Prisma Studio (General API)
	@echo "$(BLUE)🖥️  Abrindo Prisma Studio (General API)...$(NC)"
	@cd apps/atd-workspace-general-api && npx prisma studio

db-studio-hosting: ## Abre Prisma Studio (Hosting API)
	@echo "$(BLUE)🖥️  Abrindo Prisma Studio (Hosting API)...$(NC)"
	@cd apps/atd-workspace-hosting/api && npx prisma studio

db-studio-cms: ## Abre Prisma Studio (CMS API)
	@echo "$(BLUE)🖥️  Abrindo Prisma Studio (CMS API)...$(NC)"
	@cd apps/atd-workspace-cms-api && npx prisma studio

db-studio-crm: ## Abre Prisma Studio (CRM API)
	@echo "$(BLUE)🖥️  Abrindo Prisma Studio (CRM API)...$(NC)"
	@cd apps/atd-workspace-crm && npx prisma studio

db-reset: ## ⚠️  Reset todos os bancos (apaga dados!)
	@echo "$(RED)⚠️  ATENÇÃO: Isso irá apagar TODOS OS DADOS dos bancos!$(NC)"
	@read -p "Tem certeza? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(MAKE) db-reset-general
	@$(MAKE) db-reset-hosting
	@$(MAKE) db-reset-cms
	@$(MAKE) db-reset-crm

db-reset-general: ## Reset apenas General API database
	@cd apps/atd-workspace-general-api && npx prisma migrate reset --force

db-reset-hosting: ## Reset apenas Hosting API database
	@cd apps/atd-workspace-hosting/api && npx prisma migrate reset --force

db-reset-cms: ## Reset apenas CMS API database
	@cd apps/atd-workspace-cms-api && npx prisma migrate reset --force

db-reset-crm: ## Reset apenas CRM API database
	@cd apps/atd-workspace-crm && npx prisma migrate reset --force

db-seed: ## Popula bancos com dados de exemplo
	@echo "$(BLUE)🌱 Populando bancos com dados de exemplo...$(NC)"
	@echo "$(YELLOW)⚠  Comando db-seed ainda não implementado$(NC)"

##@ Variáveis de Ambiente

env-generate: ## Gera arquivos .env a partir dos templates
	@./scripts/generate-env.sh

env-regenerate: ## Regenera .env (sobrescreve existentes)
	@echo "$(YELLOW)⚠  Sobrescrevendo arquivos .env existentes...$(NC)"
	@rm -f apps/atd-workspace-ui/.env
	@rm -f apps/atd-workspace-general-api/.env
	@rm -f apps/atd-workspace-hosting/api/.env
	@rm -f apps/atd-workspace-cms-api/.env
	@rm -f apps/atd-workspace-crm/.env
	@rm -f apps/atd-workspace-renderer/.env
	@./scripts/generate-env.sh

env-validate: ## Valida se .env tem todas as variáveis necessárias
	@echo "$(BLUE)🔍 Validando arquivos .env...$(NC)"
	@echo "$(YELLOW)⚠  Comando env-validate ainda não implementado$(NC)"

##@ Limpeza

clean: ## Remove node_modules, dist, .next, cache
	@echo "$(YELLOW)🧹 Limpando arquivos temporários...$(NC)"
	@rm -rf apps/atd-workspace-ui/node_modules apps/atd-workspace-ui/dist apps/atd-workspace-ui/.next
	@rm -rf apps/atd-workspace-general-api/node_modules apps/atd-workspace-general-api/dist
	@rm -rf apps/atd-workspace-hosting/node_modules apps/atd-workspace-hosting/api/dist apps/atd-workspace-hosting/renderer/.next
	@rm -rf apps/atd-workspace-cms-api/node_modules apps/atd-workspace-cms-api/dist
	@rm -rf apps/atd-workspace-crm/node_modules apps/atd-workspace-crm/dist
	@rm -rf apps/atd-workspace-renderer/node_modules apps/atd-workspace-renderer/.next apps/atd-workspace-renderer/dist
	@echo "$(GREEN)✓ Limpeza concluída$(NC)"

clean-ui: ## Limpa apenas UI
	@rm -rf apps/atd-workspace-ui/node_modules apps/atd-workspace-ui/dist apps/atd-workspace-ui/.next

clean-general-api: ## Limpa apenas General API
	@rm -rf apps/atd-workspace-general-api/node_modules apps/atd-workspace-general-api/dist

clean-hosting: ## Limpa apenas Hosting
	@rm -rf apps/atd-workspace-hosting/node_modules apps/atd-workspace-hosting/api/dist apps/atd-workspace-hosting/renderer/.next

clean-cms: ## Limpa apenas CMS API
	@rm -rf apps/atd-workspace-cms-api/node_modules apps/atd-workspace-cms-api/dist

clean-crm: ## Limpa apenas CRM API
	@rm -rf apps/atd-workspace-crm/node_modules apps/atd-workspace-crm/dist

clean-renderer: ## Limpa apenas Renderer standalone
	@rm -rf apps/atd-workspace-renderer/node_modules apps/atd-workspace-renderer/.next apps/atd-workspace-renderer/dist

clean-all: ## Limpa tudo + reset de serviços Docker
	@echo "$(RED)⚠️  Limpando TUDO (arquivos + Docker)...$(NC)"
	@read -p "Tem certeza? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(MAKE) clean
	@docker-compose down -v
	@echo "$(GREEN)✓ Limpeza completa concluída$(NC)"

purge: ## ⚠️  Remove apps/ completamente (requer make clone depois)
	@echo "$(RED)⚠️  ATENÇÃO: Isso irá remover o diretório apps/ completamente!$(NC)"
	@read -p "Tem certeza? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@rm -rf apps/
	@echo "$(GREEN)✓ Diretório apps/ removido$(NC)"
	@echo "$(YELLOW)ℹ  Execute 'make clone' para clonar os repositórios novamente$(NC)"

##@ Utilidades

status: ## Verifica status de todos os repos e serviços
	@echo "$(BLUE)📊 Status dos Repositórios$(NC)"
	@echo ""
	@for dir in apps/*/; do \
		if [ -d "$$dir/.git" ]; then \
			echo "$(YELLOW)→$(NC) $$(basename $$dir)"; \
			cd $$dir; \
			echo "  Branch: $$(git branch --show-current)"; \
			git status -s | head -5; \
			cd - > /dev/null; \
			echo ""; \
		fi \
	done
	@echo "$(BLUE)🐳 Status dos Serviços Docker$(NC)"
	@echo ""
	@docker-compose ps

logs: ## Visualiza logs de todas as aplicações
	@echo "$(BLUE)📋 Logs (Ctrl+C para sair)$(NC)"
	@docker-compose logs -f

logs-services: ## Logs apenas dos serviços Docker
	@docker-compose logs -f postgres-general postgres-hosting postgres-cms postgres-crm redis redis-cms-batch redis-cms-search opensearch-cms localstack

logs-ui: ## Logs apenas da UI
	@echo "$(YELLOW)ℹ  Execute em outro terminal: cd apps/atd-workspace-ui && npm run dev$(NC)"

logs-general-api: ## Logs apenas da General API
	@echo "$(YELLOW)ℹ  Execute em outro terminal: cd apps/atd-workspace-general-api && yarn dev$(NC)"

logs-hosting: ## Logs do Hosting (API + Worker + Renderer)
	@echo "$(YELLOW)ℹ  Execute em outro terminal: make dev-hosting$(NC)"

logs-cms: ## Logs da CMS API
	@echo "$(YELLOW)ℹ  Execute em outro terminal: make dev-cms$(NC)"

logs-crm: ## Logs da CRM API
	@echo "$(YELLOW)ℹ  Execute em outro terminal: make dev-crm$(NC)"

lint: ## Executa ESLint em todos os projetos
	@echo "$(BLUE)🔍 Executando linting...$(NC)"
	@cd apps/atd-workspace-ui && npm run lint || true
	@cd apps/atd-workspace-general-api && echo "Linting não configurado" || true
	@cd apps/atd-workspace-hosting && pnpm --filter renderer lint || true

lint-fix: ## Auto-fix de issues do ESLint
	@echo "$(BLUE)🔧 Corrigindo issues de linting...$(NC)"
	@cd apps/atd-workspace-ui && npm run lint -- --fix || true

format: ## Formata código com Prettier
	@echo "$(BLUE)✨ Formatando código...$(NC)"
	@echo "$(YELLOW)⚠  Comando format ainda não implementado$(NC)"

format-check: ## Verifica formatação sem modificar
	@echo "$(BLUE)🔍 Verificando formatação...$(NC)"
	@echo "$(YELLOW)⚠  Comando format-check ainda não implementado$(NC)"

monitor: ## Abre Bull Board (monitoramento de filas)
	@echo "$(BLUE)📊 Bull Board disponível em:$(NC)"
	@echo ""
	@echo "   $(YELLOW)Hosting API:$(NC) http://localhost:3001/bullmq/queues"
	@echo "   $(YELLOW)CMS API:$(NC)     http://localhost:3011/admin/queues"
	@echo ""
	@echo "   Usuário: admin"
	@echo "   Senha: (configurado em BULLBOARD_PASSWORD no .env)"
	@echo ""
	@echo "$(YELLOW)ℹ  Certifique-se de que as APIs estão rodando:$(NC)"
	@echo "   - Hosting: make dev-hosting-api"
	@echo "   - CMS:     make dev-cms"

##@ Documentação

docs-build: ## Builda a documentação Swagger do Hosting API
	@echo "$(BLUE)📚 Building Swagger documentation...$(NC)"
	@cd apps/atd-workspace-hosting/docs && npm run build
	@echo "$(GREEN)✓ Documentação buildada em apps/atd-workspace-hosting/docs/dist$(NC)"

docs-serve: docs-build ## Builda e serve a documentação Swagger (porta 8080)
	@echo "$(BLUE)📚 Servindo documentação Swagger...$(NC)"
	@echo "$(GREEN)✓ Documentação disponível em: $(YELLOW)http://localhost:8080$(NC)"
	@echo "$(YELLOW)ℹ  Pressione Ctrl+C para parar$(NC)"
	@echo ""
	@cd apps/atd-workspace-hosting/docs/dist && npx http-server -p 8080

docs-open: docs-build ## Builda e abre a documentação Swagger no navegador
	@echo "$(BLUE)📚 Abrindo documentação Swagger...$(NC)"
	@xdg-open apps/atd-workspace-hosting/docs/dist/index.html 2>/dev/null || open apps/atd-workspace-hosting/docs/dist/index.html 2>/dev/null || echo "$(YELLOW)Abra manualmente: apps/atd-workspace-hosting/docs/dist/index.html$(NC)"

docs: docs-serve ## Alias para docs-serve

##@ Storybook

storybook-ui: ## Inicia Storybook da UI (porta 6007)
	@echo "$(BLUE)📖 Iniciando Storybook da UI...$(NC)"
	@echo "$(GREEN)✓ Storybook disponível em: $(YELLOW)http://localhost:6007$(NC)"
	@echo "$(YELLOW)ℹ  Pressione Ctrl+C para parar$(NC)"
	@echo ""
	@cd apps/atd-workspace-ui && npm run storybook -- --port 6007

storybook-renderer: ## Inicia Storybook do Hosting Renderer - blocos (porta 6006)
	@echo "$(BLUE)📖 Iniciando Storybook do Hosting Renderer...$(NC)"
	@echo "$(GREEN)✓ Storybook disponível em: $(YELLOW)http://localhost:6006$(NC)"
	@echo "$(YELLOW)ℹ  Pressione Ctrl+C para parar$(NC)"
	@echo ""
	@cd apps/atd-workspace-hosting/renderer && pnpm storybook -- --port 6006

storybook-standalone-renderer: ## Inicia Storybook do Renderer standalone (porta 6008)
	@echo "$(BLUE)📖 Iniciando Storybook do Renderer standalone...$(NC)"
	@echo "$(GREEN)✓ Storybook disponível em: $(YELLOW)http://localhost:6008$(NC)"
	@echo "$(YELLOW)ℹ  Pressione Ctrl+C para parar$(NC)"
	@echo ""
	@cd apps/atd-workspace-renderer && npm run storybook -- --port 6008

storybook-build-ui: ## Builda Storybook da UI
	@echo "$(BLUE)📖 Building Storybook da UI...$(NC)"
	@cd apps/atd-workspace-ui && npm run build-storybook
	@echo "$(GREEN)✓ Storybook da UI buildado em apps/atd-workspace-ui/storybook-static$(NC)"

storybook-build-renderer: ## Builda Storybook do Hosting Renderer
	@echo "$(BLUE)📖 Building Storybook do Hosting Renderer...$(NC)"
	@cd apps/atd-workspace-hosting/renderer && pnpm build-storybook
	@echo "$(GREEN)✓ Storybook do Hosting Renderer buildado em apps/atd-workspace-hosting/renderer/storybook-static$(NC)"

storybook-build-standalone-renderer: ## Builda Storybook do Renderer standalone
	@echo "$(BLUE)📖 Building Storybook do Renderer standalone...$(NC)"
	@cd apps/atd-workspace-renderer && npm run build-storybook
	@echo "$(GREEN)✓ Storybook do Renderer standalone buildado em apps/atd-workspace-renderer/storybook-static$(NC)"

storybook-build: storybook-build-ui storybook-build-renderer storybook-build-standalone-renderer ## Builda todos os Storybooks

