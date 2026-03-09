# 🚀 Quick Start - Docker Otimizado

Guia rápido para usar o setup Docker otimizado.

## ⚡ Início Rápido (3 comandos)

```bash
# 1. Iniciar serviços otimizados
make services-optimized

# 2. Testar se funcionou
make services-optimized-test

# 3. Usar com dev-modular
export ATD_DOCKER_MODE=optimized
make dev-modular
# Escolha opção 9 (Builder + CMS)
```

**Resultado:** ~1.9 GB de RAM total (vs ~5.5 GB original) ✅

## 📊 Comparação Rápida

| Setup | Comando | RAM | Tempo |
|-------|---------|-----|-------|
| **Original** | `make services` | ~4 GB | ~45s |
| **Otimizado Minimal** | `make services-optimized` | ~0.4 GB | ~30s |
| **Otimizado Full** | `make services-optimized-full` | ~2.2 GB | ~40s |

## 🎯 Casos de Uso

### 1. Desenvolvimento Leve (Builder + CMS)

```bash
# Docker otimizado
make services-optimized

# Dev modular com perfil 9
export ATD_DOCKER_MODE=optimized
make dev-modular
# → Escolha opção 9
```

**RAM Total:** ~1.5 GB
- Docker: ~400 MB (PostgreSQL único)
- Node.js: ~1.1 GB (UI + APIs + Renderer static)

### 2. Desenvolvimento Backend (com filas)

```bash
# Docker otimizado com Redis
make services-optimized-backend

# Dev modular
export ATD_DOCKER_MODE=optimized
make dev-modular
# → Escolha perfil que precise de workers
```

**RAM Total:** ~2 GB
- Docker: ~600 MB (PostgreSQL + Redis)
- Node.js: ~1.4 GB

### 3. Desenvolvimento Fullstack

```bash
# Docker otimizado completo
make services-optimized-full

# Dev tradicional
make dev
```

**RAM Total:** ~3.7 GB
- Docker: ~2.2 GB (todos serviços otimizados)
- Node.js: ~1.5 GB

## 🔧 Comandos Essenciais

```bash
# Iniciar
make services-optimized              # Minimal (padrão)
make services-optimized-backend      # Com Redis
make services-optimized-full         # Tudo

# Gerenciar
make services-optimized-status       # Ver status
make services-optimized-test         # Testar databases
make services-optimized-logs         # Ver logs
make services-optimized-stop         # Parar
make services-optimized-reset        # Reset (apaga dados!)
```

## ⚙️ Configuração Inicial

### 1. Atualizar .env Files

**IMPORTANTE:** Connection strings mudam quando usar Docker otimizado!

#### General API (.env)
```env
# Antes (original)
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_general"

# Depois (otimizado) - MESMA!
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_general"
```

#### Hosting API (.env)
```env
# Antes (original)
DATABASE_URL="postgresql://atd:atd123@localhost:5433/atd_hosting"

# Depois (otimizado) - MUDA PORTA!
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_hosting"
```

#### CMS API (.env)
```env
# Antes (original)
DATABASE_URL="postgresql://atd:atd123@localhost:5434/atd_cms"

# Depois (otimizado) - MUDA PORTA!
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_cms"
```

#### CRM API (.env)
```env
# Antes (original)
DATABASE_URL="postgresql://atd:atd123@localhost:5435/atd_crm"

# Depois (otimizado) - MUDA PORTA!
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_crm"
```

### 2. Rodar Migrations

```bash
# Depois de iniciar serviços otimizados
make db-migrate
```

## 🧪 Validação

Após iniciar, valide que tudo funcionou:

```bash
make services-optimized-test
```

Deve mostrar:
```
✓ PostgreSQL otimizado está rodando
✓ PostgreSQL está pronto
✓ atd_general
✓ atd_hosting
✓ atd_cms
✓ atd_crm
✓ Todos os testes passaram!
```

## 🔄 Migrando do Original para Otimizado

### Passo a Passo

```bash
# 1. Parar serviços originais
make services-stop

# 2. Atualizar .env files (mudar portas para 5432)
# Ver seção "Configuração Inicial" acima

# 3. Iniciar serviços otimizados
make services-optimized

# 4. Testar
make services-optimized-test

# 5. Rodar migrations
make db-migrate

# 6. Iniciar aplicações
make dev-modular
```

### Voltar para Original (se necessário)

```bash
# 1. Parar otimizado
make services-optimized-stop

# 2. Reverter .env files (restaurar portas originais)

# 3. Iniciar original
make services

# 4. Continuar normal
make dev
```

## 💡 Dicas

### Usar Otimizado por Padrão

Adicione ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
export ATD_DOCKER_MODE=optimized
```

### Ver Uso de Memória

```bash
docker stats atd-postgres-optimized --no-stream
```

### Acessar PostgreSQL Diretamente

```bash
# Entrar no container
docker exec -it atd-postgres-optimized psql -U atd

# Ou conectar a database específico
docker exec -it atd-postgres-optimized psql -U atd -d atd_general
```

### Verificar Databases

```bash
docker exec atd-postgres-optimized psql -U atd -c "\l"
```

## 🐛 Troubleshooting

### Databases não foram criados

```bash
# Reset e recria
make services-optimized-reset
make services-optimized
make services-optimized-test
```

### Prisma não conecta

Verifique se atualizou as connection strings nos .env:
```bash
# Deve usar porta 5432 para TODOS!
grep DATABASE_URL apps/*/. env
```

### "Port already in use"

```bash
# Ver o que está usando porta 5432
lsof -ti:5432

# Parar containers antigos
docker ps -a | grep postgres
docker rm -f <container-id>
```

## 📈 Benchmarks no Seu Sistema

Teste você mesmo:

```bash
# 1. Iniciar otimizado
time make services-optimized

# 2. Ver uso de RAM
docker stats --no-stream atd-postgres-optimized

# 3. Testar performance
make services-optimized-test
```

## 🎓 Próximos Passos

1. ✅ Testar setup otimizado
2. ✅ Migrar .env files
3. ✅ Rodar migrations
4. ✅ Validar com `make services-optimized-test`
5. ✅ Usar com `make dev-modular` + perfil 9
6. 🚀 Desenvolver com 60% menos RAM!

## 📚 Documentação Completa

- [DOCKER-OPTIMIZED.md](./DOCKER-OPTIMIZED.md) - Documentação detalhada
- [DEV-MODULAR.md](./DEV-MODULAR.md) - Setup modular de desenvolvimento
- [README.md](./README.md) - Documentação geral

## ❓ Dúvidas?

```bash
# Ver todos comandos disponíveis
make help

# Ver status de tudo
make services-optimized-status
make dev-status
```
