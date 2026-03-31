# Arquitetura Técnica: Camelo Pro

---

## 1. Visão Geral

```
┌─────────────────────────────────────────────────────────┐
│                    PLATAFORMAS                          │
│                                                         │
│  📱 Mobile (Flutter)          🌐 Web (Next.js/Flutter)  │
│  ├─ Dono da Barraca           ├─ Painel Superadmin      │
│  └─ Funcionário               └─ (Epic 8 — futuro)     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    BACKEND                              │
│                                                         │
│  🔐 Supabase Auth         (Phone OTP + PIN)             │
│  🗄️ Supabase Database     (PostgreSQL + RLS)            │
│  📦 Supabase Storage      (Fotos de produtos)           │
│  ⚡ Supabase Edge Funcs   (Webhooks, Push — futuro)     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    INTEGRAÇÕES FUTURAS                  │
│                                                         │
│  💳 Asaas / Mercado Pago  (Assinaturas Pix + Cartão)   │
│  📲 OneSignal / FCM       (Push Notifications)          │
│  📊 PostHog / Mixpanel    (Analytics — opcional)        │
└─────────────────────────────────────────────────────────┘
```

## 2. Stack Tecnológica

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| **Mobile** | Flutter | 3.x (SDK ^3.11) |
| **State Management** | Riverpod 3 | ^3.3.1 |
| **Navegação** | GoRouter | ^17.1.0 |
| **Backend** | Supabase (PostgreSQL 15) | Cloud |
| **Auth** | Supabase Auth (Phone OTP) | — |
| **Storage** | Supabase Storage | — |
| **Web Superadmin** | A definir (Next.js ou Flutter Web) | Futuro |

## 3. Arquitetura Flutter (Clean Architecture)

```
lib/
├── core/
│   ├── config/
│   │   ├── env.dart            # Variáveis de ambiente (Supabase URL/Key)
│   │   ├── app_theme.dart      # Design System (cores, tipografia, componentes)
│   │   └── routes.dart         # GoRouter + StatefulShellRoute + redirect auth
│   ├── constants/              # Constantes globais
│   ├── extensions/             # Extensões de tipos Dart
│   └── utils/                  # Helpers (formatadores, validadores)
│
├── data/
│   ├── models/                 # Classes de dados tipadas (Product, Company, etc.)
│   ├── repositories/           # Comunicação com Supabase (CRUD)
│   └── services/               # Serviços auxiliares (câmera, storage, etc.)
│
├── presentation/
│   ├── providers/              # Riverpod Providers & Notifiers
│   ├── screens/
│   │   ├── auth/               # login, signup, otp_verification
│   │   ├── home/               # Dashboard principal
│   │   ├── onboarding/         # Telas de introdução
│   │   ├── products/           # Listagem, cadastro, edição
│   │   ├── pos/                # Ponto de venda
│   │   └── profile/            # Perfil do usuário
│   └── widgets/                # Componentes reutilizáveis (AppShell, etc.)
│
└── main.dart                   # Entry point
```

### Fluxo de Dados

```
Widget (UI) → Provider (Riverpod) → Repository → Supabase Client → PostgreSQL
     ↑                                                    │
     └────────────── Estado Reativo ──────────────────────┘
```

## 4. Schema do Banco de Dados (Atual)

```
┌──────────────────┐       ┌──────────────────┐
│   auth.users     │       │    profiles      │
│──────────────────│       │──────────────────│
│ id (PK)          │──────▶│ id (PK, FK)      │
│ phone            │       │ company_id (FK)  │──┐
│ raw_user_meta    │       │ name             │  │
│ created_at       │       │ phone            │  │
└──────────────────┘       │ role             │  │
                           │ permissions {}   │  │
                           └──────────────────┘  │
                                                 │
┌──────────────────┐       ┌──────────────────┐  │
│  subscriptions   │       │   companies      │◀─┘
│──────────────────│       │──────────────────│
│ id (PK)          │       │ id (PK)          │
│ company_id (FK)  │──────▶│ name             │
│ plan             │       │ owner_user_id FK │──▶ profiles.id
│ started_at       │       │ state            │
│ expires_at       │       │ city             │
│ payment_method   │       │ segment          │
│ status           │       │ plan             │
└──────────────────┘       │ status           │
                           └──────────────────┘

┌──────────────────┐  (Epic 2 — PRÓXIMO)
│    products      │
│──────────────────│
│ id (PK)          │
│ company_id (FK)  │──▶ companies.id
│ barcode          │
│ name             │
│ photo_url        │
│ buy_price        │
│ gross_cost_markup│
│ price_pix_cash   │
│ price_card       │
│ is_combo         │
│ stock_quantity   │
│ is_active        │
└──────────────────┘
```

## 5. Segurança

### Row Level Security (RLS)
Toda tabela tem RLS ativado. As políticas seguem o princípio:
- **Dono/Funcionário:** Só vê dados da própria `company_id`
- **Superadmin:** Vê tudo (role = 'SUPERADMIN')
- **Inserts:** Controlados via trigger `SECURITY DEFINER` ou política de admin

### Trigger de Registro
A função `handle_new_user_registration` (com `SET search_path = ''`) executa no `INSERT` em `auth.users` e:
1. Cria o `profile` (role: ADMIN_EMPRESA)
2. Cria a `company` (com state, city, segment)
3. Vincula o profile à company
4. Cria a `subscription` trial (45 dias)

### Princípios de Segurança
- Telefone como identidade primária (barreira física contra contas clone)
- PIN numérico de 6 dígitos (adequado ao público-alvo)
- Sem marketplace ou exposição pública de dados
- Nenhum dado financeiro trafega para fora do Supabase

## 6. Decisões Arquiteturais Registradas (ADRs)

| # | Decisão | Razão |
|---|---------|-------|
| ADR-01 | Phone-only auth (sem e-mail) | Público-alvo não usa e-mail corporativo; SMSs são universais |
| ADR-02 | PIN numérico em vez de senha alfanumérica | Facilidade para Persona A (Seu Manoel); teclado numérico é mais rápido |
| ADR-03 | Preço duplo (Pix vs Cartão) por produto | Prática universal no comércio de rua; taxa da maquininha repassada ao cliente |
| ADR-04 | Sem marketplace/catálogo público | Proteção fiscal; muitos produtos não têm NF de entrada |
| ADR-05 | Trial de 45 dias (não 30) | Mais tempo para criar hábito e dependência antes do paywall |
| ADR-06 | StatefulShellRoute com BottomNav | Material 3 pattern; cada aba mantém estado independente |
| ADR-07 | Supabase como backend único | Evita vendor lock-in complexo; RLS nativo; Auth + DB + Storage integrados |
| ADR-08 | Barcode scanner no cadastro de produto | Diferencial UX; "zero digitação" para produtos com embalagem |
