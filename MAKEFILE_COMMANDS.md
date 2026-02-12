# Comandos Make - CMS API e CRM API

Este documento lista todos os comandos Make adicionados para suportar as APIs CMS e CRM.

## Visão Geral

Foram adicionados comandos completos para gerenciar o ciclo de vida das APIs CMS e CRM, seguindo o mesmo padrão das APIs existentes (UI, General, Hosting).

## Lista Completa de Comandos

### 📦 Instalação

```bash
make install-cms        # Instala dependências apenas da CMS API
make install-crm        # Instala dependências apenas da CRM API
```

### 🚀 Desenvolvimento

```bash
make dev-cms            # Inicia CMS API (porta 3011)
                        # - API: http://localhost:3011
                        # - BullBoard: http://localhost:3011/admin/queues
                        # - OpenSearch Dashboards: http://localhost:5601

make dev-cms-worker     # Inicia CMS Worker (processamento de filas BullMQ)
                        # - Worker para batch-sync, entry-process, cleanup
                        # - Conecta ao Redis nas portas 6380 e 6381

make dev-crm            # Inicia CRM API (porta 3010)
                        # - API: http://localhost:3010
                        # - Swagger UI: http://localhost:3010/api-docs
                        # - Inclui worker BullMQ automaticamente
```

### 🧪 Testes

```bash
make test-cms           # Executa testes da CMS API (Vitest)
make test-cms-watch     # Testes da CMS API em watch mode

make test-crm           # Executa testes da CRM API (Vitest)
make test-crm-watch     # Testes da CRM API em watch mode

make test               # ATUALIZADO: Agora inclui CMS e CRM
make coverage           # ATUALIZADO: Gera coverage de todos (incluindo CMS e CRM)
```

### 🏗️ Build

```bash
make build-cms          # Build apenas CMS API (TypeScript → dist/)
make build-crm          # Build apenas CRM API (TypeScript → dist/)

make build              # ATUALIZADO: Agora inclui CMS e CRM
```

### 🗄️ Banco de Dados

#### Migrations

```bash
make db-migrate-cms     # Aplica migrations do Prisma (CMS API)
make db-migrate-crm     # Aplica migrations do Prisma (CRM API)

make db-migrate         # ATUALIZADO: Migra TODOS os bancos (General, Hosting, CMS, CRM)
```

#### Prisma Studio

```bash
make db-studio-cms      # Abre Prisma Studio para CMS API
                        # - Interface visual: http://localhost:5555
                        # - Visualiza/edita: ContentType, ContentField, ContentEntry, etc

make db-studio-crm      # Abre Prisma Studio para CRM API
                        # - Interface visual: http://localhost:5555
                        # - Visualiza/edita: Contact, Conversion, Activity, Team, etc
```

#### Reset (⚠️ Cuidado!)

```bash
make db-reset-cms       # Reset apenas banco CMS (apaga TODOS os dados!)
make db-reset-crm       # Reset apenas banco CRM (apaga TODOS os dados!)

make db-reset           # ATUALIZADO: Reseta TODOS os bancos (General, Hosting, CMS, CRM)
```

### 🧹 Limpeza

```bash
make clean-cms          # Remove node_modules e dist/ da CMS API
make clean-crm          # Remove node_modules e dist/ da CRM API

make clean              # ATUALIZADO: Limpa TODOS os projetos (incluindo CMS e CRM)
```

### 📋 Logs

```bash
make logs-cms           # Mostra onde ver logs da CMS API
make logs-crm           # Mostra onde ver logs da CRM API

make logs-services      # ATUALIZADO: Logs de TODOS os serviços Docker
                        # Inclui: postgres-cms, postgres-crm, redis-cms-batch,
                        # redis-cms-search, opensearch-cms
```

### 🐳 Serviços Docker

```bash
make services           # ATUALIZADO: Agora sobe TODOS os serviços
                        # - PostgreSQL x4 (general, hosting, cms, crm)
                        # - Redis x3 (main, cms-batch, cms-search)
                        # - OpenSearch + Dashboards (CMS)
                        # - LocalStack (AWS mock)
```

## Exemplos de Uso

### Setup Inicial CMS API

```bash
# 1. Subir infraestrutura
make services

# 2. Instalar dependências
make install-cms

# 3. Copiar .env
cd apps/atd-workspace-cms-api
cp .env.sample .env

# 4. Executar migrations
make db-migrate-cms

# 5. Iniciar API
make dev-cms

# 6. Em outro terminal, iniciar worker (opcional)
make dev-cms-worker
```

### Setup Inicial CRM API

```bash
# 1. Subir infraestrutura
make services

# 2. Instalar dependências
make install-crm

# 3. Copiar .env
cd apps/atd-workspace-crm
cp .env.sample .env

# 4. Executar migrations
make db-migrate-crm

# 5. Iniciar API (worker inicia automaticamente)
make dev-crm
```

### Workflow de Desenvolvimento

**Trabalhando apenas na CMS API:**
```bash
make dev-cms            # Terminal 1: API
make dev-cms-worker     # Terminal 2: Worker (se necessário)
make db-studio-cms      # Terminal 3: Visualizar dados
```

**Trabalhando apenas na CRM API:**
```bash
make dev-crm            # Terminal 1: API + Worker
make db-studio-crm      # Terminal 2: Visualizar dados
```

**Rodando todas as APIs:**
```bash
make services           # Infraestrutura
make dev-general-api    # Terminal 1
make dev-hosting        # Terminal 2
make dev-cms            # Terminal 3
make dev-crm            # Terminal 4
make dev-ui             # Terminal 5
```

### Testes Antes de Commit

```bash
# Testar apenas CMS
make test-cms

# Testar apenas CRM
make test-crm

# Testar TUDO
make test              # Roda UI, General, Hosting, CMS, CRM

# Coverage completo
make coverage          # Gera relatórios de todos os projetos
```

### Troubleshooting

**Limpar tudo e começar do zero:**
```bash
# Limpar arquivos
make clean-cms
make clean-crm

# Resetar bancos (cuidado!)
make db-reset-cms
make db-reset-crm

# Reinstalar
make install-cms
make install-crm

# Migrations novamente
make db-migrate-cms
make db-migrate-crm
```

**Verificar serviços Docker:**
```bash
make services-status    # Status de todos os containers
make logs-services      # Logs em tempo real
```

**Problemas com migrations:**
```bash
# CMS
cd apps/atd-workspace-cms-api
npx prisma migrate reset --force
npx prisma migrate dev

# CRM
cd apps/atd-workspace-crm
npx prisma migrate reset --force
npx prisma migrate dev
```

## Comandos Modificados

Os seguintes comandos existentes foram **atualizados** para incluir CMS e CRM:

| Comando | O que mudou |
|---------|-------------|
| `make services` | Agora sobe PostgreSQL CMS/CRM, Redis CMS, OpenSearch |
| `make test` | Agora testa CMS e CRM também |
| `make coverage` | Agora inclui coverage de CMS e CRM |
| `make build` | Agora builda CMS e CRM |
| `make db-migrate` | Agora migra CMS e CRM |
| `make db-reset` | Agora reseta CMS e CRM (cuidado!) |
| `make clean` | Agora limpa CMS e CRM |
| `make logs-services` | Agora inclui logs dos novos serviços Docker |

## Atalhos Úteis

```bash
# Ver TODOS os comandos disponíveis
make help

# Status geral do projeto
make status

# Verificar pré-requisitos
make check

# Setup completo (primeira vez)
make setup
```

## Estrutura de Portas

| Serviço | Porta | Comando para Iniciar |
|---------|-------|---------------------|
| **CMS API** | 3011 | `make dev-cms` |
| **CRM API** | 3010 | `make dev-crm` |
| **PostgreSQL CMS** | 5434 | `make services` |
| **PostgreSQL CRM** | 5435 | `make services` |
| **Redis CMS Batch** | 6380 | `make services` |
| **Redis CMS Search** | 6381 | `make services` |
| **OpenSearch** | 9200 | `make services` |
| **OpenSearch Dashboards** | 5601 | `make services` |
| **BullBoard CMS** | 3011/admin/queues | `make dev-cms` |
| **Swagger CRM** | 3010/api-docs | `make dev-crm` |
| **Prisma Studio** | 5555 | `make db-studio-cms` ou `make db-studio-crm` |

## Notas Importantes

1. **CMS Worker**: O worker da CMS API precisa ser iniciado separadamente com `make dev-cms-worker`
2. **CRM Worker**: O worker da CRM API inicia automaticamente junto com a API (`make dev-crm`)
3. **Redis Compartilhado**: O CRM compartilha o Redis principal (porta 6379) com o Hosting
4. **Redis Dedicado**: A CMS tem seus próprios Redis dedicados (portas 6380 e 6381)
5. **OpenSearch**: Usado exclusivamente pela CMS API para busca full-text

## Integração com Outros Comandos

Os comandos CMS/CRM se integram perfeitamente com os existentes:

```bash
# Instalar todas as dependências
make install            # Instala: UI, General, Hosting, CMS, CRM

# Testar tudo
make test              # Testa: UI, General, Hosting, CMS, CRM

# Buildar tudo
make build             # Builda: UI, General, Hosting, CMS, CRM

# Migrar todos os bancos
make db-migrate        # Migra: General, Hosting, CMS, CRM

# Limpar tudo
make clean             # Limpa: UI, General, Hosting, CMS, CRM
```

---

**Documentação Completa:**
- [README Principal](./README.md)
- [README CMS API](./apps/atd-workspace-cms-api/README.md)
- [README CRM API](./apps/atd-workspace-crm/README.md)
