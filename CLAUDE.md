# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**Autódromo 2.0** is a multi-project repository containing three independent but interconnected workspace applications that together form a complete website building and hosting platform:

1. **atd-workspace-ui** - React-based website builder interface
2. **atd-workspace-general-api** - User and account management API
3. **atd-workspace-hosting** - Website processing, publishing, and hosting system

Each workspace has its own CLAUDE.md file with detailed documentation:
- `/atd-workspace-ui/CLAUDE.md`
- `/atd-workspace-general-api/CLAUDE.md`
- `/atd-workspace-hosting/CLAUDE.md`

## System Architecture

### High-Level Data Flow

```
User (Browser)
    ↓
atd-workspace-ui (React + Vite)
    ↓ Authentication ↓ Account/User Management ↓ Site Building
    ↓                ↓                          ↓
atd-workspace-general-api                atd-workspace-hosting
(Express + Cognito)                      (Express + Next.js)
    ↓                                        ↓
AWS Cognito                              PostgreSQL + Redis
PostgreSQL                               AWS S3 + CloudFront
```

### Component Responsibilities

**atd-workspace-ui** (Frontend):
- User-facing website builder interface
- Drag-and-drop page builder using CraftJS
- Page template and site template management
- Authentication UI (login, password reset)
- Multi-tenant account and user management UI
- Consumes federated modules from hosting's renderer

**atd-workspace-general-api** (Auth & Accounts):
- AWS Cognito integration for authentication
- Account management (multi-tenant)
- User management (create, update, delete users in Cognito)
- Authorization middleware (admin vs account-level access)
- File uploads to S3 with image compression

**atd-workspace-hosting** (Publishing):
- Site and page management
- Page builder backend (stores compressed page structures)
- Template system (page templates and site templates)
- Design system management (styleguides)
- Asynchronous publishing queue (BullMQ + Redis)
- Static site generation and deployment to S3/CloudFront
- Renderer (Next.js + React) with federated sections/components

### Technology Stack

| Component | Stack |
|-----------|-------|
| UI | Vite, React 18, TypeScript, Jotai, React Query, Radix UI, Tailwind CSS, CraftJS, Slate.js |
| General API | Express, TypeScript, Prisma (PostgreSQL), AWS Cognito, AWS S3, Nodemailer |
| Hosting | Express, TypeScript, Prisma (PostgreSQL), BullMQ (Redis), Next.js 14, AWS S3/CloudFront |

### Authentication & Authorization Flow

1. User authenticates via UI → calls general-api
2. General-api validates credentials with AWS Cognito
3. Cognito returns access token with user groups (`admin` or `account`)
4. UI stores token and includes it in all subsequent requests
5. Both APIs use `authenticationMiddleware` to validate Cognito tokens
6. Authorization middleware checks user groups for protected resources

## Working with This Repository

### Which Workspace to Use?

**When working on authentication, users, or accounts:**
- Navigate to: `atd-workspace-general-api/`
- Refer to: `atd-workspace-general-api/CLAUDE.md`

**When working on site building UI, page builder interface:**
- Navigate to: `atd-workspace-ui/`
- Refer to: `atd-workspace-ui/CLAUDE.md`

**When working on site publishing, rendering, or deployment:**
- Navigate to: `atd-workspace-hosting/`
- Refer to: `atd-workspace-hosting/CLAUDE.md`

### Starting All Services

Each workspace runs independently. For full platform functionality:

```bash
# Terminal 1: General API (port 3005)
cd atd-workspace-general-api
yarn install
cp .env.sample .env
# Configure .env with AWS Cognito credentials
npx prisma migrate dev
yarn dev

# Terminal 2: Hosting API (requires static fonts first)
cd atd-workspace-hosting
pnpm install
pnpm --filter static run fonts
pnpm --filter api run migrate
# Configure api/.env with AWS and Redis credentials
pnpm --filter api dev

# Terminal 3: Hosting Worker (for async publishing)
cd atd-workspace-hosting
pnpm --filter api dev:worker

# Terminal 4: Hosting Renderer (Next.js for federated modules)
cd atd-workspace-hosting
pnpm --filter renderer dev

# Terminal 5: UI
cd atd-workspace-ui
npm install
cp .env.sample .env
# Configure .env with API URLs
npm run dev
```

### Testing Strategy

Each workspace has its own test suite:

**UI Tests:**
```bash
cd atd-workspace-ui
npm test                    # Vitest unit tests
npm run cy:run-e2e         # Cypress E2E tests
```

**General API Tests:**
```bash
cd atd-workspace-general-api
yarn test                  # Vitest integration tests
yarn coverage             # Coverage report
```

**Hosting Tests:**
```bash
cd atd-workspace-hosting
pnpm --filter api test            # API tests
pnpm --filter renderer unit-test  # Renderer tests
pnpm --filter e2e test-e2e       # E2E tests
```

## Key Integration Points

### Module Federation
- UI consumes remote sections from hosting's renderer
- Configured via `VITE_MODULE_FEDERATION_URL` in UI
- Renderer exposes sections via Vite federation

### Shared Data Models
- Users stored in AWS Cognito (managed by general-api)
- User-to-Account mapping via `custom:account` attribute in Cognito
- Sites, pages, templates stored in hosting's PostgreSQL
- Account data replicated or referenced across systems

### API Endpoints
- General API: User/account management, authentication
- Hosting API: Site/page/template CRUD, deployment triggers

### Real-time Updates
- Hosting uses Pusher for deployment status updates
- UI subscribes to Pusher channels for live feedback

## Environment Variables

Each workspace requires its own `.env` file. See each workspace's `.env.sample` for required variables.

**Critical shared configurations:**
- AWS Cognito credentials (general-api and hosting-api)
- AWS S3/CloudFront credentials (general-api and hosting-api)
- Database URLs (separate PostgreSQL databases)
- API URLs for cross-service communication

## Deployment Architecture

Each workspace deploys independently:

- **General API**: AWS deployment (Docker + PM2)
- **Hosting API**: AWS deployment (Docker + PM2, separate processes for web and worker)
- **Hosting Renderer**: Next.js deployment (static export to S3/CloudFront)
- **UI**: Vite build deployed to static hosting (S3/CloudFront)

## Common Patterns Across Workspaces

### Request-Response Cycle
1. Router defines HTTP endpoints
2. Validation middleware (Zod schemas)
3. Authentication middleware (Cognito token validation)
4. Authorization middleware (group-based access control)
5. Controller handles request/response
6. Service layer contains business logic
7. Prisma for database operations

### Error Handling
All workspaces use `express-async-errors` for automatic async error handling with standardized error responses.

### Pagination
Consistent pagination utilities across APIs using limit/offset pattern.

### Code Organization
Modular architecture with clear separation of concerns:
- `modules/` for domain-specific code
- `utils/` for shared utilities
- `config/` for configuration
- Service layer pattern for business logic
