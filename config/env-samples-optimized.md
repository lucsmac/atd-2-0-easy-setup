# Configuração de .env para Docker Otimizado

Quando usar `docker-compose.optimized.yml`, os databases estão todos no **mesmo container PostgreSQL** (porta 5432).

## Diferenças nas Connection Strings

### Original (docker-compose.yml)
```env
# General API - porta 5432
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_general"

# Hosting API - porta 5433
DATABASE_URL="postgresql://atd:atd123@localhost:5433/atd_hosting"

# CMS API - porta 5434
DATABASE_URL="postgresql://atd:atd123@localhost:5434/atd_cms"

# CRM API - porta 5435
DATABASE_URL="postgresql://atd:atd123@localhost:5435/atd_crm"
```

### Otimizado (docker-compose.optimized.yml)
```env
# Todos usam porta 5432, mas databases diferentes

# General API
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_general"

# Hosting API
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_hosting"

# CMS API
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_cms"

# CRM API
DATABASE_URL="postgresql://atd:atd123@localhost:5432/atd_crm"
```

## Redis

### Original
```env
# Hosting API - Redis principal (porta 6379)
REDIS_URL="redis://localhost:6379"

# CMS API - Redis batch (porta 6380)
REDIS_BATCH_URL="redis://localhost:6380"

# CMS API - Redis search (porta 6381)
REDIS_SEARCH_URL="redis://localhost:6381"
```

### Otimizado
```env
# Todos usam o mesmo Redis por padrão (economia de memória)
# Se precisar separação, use profiles

# Hosting API e CMS API - Redis único (porta 6379)
REDIS_URL="redis://localhost:6379"

# CMS batch (apenas com --profile full)
REDIS_BATCH_URL="redis://localhost:6380"

# CMS search (apenas com --profile full)
REDIS_SEARCH_URL="redis://localhost:6381"
```

## OpenSearch

```env
# Mesma configuração em ambos
OPENSEARCH_URL="http://localhost:9200"
```

## Migração Automática

Para facilitar, você pode usar variáveis de ambiente:

```bash
# .envrc ou shell profile
export ATD_DOCKER_MODE="optimized"  # ou "standard"
```

E scripts podem detectar automaticamente qual usar.
