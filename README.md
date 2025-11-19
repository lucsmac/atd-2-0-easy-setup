# Autódromo 2.0 - Meta-Repositório

Este é o repositório centralizador do **Autódromo 2.0**, uma plataforma multi-tenant para gerenciamento de concessionárias automotivas. Este meta-repositório orquestra o desenvolvimento local de todos os microsserviços e aplicações do projeto.

## Visão Geral

O Autódromo 2.0 é composto por três aplicações principais:

- **atd-workspace-ui** - Interface de usuário (Next.js + React)
- **atd-workspace-general-api** - API de propósito geral (NestJS)
- **atd-workspace-hosting** - Sistema de hospedagem multi-tenant (NestJS + Module Federation)

Este repositório não contém o código das aplicações em si. Ele fornece:
- Configuração Docker para serviços de infraestrutura (PostgreSQL, Redis, LocalStack)
- Scripts de automação para setup e gerenciamento
- Makefile com comandos para todas as operações comuns
- Templates de configuração (.env)

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                     Autódromo 2.0                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │     UI      │  │  General API │  │  Hosting System │  │
│  │  (Next.js)  │  │   (NestJS)   │  │  (API+Worker)   │  │
│  │   Port 3000 │  │   Port 3005  │  │   Port 3000     │  │
│  └──────┬──────┘  └──────┬───────┘  └────────┬────────┘  │
│         │                │                    │            │
│  ┌──────┴────────────────┴────────────────────┴────────┐  │
│  │            Docker Services (Infraestrutura)         │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │ PostgreSQL General (5432) │ PostgreSQL Hosting (5433)│ │
│  │ Redis (6379)              │ LocalStack (4566)        │ │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
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
2. Clonar os três repositórios de aplicações
3. Iniciar os serviços Docker (PostgreSQL, Redis, LocalStack)
4. Gerar arquivos `.env` a partir dos templates
5. Instalar dependências de todas as aplicações
6. Executar migrations e configurações iniciais

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

#### Serviços Docker
```bash
make services           # Inicia serviços (PostgreSQL, Redis, LocalStack)
make services-stop      # Para serviços
make services-restart   # Reinicia serviços
make services-status    # Status dos serviços
make services-logs      # Visualiza logs dos serviços
make services-reset     # Reset completo (APAGA DADOS!)
```

#### Desenvolvimento
```bash
make dev                # Inicia TODAS as aplicações
make dev-ui             # Inicia apenas UI (porta 3000)
make dev-general-api    # Inicia apenas General API (porta 3005)
make dev-hosting-api    # Inicia apenas Hosting API (porta 3000)
make dev-hosting-worker # Inicia apenas Hosting Worker (BullMQ)
make dev-apis           # Inicia General API + Hosting API + Worker
make dev-hosting        # Inicia Hosting completo (API + Worker + Renderer)
```

#### Testes
```bash
make test               # Executa todos os testes
make test-ui            # Testes da UI
make test-general-api   # Testes da General API
make test-hosting       # Testes do Hosting
make coverage           # Gera relatórios de cobertura
```

#### Build
```bash
make build              # Build de todos os projetos
make build-ui           # Build apenas UI
make build-general-api  # Build apenas General API
make build-hosting      # Build apenas Hosting
```

#### Banco de Dados
```bash
make db-migrate         # Executa migrations em ambos os bancos
make db-migrate-general # Migration apenas General API
make db-migrate-hosting # Migration apenas Hosting
make db-studio-general  # Abre Prisma Studio (General API)
make db-studio-hosting  # Abre Prisma Studio (Hosting)
make db-reset           # Reset de ambos os bancos (APAGA DADOS!)
```

#### Variáveis de Ambiente
```bash
make env-generate       # Gera .env a partir dos templates
make env-regenerate     # Regenera .env (sobrescreve existentes)
```

#### Limpeza
```bash
make clean              # Remove node_modules, dist, cache
make clean-ui           # Limpa apenas UI
make clean-general-api  # Limpa apenas General API
make clean-hosting      # Limpa apenas Hosting
make clean-all          # Limpa tudo + reset Docker
make purge              # Remove apps/ completamente
```

#### Utilidades
```bash
make status             # Status de repos e serviços
make logs               # Visualiza logs
make lint               # Executa linting
make monitor            # Informações sobre Bull Board (monitoramento de filas)
```

## Estrutura do Projeto

```
atd-2-0/
├── apps/                          # Repositórios clonados (não versionado)
│   ├── atd-workspace-ui/          # Interface de usuário
│   ├── atd-workspace-general-api/ # API de propósito geral
│   └── atd-workspace-hosting/     # Sistema de hospedagem
│
├── config/                        # Configurações
│   ├── repos.json                 # Definição dos repositórios
│   └── env-templates/             # Templates de .env
│       ├── ui.env.template
│       ├── general-api.env.template
│       └── hosting-api.env.template
│
├── scripts/                       # Scripts de automação
│   ├── check-prerequisites.sh     # Verifica pré-requisitos
│   ├── clone-repos.sh             # Clona repositórios
│   ├── generate-env.sh            # Gera arquivos .env
│   ├── install-deps.sh            # Instala dependências
│   ├── wait-for-services.sh       # Aguarda serviços Docker
│   └── setup.sh                   # Setup completo
│
├── docs/                          # Documentação adicional
│
├── docker-compose.yml             # Definição de serviços Docker
├── Makefile                       # Comandos de automação
├── .gitignore                     # Ignora apps/ e arquivos sensíveis
└── README.md                      # Este arquivo
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

### Redis (Porta 6379)
- Usado para filas BullMQ no Hosting Worker
- Sem autenticação em desenvolvimento

### LocalStack (Porta 4566)
- Mock de serviços AWS para desenvolvimento local
- Serviços mockados: S3, Cognito, CloudFront
- Dashboard: http://localhost:4566

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
```

### Atualizando Repositórios
```bash
make update           # Faz git pull em todos os repos
make install          # Reinstala dependências se necessário
```

### Após Mudanças no Schema do Banco
```bash
make db-migrate-general  # Se alterou General API
# ou
make db-migrate-hosting  # Se alterou Hosting
```

### Rodando Testes Antes de Commit
```bash
make test             # Testa tudo
# ou
make test-ui          # Testa apenas UI
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

## Portas Utilizadas

| Serviço              | Porta | URL                                |
|----------------------|-------|------------------------------------|
| UI                   | 3000  | http://localhost:3000              |
| General API          | 3005  | http://localhost:3005              |
| Hosting API          | 3000  | http://localhost:3000              |
| Hosting Renderer     | 3001  | http://localhost:3001              |
| PostgreSQL General   | 5432  | localhost:5432                     |
| PostgreSQL Hosting   | 5433  | localhost:5433                     |
| Redis                | 6379  | localhost:6379                     |
| LocalStack           | 4566  | http://localhost:4566              |
| Bull Board           | 3000  | http://localhost:3000/bullmq/queues|

## Monitoramento

### Bull Board (Filas)
- URL: http://localhost:3000/bullmq/queues
- Usuário: `admin`
- Senha: `admin`
- Requer Hosting API rodando

### Prisma Studio
```bash
make db-studio-general  # Visualiza banco General API
make db-studio-hosting  # Visualiza banco Hosting API
```

### Docker Status
```bash
make services-status    # Status dos containers
make services-logs      # Logs em tempo real
```

## Tecnologias

- **Frontend**: Next.js 14, React 18, TypeScript, TailwindCSS
- **Backend**: NestJS, TypeScript, Prisma ORM
- **Bancos**: PostgreSQL 15
- **Cache/Queues**: Redis, BullMQ
- **Autenticação**: AWS Cognito
- **Storage**: AWS S3 (LocalStack em dev)
- **Module Federation**: Webpack Module Federation
- **Testes**: Vitest, Cypress
- **Gerenciadores**: npm, yarn, pnpm

## Contribuindo

1. Certifique-se de que o setup está funcionando: `make setup`
2. Execute os testes: `make test`
3. Execute o linting: `make lint`
4. Commit suas mudanças em cada repositório específico (não neste meta-repo)

## Documentação Adicional

- [UI - Documentação Completa](./apps/atd-workspace-ui/README.md)
- [General API - Documentação Completa](./apps/atd-workspace-general-api/README.md)
- [Hosting - Documentação Completa](./apps/atd-workspace-hosting/README.md)
- [CLAUDE.md - Guia para IA](./CLAUDE.md)

## Suporte

Em caso de problemas:
1. Verifique os logs: `make services-logs` e `make status`
2. Tente resetar: `make services-reset` e `make setup`
3. Consulte a documentação específica de cada aplicação

## Licença

Propriedade da Autoforce. Todos os direitos reservados.
