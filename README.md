# Autódromo 2.0 - Meta-Repositório

Este é o repositório centralizador do **Autódromo 2.0**, uma plataforma multi-tenant para gerenciamento de concessionárias automotivas. Este meta-repositório orquestra o desenvolvimento local de todos os microsserviços e aplicações do projeto.

## Visão Geral

O Autódromo 2.0 é composto por seis aplicações principais:

| Aplicação | Descrição | Tecnologias | Porta |
|-----------|-----------|-------------|-------|
| **atd-workspace-ui** | Interface de usuário (page builder) | Vite + React | 3000 |
| **atd-workspace-general-api** | API de autenticação e contas | Express + TypeScript | 3005 |
| **atd-workspace-hosting** | Sistema de hospedagem e publicação | Express + Next.js | 3001 |
| **atd-workspace-cms-api** | API de gerenciamento de conteúdo | Express + OpenSearch | 3011 |
| **atd-workspace-crm** | API de CRM | Express + BullMQ | 3010 |
| **atd-workspace-renderer** | Renderer standalone (Next.js) | Next.js + Module Federation | 3000/5500 |

Este repositório não contém o código das aplicações em si. Ele fornece:
- Configuração Docker para serviços de infraestrutura (PostgreSQL x4, Redis x3, OpenSearch, LocalStack)
- Scripts de automação para setup e gerenciamento
- Makefile com comandos para todas as operações comuns
- Templates de configuração (.env)

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Autódromo 2.0                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌──────────┐  ┌─────────────┐  ┌──────────────┐  ┌──────────┐  ┌────────┐  ┌────────┐
│  │    UI    │  │ General API │  │   Hosting    │  │ CMS API  │  │  CRM   │  │Renderer│
│  │  (Vite)  │  │  (Express)  │  │(Express+Next)│  │(Express) │  │(Express│  │(Next.js│
│  │Port 3000 │  │  Port 3005  │  │  Port 3001   │  │Port 3011 │  │Port 3010│ │Port 5500│
│  └─────┬────┘  └──────┬──────┘  └───────┬──────┘  └─────┬────┘  └────┬───┘  └───┬────┘
│        │              │                  │                │            │          │
│  ┌─────┴──────────────┴──────────────────┴────────────────┴────────────┴──────────┴─┐
│  │                   Docker Services (Infraestrutura)                               │
│  ├──────────────────────────────────────────────────────────────────────────────────┤
│  │ PostgreSQL General (5432)  │ PostgreSQL Hosting (5433)                           │
│  │ PostgreSQL CMS (5434)      │ PostgreSQL CRM (5435)                               │
│  │ Redis Main (6379)          │ Redis CMS Batch (6380) │ Redis CMS Search (6381)    │
│  │ OpenSearch CMS (9200)      │ LocalStack AWS (4566)                               │
│  └──────────────────────────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Pré-requisitos

- **Docker** e **Docker Compose**
- **Node.js** 18+ (recomendado: 20.x)
- **npm**, **yarn** e **pnpm**
- **Git**
- **Make**
- **jq** (para parsing de JSON nos scripts)

## Setup Inicial

### 1. Clone este repositório

```bash
git clone https://github.com/autoforce/atd-2-0.git
cd atd-2-0
```

### 2. Execute o setup completo

```bash
make setup
```

Este comando irá:
1. Verificar todos os pré-requisitos
2. Clonar os seis repositórios de aplicações
3. Iniciar os serviços Docker (PostgreSQL x4, Redis x3, OpenSearch, LocalStack)
4. Gerar arquivos `.env` a partir dos templates
5. Instalar dependências de todas as aplicações
6. Executar migrations e configurações iniciais (Prisma generate para todas as APIs)

### 3. Configure credenciais reais

Edite os arquivos `.env` gerados e configure credenciais reais para:

**apps/atd-workspace-ui/.env**
```env
NEXT_PUBLIC_PUSHER_KEY=sua_chave_pusher
NEXT_PUBLIC_PUSHER_CLUSTER=sua_cluster_pusher
```

**apps/atd-workspace-general-api/.env**
```env
# SMTP
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USER=seu_usuario
MAIL_PASSWORD=sua_senha

# Pusher
PUSHER_APP_ID=seu_app_id
PUSHER_KEY=sua_chave
PUSHER_SECRET=seu_secret
PUSHER_CLUSTER=sua_cluster
```

**apps/atd-workspace-hosting/api/.env**
```env
PUSHER_APP_ID=seu_app_id
PUSHER_KEY=sua_chave
PUSHER_SECRET=seu_secret
PUSHER_CLUSTER=sua_cluster
```

**apps/atd-workspace-cms-api/.env**
```env
# AWS Cognito
COGNITO_USER_POOL_ID=us-east-1_xxxxx
COGNITO_CLIENT_ID=xxxxx

# AWS S3
AWS_REGION=us-east-1
AWS_S3_BUCKET=seu_bucket
```

**apps/atd-workspace-crm/.env**
```env
# AWS Cognito
COGNITO_USER_POOL_ID=us-east-1_xxxxx
COGNITO_CLIENT_ID=xxxxx
```

### 4. Inicie as aplicações

```bash
make dev
```

## Comandos Disponíveis

Para ver todos os comandos disponíveis:
```bash
make help
```

### Comandos Principais

#### Setup e Instalação
```bash
make check              # Verifica pré-requisitos
make setup              # Setup completo (recomendado na primeira vez)
make clone              # Clona/atualiza repositórios
make install            # Instala dependências
make reclone            # Remove apps/ e clona novamente
```

#### Instalação Individual
```bash
make install-ui             # Instala deps da UI
make install-general-api    # Instala deps da General API
make install-hosting        # Instala deps do Hosting
make install-cms            # Instala deps da CMS API
make install-crm            # Instala deps da CRM API
make install-renderer       # Instala deps do Renderer standalone
```

#### Serviços Docker
```bash
make services           # Inicia serviços (PostgreSQL x4, Redis x3, OpenSearch, LocalStack)
make services-stop      # Para serviços
make services-restart   # Reinicia serviços
make services-status    # Status dos serviços
make services-logs      # Visualiza logs dos serviços
make services-reset     # Reset completo (APAGA DADOS!)
```

#### ⚡ Serviços Docker Otimizados (Economia de RAM)

**Novo!** Setup Docker otimizado que reduz uso de RAM em até **62%** (~2.5 GB vs ~4 GB).

```bash
# Minimal (~400 MB) - Apenas PostgreSQL único
make services-optimized
make services-optimized-minimal

# Backend (~600 MB) - PostgreSQL + Redis
make services-optimized-backend

# Full (~2.5 GB) - Todos serviços otimizados
make services-optimized-full

# Gerenciamento
make services-optimized-stop
make services-optimized-status
make services-optimized-logs
make services-optimized-reset
```

**Principais otimizações:**
- 🔥 **PostgreSQL único** ao invés de 4 containers (economia de ~1.2 GB)
- 🔥 **Redis com limites** de memória
- 🔥 **OpenSearch com heap reduzido** (512 MB vs 1 GB)
- 🔥 **LocalStack slim** (400 MB vs 600 MB)
- 🔥 **tmpfs para logs** (I/O mais rápido)

📖 **[Documentação completa Docker Otimizado](./DOCKER-OPTIMIZED.md)**

**Uso com dev-modular:**
```bash
# Usar Docker otimizado automaticamente
export ATD_DOCKER_MODE=optimized
make dev-modular
```

#### Desenvolvimento
```bash
make dev                   # Inicia TODAS as aplicações
make dev-ui                # Inicia apenas UI (porta 3000)
make dev-general-api       # Inicia apenas General API (porta 3005)
make dev-hosting-api       # Inicia apenas Hosting API (porta 3001)
make dev-hosting-worker    # Inicia apenas Hosting Worker (BullMQ)
make dev-hosting-renderer  # Inicia Hosting Renderer Federation (porta 5500)
make dev-cms               # Inicia CMS API (porta 3011)
make dev-cms-worker        # Inicia CMS Worker (BullMQ)
make dev-crm               # Inicia CRM API (porta 3010)
make dev-renderer          # Inicia Renderer standalone (porta 3000)
make dev-renderer-federation # Inicia Renderer Federation (porta 5500)
make dev-apis              # Inicia TODAS as APIs (General + Hosting + CMS + CRM)
make dev-hosting           # Inicia Hosting completo (API + Worker + Renderer)
```

#### ⚡ Desenvolvimento Modular (Uso Reduzido de RAM)

**Novo!** Setup otimizado que roda apenas os serviços necessários para cada contexto, reduzindo uso de RAM em 50-80%.

```bash
make dev-modular        # Menu interativo para escolher perfil
make dev-status         # Ver status e uso de RAM dos serviços
make dev-logs           # Visualizar logs dos serviços
make dev-stop           # Parar todos os serviços
make dev-restart        # Reiniciar setup modular
```

**Perfis disponíveis:**
1. **UI + Builder** (~1.5 GB) - Desenvolvimento de interface
2. **Auth & Usuários** (~800 MB) - Autenticação e Cognito
3. **Publishing & Templates** (~2 GB) - Sistema de publicação
4. **CMS Completo** (~1.8 GB) - Gerenciamento de conteúdo
5. **CRM** (~1 GB) - Sistema de CRM
6. **Backend Completo** (~3 GB) - Todas APIs sem UI
7. **Fullstack** (~4 GB) - Equivalente ao `make dev`
8. **Personalizado** - Escolha serviços individualmente
9. **Builder + CMS** (~1.5 GB) - UI + CMS sem workers/OpenSearch
10. **Builder + CMS + Hosting** (~2.5 GB) - Desenvolvimento completo ⭐ Novo!

📖 **[Documentação completa do Setup Modular](./DEV-MODULAR.md)**

**Comparação:**
- `make dev`: ~4 GB RAM, 8 processos Node.js
- `make dev-modular`: ~1-2 GB RAM (dependendo do perfil)

#### Testes
```bash
make test               # Executa todos os testes
make test-ui            # Testes da UI
make test-ui-watch      # Testes da UI em watch mode
make test-ui-e2e        # Testes E2E da UI (Cypress)
make test-general-api   # Testes da General API
make test-hosting       # Testes do Hosting (API + Renderer)
make test-hosting-api   # Testes apenas Hosting API
make test-hosting-renderer # Testes apenas Hosting Renderer
make test-cms           # Testes da CMS API
make test-cms-watch     # Testes da CMS API em watch mode
make test-crm           # Testes da CRM API
make test-crm-watch     # Testes da CRM API em watch mode
make test-renderer      # Lint do Renderer standalone
make coverage           # Gera relatórios de cobertura
```

#### Build
```bash
make build              # Build de todos os projetos
make build-ui           # Build apenas UI
make build-general-api  # Build apenas General API
make build-hosting      # Build apenas Hosting
make build-cms          # Build apenas CMS API
make build-crm          # Build apenas CRM API
make build-renderer     # Build Renderer standalone (Next.js + Module Federation)
```

#### Banco de Dados
```bash
make db-migrate         # Executa migrations em todos os bancos
make db-migrate-general # Migration apenas General API
make db-migrate-hosting # Migration apenas Hosting
make db-migrate-cms     # Migration apenas CMS API
make db-migrate-crm     # Migration apenas CRM API
make db-studio-general  # Abre Prisma Studio (General API)
make db-studio-hosting  # Abre Prisma Studio (Hosting)
make db-studio-cms      # Abre Prisma Studio (CMS API)
make db-studio-crm      # Abre Prisma Studio (CRM API)
make db-reset           # Reset de todos os bancos (APAGA DADOS!)
make db-reset-general   # Reset apenas General API
make db-reset-hosting   # Reset apenas Hosting
make db-reset-cms       # Reset apenas CMS API
make db-reset-crm       # Reset apenas CRM API
```

#### Variáveis de Ambiente
```bash
make env-generate       # Gera .env a partir dos templates
make env-regenerate     # Regenera .env (sobrescreve existentes)
```

#### Limpeza
```bash
make clean              # Remove node_modules, dist, cache de todos
make clean-ui           # Limpa apenas UI
make clean-general-api  # Limpa apenas General API
make clean-hosting      # Limpa apenas Hosting
make clean-cms          # Limpa apenas CMS API
make clean-crm          # Limpa apenas CRM API
make clean-renderer     # Limpa apenas Renderer standalone
make clean-all          # Limpa tudo + reset Docker
make purge              # Remove apps/ completamente
```

#### Documentação
```bash
make docs               # Builda e serve documentação Swagger (porta 8080)
make docs-build         # Apenas builda a documentação
make docs-serve         # Builda e serve a documentação (porta 8080)
make docs-open          # Builda e abre a documentação no navegador
```

#### Storybook
```bash
make storybook-ui                     # Storybook da UI (porta 6007)
make storybook-renderer               # Storybook do Hosting Renderer (porta 6006)
make storybook-standalone-renderer    # Storybook do Renderer standalone (porta 6008)
make storybook-build                  # Builda todos os Storybooks
make storybook-build-ui               # Builda Storybook da UI
make storybook-build-renderer         # Builda Storybook do Hosting Renderer
make storybook-build-standalone-renderer # Builda Storybook do Renderer standalone
```

#### Utilidades
```bash
make status             # Status de repos e serviços
make logs               # Visualiza logs
make logs-services      # Logs apenas dos serviços Docker
make lint               # Executa linting
make lint-fix           # Auto-fix de linting
make monitor            # Informações sobre Bull Board (monitoramento de filas)
```

## Estrutura do Projeto

```
atd-2-0/
├── apps/                              # Repositórios clonados (não versionado)
│   ├── atd-workspace-ui/              # Interface de usuário
│   ├── atd-workspace-general-api/     # API de autenticação
│   ├── atd-workspace-hosting/         # Sistema de hospedagem
│   ├── atd-workspace-cms-api/         # API de conteúdo
│   ├── atd-workspace-crm/             # API de CRM
│   └── atd-workspace-renderer/        # Renderer standalone
│
├── config/                            # Configurações
│   ├── repos.json                     # Definição dos repositórios
│   └── env-templates/                 # Templates de .env
│       ├── ui.env.template
│       ├── general-api.env.template
│       ├── hosting-api.env.template
│       ├── cms-api.env.template
│       ├── crm.env.template
│       └── renderer.env.template
│
├── scripts/                           # Scripts de automação
│   ├── check-prerequisites.sh         # Verifica pré-requisitos
│   ├── clone-repos.sh                 # Clona repositórios
│   ├── generate-env.sh                # Gera arquivos .env
│   ├── install-deps.sh                # Instala dependências
│   ├── wait-for-services.sh           # Aguarda serviços Docker
│   └── setup.sh                       # Setup completo
│
├── docs/                              # Documentação adicional
│
├── docker-compose.yml                 # Definição de serviços Docker
├── Makefile                           # Comandos de automação
├── .gitignore                         # Ignora apps/ e arquivos sensíveis
└── README.md                          # Este arquivo
```

## Serviços Docker

Este meta-repositório provisiona os seguintes serviços via Docker:

### PostgreSQL General (Porta 5432)
- Usado pela General API
- Database: `atd_general`
- User/Password: `atd` / `atd123`

### PostgreSQL Hosting (Porta 5433)
- Usado pela Hosting API
- Database: `atd_hosting`
- User/Password: `atd` / `atd123`

### PostgreSQL CMS (Porta 5434)
- Usado pela CMS API
- Database: `atd_cms`
- User/Password: `atd` / `atd123`

### PostgreSQL CRM (Porta 5435)
- Usado pela CRM API
- Database: `atd_crm`
- User/Password: `atd` / `atd123`

### Redis Main (Porta 6379)
- Usado para filas BullMQ no Hosting Worker e CRM API
- Compartilhado entre Hosting e CRM
- Sem autenticação em desenvolvimento

### Redis CMS Batch (Porta 6380)
- Usado para processamento em lote da CMS API
- Filas: batch-sync, entry-process, cleanup
- Sem autenticação em desenvolvimento

### Redis CMS Search (Porta 6381)
- Usado para indexação de busca da CMS API
- Fila: search-indexer
- Sem autenticação em desenvolvimento

### OpenSearch CMS (Porta 9200)
- Motor de busca full-text para CMS API
- Interface: OpenSearch Dashboards (porta 5601)
- URL: http://localhost:9200
- Dashboards: http://localhost:5601

### LocalStack (Porta 4566)
- Mock de serviços AWS para desenvolvimento local
- Serviços mockados: S3, Cognito, CloudFront
- Dashboard: http://localhost:4566

## Module Federation (Blocos do Page Builder)

O projeto usa **Vite Module Federation** para compartilhar componentes entre aplicações.

### Como Funciona

**Renderer (Host):** Contém e expõe 23+ blocos/seções React
- Localização: `apps/atd-workspace-hosting/renderer/src/sections/`
- Exemplos: Hero, Gallery, FormContentImage, Header, Footer, etc.
- Expõe via: `vite.federation.config.ts`
- Servidor: Vite dev server na porta **5500**

**Renderer Standalone:** Versão independente do renderer
- Localização: `apps/atd-workspace-renderer/`
- Mesmos blocos, configuração independente
- Usado para desenvolvimento isolado

**UI (Consumer):** Consome os blocos remotamente no page builder
- Configuração: `VITE_MODULE_FEDERATION_URL` no `.env`
- **Padrão**: CloudFront (staging/produção) - não requer renderer local
- **Desenvolvimento local**: `http://localhost:5500` - requer `make dev-hosting-renderer`

### Variável de Ambiente Importante

```env
# apps/atd-workspace-ui/.env

# Opção 1: Usar blocos remotos do CloudFront (PADRÃO - recomendado)
VITE_MODULE_FEDERATION_URL='https://d379stbdytb00m.cloudfront.net'
# Mais rápido, não precisa rodar renderer local
# Não permite testar alterações nos blocos

# Opção 2: Usar blocos do renderer local (desenvolvimento de blocos)
VITE_MODULE_FEDERATION_URL='http://localhost:5500'
# Permite desenvolver e testar blocos com hot reload
# Requer rodar: make dev-hosting-renderer ou make dev-renderer-federation
```

### Comandos Rápidos

```bash
# Para usar blocos remotos (padrão):
make dev-ui  # Apenas isso, blocos vêm do CloudFront

# Para desenvolver blocos localmente:
make dev-hosting-renderer  # Terminal 1: Inicia Vite Federation (porta 5500)
# Edite .env conforme acima (VITE_MODULE_FEDERATION_URL='http://localhost:5500')
make dev-ui                # Terminal 2: Inicia UI consumindo blocos locais
```

## Fluxo de Trabalho Típico

### Início do Dia
```bash
make services         # Inicia serviços Docker
make dev              # Inicia todas as aplicações
```

### Trabalhando em uma Aplicação Específica
```bash
make services         # Garante que serviços estão rodando
make dev-ui           # Trabalha apenas na UI
# ou
make dev-general-api  # Trabalha apenas na General API
# ou
make dev-hosting      # Trabalha no Hosting (API + Worker + Renderer)
# ou
make dev-cms          # Trabalha na CMS API
# ou
make dev-crm          # Trabalha na CRM API
```

### Desenvolvendo Blocos do Page Builder

Os blocos/componentes do page builder estão no **Hosting Renderer**, não na UI. Por padrão, a UI consome blocos remotos do CloudFront (staging/produção).

**Para usar blocos remotos (padrão - não precisa rodar renderer local):**
```bash
make dev-ui           # UI consome blocos do CloudFront
```

**Para desenvolver blocos localmente:**

1. Inicie o renderer com Module Federation:
```bash
make dev-hosting-renderer  # Sobe Vite Federation Server na porta 5500
```

2. Configure a UI para usar renderer local em `apps/atd-workspace-ui/.env`:
```env
VITE_MODULE_FEDERATION_URL='http://localhost:5500'
```

3. Reinicie a UI para aplicar mudanças:
```bash
make dev-ui
```

### Visualizando Componentes no Storybook

O projeto possui **três Storybooks** para desenvolvimento isolado de componentes:

**Storybook do Hosting Renderer (blocos do page builder):**
```bash
make storybook-renderer
```
- Porta: http://localhost:6006
- Contém: Todos os 23+ blocos/seções (Hero, Gallery, FormContentImage, etc.)

**Storybook da UI (componentes internos):**
```bash
make storybook-ui
```
- Porta: http://localhost:6007
- Contém: Componentes da UI (Sidebar, Navbar, MediaSelect, etc.)

**Storybook do Renderer standalone:**
```bash
make storybook-standalone-renderer
```
- Porta: http://localhost:6008
- Contém: Blocos do renderer standalone

### Atualizando Repositórios
```bash
make update           # Faz git pull em todos os repos
make install          # Reinstala dependências se necessário
```

### Após Mudanças no Schema do Banco
```bash
make db-migrate-general  # Se alterou General API
make db-migrate-hosting  # Se alterou Hosting
make db-migrate-cms      # Se alterou CMS API
make db-migrate-crm      # Se alterou CRM API
```

### Rodando Testes Antes de Commit
```bash
make test             # Testa tudo
# ou testes individuais
make test-ui
make test-general-api
make test-hosting
make test-cms
make test-crm
```

### Final do Dia
```bash
Ctrl+C                # Para aplicações em execução
make services-stop    # Para serviços Docker
```

## Troubleshooting

### Serviços Docker não iniciam
```bash
make services-reset   # Reset completo dos serviços
make services         # Inicia novamente
```

### Erro de dependências
```bash
make clean            # Limpa node_modules e caches
make install          # Reinstala dependências
```

### Banco de dados corrompido
```bash
make db-reset         # ATENÇÃO: apaga todos os dados!
```

### Repositórios corrompidos
```bash
make reclone          # Remove apps/ e clona tudo novamente
```

### Problemas com .env
```bash
make env-regenerate   # Regenera todos os .env
```

### Blocos do page builder não carregam

**Problema:** UI não mostra blocos ou mostra erro de Module Federation.

**Solução 1 - Usando blocos remotos (padrão):**
```bash
# Verifique apps/atd-workspace-ui/.env:
VITE_MODULE_FEDERATION_URL='https://d379stbdytb00m.cloudfront.net'
# (deve estar apontando para CloudFront, não localhost)
```

**Solução 2 - Usando blocos locais:**
```bash
# 1. Certifique-se que o renderer está rodando:
make dev-hosting-renderer

# 2. Verifique apps/atd-workspace-ui/.env:
VITE_MODULE_FEDERATION_URL='http://localhost:5500/'

# 3. Reinicie a UI:
make dev-ui
```

## Portas Utilizadas

| Serviço                      | Porta | URL                                |
|------------------------------|-------|------------------------------------|
| UI                           | 3000  | http://localhost:3000              |
| General API                  | 3005  | http://localhost:3005              |
| Hosting API                  | 3001  | http://localhost:3001              |
| CRM API                      | 3010  | http://localhost:3010              |
| CMS API                      | 3011  | http://localhost:3011              |
| Hosting Renderer (Next.js)   | 3002  | http://localhost:3002 (auto)       |
| Hosting Renderer (Federation)| 5500  | http://localhost:5500              |
| Renderer standalone          | 3000  | http://localhost:3000              |
| Renderer Federation          | 5500  | http://localhost:5500              |
| Storybook Hosting Renderer   | 6006  | http://localhost:6006              |
| Storybook UI                 | 6007  | http://localhost:6007              |
| Storybook Renderer standalone| 6008  | http://localhost:6008              |
| Swagger Docs                 | 8080  | http://localhost:8080              |
| PostgreSQL General           | 5432  | localhost:5432                     |
| PostgreSQL Hosting           | 5433  | localhost:5433                     |
| PostgreSQL CMS               | 5434  | localhost:5434                     |
| PostgreSQL CRM               | 5435  | localhost:5435                     |
| Redis Main (Hosting+CRM)     | 6379  | localhost:6379                     |
| Redis CMS Batch              | 6380  | localhost:6380                     |
| Redis CMS Search             | 6381  | localhost:6381                     |
| OpenSearch CMS               | 9200  | http://localhost:9200              |
| OpenSearch Dashboards        | 5601  | http://localhost:5601              |
| LocalStack                   | 4566  | http://localhost:4566              |
| Bull Board (Hosting)         | 3001  | http://localhost:3001/bullmq/queues|
| Bull Board (CMS)             | 3011  | http://localhost:3011/admin/queues |
| Swagger UI (CRM)             | 3010  | http://localhost:3010/api-docs     |

## Monitoramento

### Bull Board (Filas)

**Hosting API:**
- URL: http://localhost:3001/bullmq/queues
- Usuário/Senha: Definidos por `BULLBOARD_USER` e `BULLBOARD_PASSWORD` no `.env`

**CMS API:**
- URL: http://localhost:3011/admin/queues
- Monitora: Jobs de processamento de conteúdo, indexação, etc.

### Storybook (Componentes)
```bash
make storybook-renderer            # Blocos do Hosting (porta 6006)
make storybook-ui                  # Componentes da UI (porta 6007)
make storybook-standalone-renderer # Blocos do Renderer standalone (porta 6008)
```

### Prisma Studio (Banco de Dados)
```bash
make db-studio-general  # Visualiza banco General API
make db-studio-hosting  # Visualiza banco Hosting API
make db-studio-cms      # Visualiza banco CMS API
make db-studio-crm      # Visualiza banco CRM API
```

### Docker Status
```bash
make services-status    # Status dos containers
make services-logs      # Logs em tempo real
```

## Tecnologias

| Componente | Stack |
|-----------|-------|
| **UI** | Vite, React 18, TypeScript, Jotai, React Query, Radix UI, Tailwind CSS, CraftJS |
| **General API** | Express, TypeScript, Prisma (PostgreSQL), AWS Cognito, AWS S3 |
| **Hosting** | Express, TypeScript, Prisma (PostgreSQL), BullMQ (Redis), Next.js 14 |
| **CMS API** | Express, TypeScript, Prisma (PostgreSQL), BullMQ (Redis), OpenSearch |
| **CRM API** | Express, TypeScript, Prisma (PostgreSQL), BullMQ (Redis) |
| **Renderer** | Next.js 14, React 18, TypeScript, Tailwind CSS, Module Federation |

**Gerenciadores de pacotes:**
- UI, CMS API, CRM API, Renderer: **npm**
- General API: **yarn**
- Hosting: **pnpm**

## Contribuindo

1. Certifique-se de que o setup está funcionando: `make setup`
2. Execute os testes: `make test`
3. Execute o linting: `make lint`
4. Commit suas mudanças em cada repositório específico (não neste meta-repo)

## Documentação Adicional

- [UI - Documentação Completa](./apps/atd-workspace-ui/README.md)
- [General API - Documentação Completa](./apps/atd-workspace-general-api/README.md)
- [Hosting - Documentação Completa](./apps/atd-workspace-hosting/README.md)
- [Hosting - Processo de Publicação](./apps/atd-workspace-hosting/PUBLICATION_PROCESS.md)
- [CMS API - Documentação Completa](./apps/atd-workspace-cms-api/README.md)
- [CRM API - Documentação Completa](./apps/atd-workspace-crm/README.md)
- [Renderer - Documentação Completa](./apps/atd-workspace-renderer/README.md)
- [CLAUDE.md - Guia para IA](./CLAUDE.md)

### Documentação Swagger

Para acessar a documentação interativa das APIs:

```bash
make docs  # Abre documentação Swagger em http://localhost:8080
```

A documentação Swagger fornece:
- Especificação completa de todos os endpoints
- Schemas de request/response
- Exemplos de uso
- Interface interativa para testar endpoints

## Suporte

Em caso de problemas:
1. Verifique os logs: `make services-logs` e `make status`
2. Tente resetar: `make services-reset` e `make setup`
3. Consulte a documentação específica de cada aplicação

## Licença

Propriedade da Autoforce. Todos os direitos reservados.
