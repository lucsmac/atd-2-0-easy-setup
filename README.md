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

#### Documentação
```bash
make docs               # Builda e serve documentação Swagger (porta 8080)
make docs-build         # Apenas builda a documentação
make docs-serve         # Builda e serve a documentação (porta 8080)
make docs-open          # Builda e abre a documentação no navegador
```

#### Storybook
```bash
make storybook-renderer # Storybook do Renderer - blocos (porta 6006)
make storybook-ui       # Storybook da UI - componentes (porta 6007)
make storybook-build    # Builda ambos os Storybooks
make storybook-build-ui # Builda apenas Storybook da UI
make storybook-build-renderer # Builda apenas Storybook do Renderer
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

## Module Federation (Blocos do Page Builder)

O projeto usa **Webpack Module Federation** para compartilhar componentes entre aplicações:

- **Renderer (Host):** Contém e expõe 23+ blocos/seções React
  - Localização: `apps/atd-workspace-hosting/renderer/src/sections/`
  - Exemplos: Hero, Gallery, FormContentImage, Header, Footer, etc.
  - Expõe via: `vite.federation.config.ts`

- **UI (Consumer):** Consome os blocos remotamente no page builder
  - Configuração: `VITE_MODULE_FEDERATION_URL` no `.env`
  - Padrão: CloudFront (staging/produção) - não requer renderer local
  - Desenvolvimento: `http://localhost:5500/` - requer renderer rodando

**Vantagens:**
- UI e renderer podem ser desenvolvidos/deployados independentemente
- Blocos podem ser atualizados sem rebuild da UI
- Mesmos componentes usados no builder e nos sites publicados
- Hot reload durante desenvolvimento de blocos

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
```

### Desenvolvendo Blocos do Page Builder

Os blocos/componentes do page builder estão no **Hosting Renderer**, não na UI. Por padrão, a UI consome blocos remotos do CloudFront (staging/produção).

**Para usar blocos remotos (padrão - não precisa rodar renderer local):**
```bash
make dev-ui           # UI consome blocos do CloudFront
```
- ✅ Mais rápido, não precisa rodar renderer
- ❌ Não pode testar alterações nos blocos

**Para desenvolver blocos localmente:**

1. Inicie o renderer:
```bash
make dev-hosting-renderer  # Sobe renderer em modo dev
```

2. Configure a UI para usar renderer local em `apps/atd-workspace-ui/.env`:
```env
# Comentar:
# VITE_MODULE_FEDERATION_URL='https://d379stbdytb00m.cloudfront.net'

# Descomentar:
VITE_MODULE_FEDERATION_URL='http://localhost:5500/'
```

3. Reinicie a UI para aplicar mudanças:
```bash
make dev-ui
```

Agora a UI carregará blocos do renderer local com hot reload!

### Visualizando Componentes no Storybook

O projeto possui **dois Storybooks** para desenvolvimento isolado de componentes:

**Storybook do Renderer (blocos do page builder):**
```bash
make storybook-renderer
```
- Porta: http://localhost:6006
- Contém: Todos os 23+ blocos/seções (Hero, Gallery, FormContentImage, etc.)
- Útil para: Desenvolver e testar blocos visuais isoladamente

**Storybook da UI (componentes internos):**
```bash
make storybook-ui
```
- Porta: http://localhost:6007
- Contém: Componentes da UI (Sidebar, Navbar, MediaSelect, etc.)
- Útil para: Desenvolver componentes da interface do page builder

**Dica:** Você pode rodar ambos Storybooks simultaneamente em portas diferentes!

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

**Causa comum:** Configuração de `VITE_MODULE_FEDERATION_URL` apontando para localhost mas renderer não está rodando.

## Portas Utilizadas

| Serviço              | Porta | URL                                |
|----------------------|-------|------------------------------------|
| UI                   | 3000  | http://localhost:3000              |
| General API          | 3005  | http://localhost:3005              |
| Hosting API          | 3001  | http://localhost:3001              |
| Hosting Renderer     | *     | http://localhost:* (Next.js auto)  |
| Storybook Renderer   | 6006  | http://localhost:6006              |
| Storybook UI         | 6007  | http://localhost:6007              |
| Swagger Docs         | 8080  | http://localhost:8080              |
| PostgreSQL General   | 5432  | localhost:5432                     |
| PostgreSQL Hosting   | 5433  | localhost:5433                     |
| Redis                | 6379  | localhost:6379                     |
| LocalStack           | 4566  | http://localhost:4566              |
| Bull Board           | 3001  | http://localhost:3001/bullmq/queues|

**Notas:**
- O Hosting Renderer usa Next.js que detecta automaticamente portas disponíveis. Verifique a saída do console ao iniciar para confirmar a porta.
- Os Storybooks usam portas diferentes (6006 e 6007) e podem rodar simultaneamente.

## Monitoramento

### Bull Board (Filas)
- URL: http://localhost:3001/bullmq/queues
- Usuário/Senha: Definidos por `BULLBOARD_USER` e `BULLBOARD_PASSWORD` no `.env`
- Requer Hosting API rodando
- Monitora: Jobs de publicação, status, filas, erros

### Storybook (Componentes)
```bash
make storybook-renderer  # Blocos do page builder (porta 6006)
make storybook-ui        # Componentes da UI (porta 6007)
```
- Renderer: http://localhost:6006
- UI: http://localhost:6007
- Visualiza: Componentes isolados com controles interativos
- Hot reload: Mudanças aparecem automaticamente
- Pode rodar ambos simultaneamente

### Prisma Studio (Banco de Dados)
```bash
make db-studio-general  # Visualiza banco General API
make db-studio-hosting  # Visualiza banco Hosting API
```
- Interface web para visualizar e editar dados do PostgreSQL

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
- [Hosting - Processo de Publicação](./apps/atd-workspace-hosting/PUBLICATION_PROCESS.md)
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
