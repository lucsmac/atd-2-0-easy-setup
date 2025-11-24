.PHONY: help check setup clone update install services services-stop services-restart services-status services-logs services-reset
.PHONY: dev dev-ui dev-general-api dev-hosting-api dev-hosting-worker dev-hosting-renderer dev-apis dev-hosting
.PHONY: test test-ui test-general-api test-hosting test-watch coverage
.PHONY: build build-ui build-general-api build-hosting
.PHONY: db-migrate db-migrate-general db-migrate-hosting db-studio-general db-studio-hosting db-reset db-seed
.PHONY: clean clean-ui clean-general-api clean-hosting clean-all purge
.PHONY: env-generate env-regenerate env-validate status logs lint lint-fix format format-check
.PHONY: docs docs-build docs-serve docs-open
.PHONY: storybook-ui storybook-renderer storybook-build storybook-build-ui storybook-build-renderer

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

##@ Serviços Docker

services: ## Inicia todos os serviços Docker (PostgreSQL x2, Redis, LocalStack)
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
	(cd apps/atd-workspace-hosting/api && pnpm worker) & \
	(cd apps/atd-workspace-hosting/renderer && pnpm dev) & \
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

dev-apis: services ## Inicia General API + Hosting API + Worker
	@echo "$(BLUE)🔧 Iniciando todas as APIs...$(NC)"
	@trap 'kill 0' EXIT; \
	(cd apps/atd-workspace-general-api && yarn dev) & \
	(cd apps/atd-workspace-hosting/api && PORT=3001 pnpm dev) & \
	(cd apps/atd-workspace-hosting/api && pnpm worker) & \
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

coverage: ## Gera relatórios de cobertura de todos os projetos
	@echo "$(BLUE)📊 Gerando relatórios de cobertura...$(NC)"
	@cd apps/atd-workspace-ui && npm run test-ci
	@cd apps/atd-workspace-general-api && yarn coverage
	@cd apps/atd-workspace-hosting && pnpm --filter api test-ci
	@cd apps/atd-workspace-hosting && pnpm --filter renderer unit-test-ci

##@ Build

build: ## Build de todos os projetos
	@echo "$(BLUE)🏗️  Building todos os projetos...$(NC)"
	@$(MAKE) build-ui
	@$(MAKE) build-general-api
	@$(MAKE) build-hosting

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

##@ Banco de Dados

db-migrate: ## Executa migrations em ambos os bancos
	@$(MAKE) db-migrate-general
	@$(MAKE) db-migrate-hosting

db-migrate-general: ## Migration apenas General API
	@echo "$(BLUE)🗄️  Migrando General API database...$(NC)"
	@cd apps/atd-workspace-general-api && npx prisma migrate dev

db-migrate-hosting: ## Migration apenas Hosting API
	@echo "$(BLUE)🗄️  Migrando Hosting API database...$(NC)"
	@cd apps/atd-workspace-hosting && pnpm --filter api run migrate

db-studio-general: ## Abre Prisma Studio (General API)
	@echo "$(BLUE)🖥️  Abrindo Prisma Studio (General API)...$(NC)"
	@cd apps/atd-workspace-general-api && npx prisma studio

db-studio-hosting: ## Abre Prisma Studio (Hosting API)
	@echo "$(BLUE)🖥️  Abrindo Prisma Studio (Hosting API)...$(NC)"
	@cd apps/atd-workspace-hosting/api && npx prisma studio

db-reset: ## ⚠️  Reset ambos os bancos (apaga dados!)
	@echo "$(RED)⚠️  ATENÇÃO: Isso irá apagar TODOS OS DADOS dos bancos!$(NC)"
	@read -p "Tem certeza? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(MAKE) db-reset-general
	@$(MAKE) db-reset-hosting

db-reset-general: ## Reset apenas General API database
	@cd apps/atd-workspace-general-api && npx prisma migrate reset --force

db-reset-hosting: ## Reset apenas Hosting API database
	@cd apps/atd-workspace-hosting/api && npx prisma migrate reset --force

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
	@echo "$(GREEN)✓ Limpeza concluída$(NC)"

clean-ui: ## Limpa apenas UI
	@rm -rf apps/atd-workspace-ui/node_modules apps/atd-workspace-ui/dist apps/atd-workspace-ui/.next

clean-general-api: ## Limpa apenas General API
	@rm -rf apps/atd-workspace-general-api/node_modules apps/atd-workspace-general-api/dist

clean-hosting: ## Limpa apenas Hosting
	@rm -rf apps/atd-workspace-hosting/node_modules apps/atd-workspace-hosting/api/dist apps/atd-workspace-hosting/renderer/.next

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
	@docker-compose logs -f postgres-general postgres-hosting redis localstack

logs-ui: ## Logs apenas da UI
	@echo "$(YELLOW)ℹ  Execute em outro terminal: cd apps/atd-workspace-ui && npm run dev$(NC)"

logs-general-api: ## Logs apenas da General API
	@echo "$(YELLOW)ℹ  Execute em outro terminal: cd apps/atd-workspace-general-api && yarn dev$(NC)"

logs-hosting: ## Logs do Hosting (API + Worker + Renderer)
	@echo "$(YELLOW)ℹ  Execute em outro terminal: make dev-hosting$(NC)"

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
	@echo "   $(YELLOW)http://localhost:3000/bullmq/queues$(NC)"
	@echo "   Usuário: admin"
	@echo "   Senha: admin"
	@echo ""
	@echo "$(YELLOW)ℹ  Certifique-se de que o Hosting API está rodando (make dev-hosting-api)$(NC)"

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

storybook-renderer: ## Inicia Storybook do Renderer - blocos (porta 6006)
	@echo "$(BLUE)📖 Iniciando Storybook do Renderer...$(NC)"
	@echo "$(GREEN)✓ Storybook disponível em: $(YELLOW)http://localhost:6006$(NC)"
	@echo "$(YELLOW)ℹ  Pressione Ctrl+C para parar$(NC)"
	@echo ""
	@cd apps/atd-workspace-hosting/renderer && pnpm storybook -- --port 6006

storybook-build-ui: ## Builda Storybook da UI
	@echo "$(BLUE)📖 Building Storybook da UI...$(NC)"
	@cd apps/atd-workspace-ui && npm run build-storybook
	@echo "$(GREEN)✓ Storybook da UI buildado em apps/atd-workspace-ui/storybook-static$(NC)"

storybook-build-renderer: ## Builda Storybook do Renderer
	@echo "$(BLUE)📖 Building Storybook do Renderer...$(NC)"
	@cd apps/atd-workspace-hosting/renderer && pnpm build-storybook
	@echo "$(GREEN)✓ Storybook do Renderer buildado em apps/atd-workspace-hosting/renderer/storybook-static$(NC)"

storybook-build: storybook-build-ui storybook-build-renderer ## Builda ambos os Storybooks

