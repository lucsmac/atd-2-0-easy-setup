# 🚀 Setup Modular de Desenvolvimento

Sistema de desenvolvimento otimizado para reduzir uso de RAM rodando apenas os serviços necessários para cada contexto.

## 📋 Índice

- [Problema](#problema)
- [Solução](#solução)
- [Uso Rápido](#uso-rápido)
- [Perfis Disponíveis](#perfis-disponíveis)
- [Comandos](#comandos)
- [Comparação de Uso de RAM](#comparação-de-uso-de-ram)
- [Dicas e Troubleshooting](#dicas-e-troubleshooting)

## Problema

O setup completo (`make dev`) consome ~4+ GB de RAM rodando 8 processos Node.js simultaneamente:

```
UI (Vite)                  ~500 MB
General API (Express)      ~400 MB
Hosting API (Express)      ~500 MB
Hosting Worker (BullMQ)    ~400 MB
Hosting Renderer (Next.js) ~800 MB
CMS API (Express)          ~500 MB
CMS Worker (BullMQ)        ~400 MB
CRM API (Express)          ~400 MB
────────────────────────────────
TOTAL                      ~3.9 GB
```

Além disso, PostgreSQL (x4) + Redis (x3) + OpenSearch adicionam mais ~1-2 GB.

## Solução

Setup modular que inicia **apenas os serviços necessários** baseado no contexto de desenvolvimento.

### Características

- ✅ Menu interativo para escolher perfil
- ✅ Verificação automática de conflitos de porta
- ✅ Monitoramento de uso de memória em tempo real
- ✅ Logs individuais por serviço
- ✅ Detecção automática de processos que morreram
- ✅ Cleanup automático ao sair (Ctrl+C)
- ✅ Otimização: Renderer em modo static (mais leve)

## Uso Rápido

```bash
# Iniciar setup modular
make dev-modular

# Ver status e uso de RAM
make dev-status

# Ver logs de um serviço específico
make dev-logs

# Parar todos os serviços
make dev-stop
```

## Perfis Disponíveis

### 1. UI + Builder (Leve - ~1.5 GB)

**Quando usar:** Trabalhando na interface do website builder, drag-and-drop, componentes visuais.

**Serviços:**
- UI (Vite) - porta 3000
- General API (autenticação) - porta 3005
- Renderer (module federation, estático) - porta 5500

**Docker:** PostgreSQL General

**Economiza:** Hosting API, Worker, CMS, CRM (~2.5 GB)

### 2. Auth & Usuários (Muito Leve - ~800 MB)

**Quando usar:** Trabalhando em autenticação, gerenciamento de usuários, Cognito.

**Serviços:**
- General API - porta 3005
- UI - porta 3000

**Docker:** PostgreSQL General

**Economiza:** Todo stack de Hosting, CMS, CRM (~3 GB)

### 3. Publishing & Templates (Moderado - ~2 GB)

**Quando usar:** Trabalhando em publicação de sites, templates, sistema de deploy.

**Serviços:**
- Hosting API - porta 3001
- Hosting Worker (BullMQ)
- Renderer (Next.js) - porta 5500
- UI - porta 3000

**Docker:** PostgreSQL Hosting, Redis

**Economiza:** General API, CMS, CRM (~2 GB)

### 4. CMS Completo (Moderado - ~1.8 GB)

**Quando usar:** Trabalhando no sistema de CMS, gerenciamento de conteúdo.

**Serviços:**
- CMS API - porta 3011
- CMS Worker (BullMQ)
- UI - porta 3000

**Docker:** PostgreSQL CMS, Redis CMS Batch, Redis CMS Search, OpenSearch

**Economiza:** General API, Hosting, CRM (~2 GB)

### 5. CRM (Leve - ~1 GB)

**Quando usar:** Trabalhando no sistema de CRM.

**Serviços:**
- CRM API - porta 3010
- UI - porta 3000

**Docker:** PostgreSQL CRM

**Economiza:** Todos outros serviços (~3 GB)

### 6. Backend Completo (Pesado - ~3 GB)

**Quando usar:** Trabalhando em integrações entre APIs, não precisa da UI.

**Serviços:**
- General API - porta 3005
- Hosting API - porta 3001
- Hosting Worker
- Renderer - porta 5500
- CMS API - porta 3011
- CMS Worker
- CRM API - porta 3010

**Docker:** Todos

**Economiza:** UI (~1 GB)

### 7. Fullstack (Muito Pesado - ~4 GB)

**Quando usar:** Precisa de tudo rodando (equivalente a `make dev`).

**Serviços:** Todos

**Docker:** Todos

### 8. Personalizado

**Quando usar:** Precisa de uma combinação específica de serviços.

**Interface:** Menu interativo para selecionar serviços individualmente.

### 9. Builder + CMS (Leve - Otimizado - ~1.5 GB)

**Quando usar:** Trabalhando no builder com integração ao CMS, sem necessidade de processar filas.

**Serviços:**
- UI (Vite) - porta 3000
- General API (autenticação) - porta 3005
- CMS API (sem worker!) - porta 3011
- Renderer (module federation, estático) - porta 5500

**Docker:** PostgreSQL General, PostgreSQL CMS

**Economiza:** Hosting API, Workers (Hosting + CMS), OpenSearch, LocalStack, Redis, CRM (~2.5 GB)

**Otimizações:**
- ✅ Renderer em modo static (~80 MB vs ~800 MB)
- ✅ CMS sem worker (filas não processadas)
- ✅ Sem OpenSearch (busca desabilitada)
- ✅ Sem LocalStack (upload de arquivos via S3 real ou desabilitado)

**Limitações:**
- ❌ Filas do CMS não serão processadas
- ❌ Busca do CMS não funcionará (OpenSearch)
- ❌ Renderer não tem hot-reload (precisa rebuild para mudanças)

### 10. Builder + CMS + Hosting (Moderado - Completo - ~2.5 GB)

**Quando usar:** Desenvolvimento completo com todas funcionalidades - builder, CMS e publicação de sites.

**Serviços:**
- UI (Vite) - porta 3000
- General API (autenticação) - porta 3005
- CMS API - porta 3011
- Hosting API - porta 3001
- Hosting Worker (BullMQ)
- Renderer (module federation, estático) - porta 5500

**Docker:** PostgreSQL General, PostgreSQL CMS, PostgreSQL Hosting, Redis

**Economiza:** OpenSearch, LocalStack, CRM, CMS Worker (~1.5 GB)

**Otimizações:**
- ✅ Renderer em modo static (~80 MB vs ~800 MB)
- ✅ Hosting Worker ativo (processa filas de publicação)
- ✅ Sem OpenSearch (busca do CMS desabilitada)
- ✅ Sem LocalStack (upload de arquivos via S3 real)
- ✅ Sem CMS Worker (filas do CMS não processadas)

**Funcionalidades:**
- ✅ Builder completo (drag-and-drop, editor visual)
- ✅ CMS API (CRUD de conteúdo)
- ✅ Hosting API (sites, pages, templates)
- ✅ Publicação de sites (worker processa filas)
- ✅ Renderer para module federation
- ✅ Autenticação via General API

**Limitações:**
- ❌ Busca do CMS não funcionará (sem OpenSearch)
- ❌ Filas do CMS não processadas (sem CMS Worker)
- ❌ Renderer não tem hot-reload (modo static)

**Ideal para:**
- Desenvolvimento completo do builder
- Testes de publicação e deployment
- Integração entre builder, CMS e hosting
- Workflow completo de criação → publicação

## Comandos

### Iniciar

```bash
make dev-modular
```

Menu interativo aparecerá para escolher o perfil.

### Status e Monitoramento

```bash
# Ver status completo dos serviços
make dev-status
```

Mostra:
- Serviços rodando/parados com PIDs
- Uso de memória por serviço
- Uso total de RAM do sistema
- Top 5 processos por CPU
- Localização dos logs

Exemplo de output:

```
╔════════════════════════════════════════════════╗
║     📊 Status da Sessão de Desenvolvimento    ║
╚════════════════════════════════════════════════╝

Tempo ativo: 1h 23m
Perfil: UI + Builder

Serviços Ativos:

  ✓ Rodando  UI (PID: 12345) → http://localhost:3000
  ✓ Rodando  General-API (PID: 12346) → http://localhost:3005
  ✓ Rodando  Renderer-Static (PID: 12347) → http://localhost:5500

Total: 3 rodando, 0 parados

📊 Uso de Memória:

  UI                          489 MB
  General-API                 412 MB
  Renderer-Static              87 MB
  ─────────────────────────────────
  TOTAL                       988 MB
```

### Visualizar Logs

```bash
# Menu interativo
make dev-logs

# Ou direto (se souber o nome do serviço)
tail -f /tmp/atd-UI.log
tail -f /tmp/atd-General-API.log
```

### Parar Serviços

```bash
# Para todos os serviços
make dev-stop

# Com cleanup de logs
./scripts/dev-stop.sh --clean-logs
```

### Reiniciar

```bash
make dev-restart
```

Equivalente a `make dev-stop && make dev-modular`.

## Comparação de Uso de RAM

| Setup | RAM | Processos | Quando Usar |
|-------|-----|-----------|-------------|
| `make dev` (tradicional) | ~4 GB | 8 | Desenvolvimento fullstack |
| `make dev-modular` (1) | ~1.5 GB | 3 | Trabalhando no UI/Builder |
| `make dev-modular` (2) | ~800 MB | 2 | Trabalhando em Auth |
| `make dev-modular` (3) | ~2 GB | 4 | Trabalhando em Publishing |
| `make dev-modular` (4) | ~1.8 GB | 3 | Trabalhando em CMS |
| `make dev-modular` (5) | ~1 GB | 2 | Trabalhando em CRM |
| `make dev-modular` (9) | ~1.5 GB | 4 | Builder + CMS (otimizado) |
| `make dev-modular` (10) | ~2.5 GB | 6 | Builder + CMS + Hosting (completo) |

**Economia média:** 40-80% de RAM

## Dicas e Troubleshooting

### Conflitos de Porta

Se receber erro de porta em uso:

```bash
# O script detecta automaticamente e pergunta se quer parar

# Ou manualmente:
lsof -ti:3000  # Ver PID usando a porta
kill $(lsof -ti:3000)  # Matar processo
```

### Processo Morreu Inesperadamente

O script monitora processos e avisa se algum morrer:

```
⚠  AVISO: CMS-API (PID: 12345) parou inesperadamente
   Ver logs: tail -f /tmp/atd-CMS-API.log
```

### Renderer em Modo Static vs Dev

**Static (padrão no perfil 1):**
- ✅ Muito mais leve (~80 MB vs ~800 MB)
- ✅ Servidor HTTP simples
- ❌ Não hot-reload
- ✅ Bom para consumir federation na UI

**Dev (perfil 3):**
- ❌ Mais pesado (~800 MB)
- ✅ Hot-reload completo
- ✅ Bom para desenvolver no renderer

Para usar Dev no perfil 1, edite manualmente o script ou use perfil personalizado.

### Logs em Tempo Real

Ver múltiplos logs simultaneamente:

```bash
# Instalar multitail (recomendado)
sudo apt install multitail  # Ubuntu/Debian
brew install multitail       # macOS

# Usar
make dev-logs
# Escolha opção "0" para ver todos
```

### Limpar Sessão Travada

Se o script travou e não limpou os arquivos:

```bash
rm -f .dev-session-pids .dev-session-info
rm -f /tmp/atd-*.log
```

### Performance Extra

Otimizações adicionais:

```bash
# 1. Usar PostgreSQL remoto/compartilhado
#    Edite docker-compose.yml ou .env para apontar para DB remoto
#    Economiza ~400 MB

# 2. Usar Redis remoto
#    Similar ao PostgreSQL
#    Economiza ~100 MB

# 3. Build do Renderer apenas uma vez
#    Já feito automaticamente no perfil 1
#    Economiza ~700 MB
```

### VSCode/IDEs

Configure seu IDE para não indexar os node_modules simultaneamente:

```json
// .vscode/settings.json
{
  "files.watcherExclude": {
    "**/node_modules/**": true
  }
}
```

### Docker Services

O script inicia apenas os serviços Docker necessários para cada perfil.

Para verificar:

```bash
docker-compose ps
```

Para parar manualmente:

```bash
docker-compose stop
```

## Arquitetura do Sistema

### Arquivos

```
scripts/
├── dev-modular.sh   - Script principal interativo
├── dev-status.sh    - Mostra status e uso de RAM
├── dev-logs.sh      - Visualiza logs dos serviços
└── dev-stop.sh      - Para todos os serviços

.dev-session-pids    - PIDs dos processos rodando (gerado)
.dev-session-info    - Metadados da sessão (gerado)

/tmp/atd-*.log       - Logs individuais dos serviços
```

### Fluxo

```
make dev-modular
      ↓
dev-modular.sh (menu interativo)
      ↓
Escolha do perfil
      ↓
Verificação de portas
      ↓
Iniciar Docker services
      ↓
Iniciar processos Node.js em background
      ↓
Salvar PIDs em .dev-session-pids
      ↓
Monitorar processos (loop)
      ↓
Ctrl+C → Cleanup (kill processos)
```

## Migração do Setup Antigo

### Antes (make dev)

```bash
make dev
# Espera ~30s para tudo subir
# Usa ~4 GB RAM
# Logs misturados no terminal
```

### Depois (make dev-modular)

```bash
make dev-modular
# Escolhe perfil interativamente
# Usa ~1-2 GB RAM (depende do perfil)
# Logs separados por serviço

# Em outro terminal
make dev-status  # Ver status
make dev-logs    # Ver logs específicos
```

## Próximos Passos

- [ ] Adicionar suporte para hot-swap de serviços
- [ ] Dashboard web para monitoramento
- [ ] Métricas históricas de uso
- [ ] Perfis salvos personalizados
- [ ] Auto-restart em caso de crash
- [ ] Notificações desktop

## Contribuindo

Para adicionar um novo perfil, edite `scripts/dev-modular.sh`:

```bash
# 1. Adicionar opção no menu (função show_menu)
# 2. Criar função setup_* com lógica do perfil
# 3. Adicionar case no main
```

## Licença

Mesmo que o projeto principal.
