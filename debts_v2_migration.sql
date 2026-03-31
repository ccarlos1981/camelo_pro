-- ==============================================================================
-- EPIC 4: Fiado & Empréstimos entre Barracas (Mútua)
-- Tabela: debts (Fiados de clientes e Acertos com Vizinhos)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS debts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('receivable', 'payable')),
    category TEXT NOT NULL CHECK (category IN ('customer', 'neighbor')),
    person_name TEXT NOT NULL,
    amount BIGINT NOT NULL DEFAULT 0,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'settled')),
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Adicionando colunas de Mútua (Produtos) de forma idempotente
ALTER TABLE debts ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products(id) ON DELETE SET NULL;
ALTER TABLE debts ADD COLUMN IF NOT EXISTS quantity INT DEFAULT 0;
-- settlement_type identifica como a devolução foi feita (se aplicável): 'product_return' ou 'cash_payment'
ALTER TABLE debts ADD COLUMN IF NOT EXISTS settlement_type TEXT CHECK (settlement_type IN ('product_return', 'cash_payment'));

-- ==============================================================================
-- PROTEÇÃO DE ACESSO (RLS - Row Level Security)
-- ==============================================================================
ALTER TABLE debts ENABLE ROW LEVEL SECURITY;

-- As Policies antigas (se existirem) podem ser removidas ou substituídas, mas o CREATE POLICY abaixo falharia se já existir.
-- Vamos deletá-las e recriá-las para atualizar:
DROP POLICY IF EXISTS "Users can view debts from their own company" ON debts;
DROP POLICY IF EXISTS "Users can insert debts into their own company" ON debts;
DROP POLICY IF EXISTS "Users can update debts from their own company" ON debts;

CREATE POLICY "Users can view debts from their own company"
    ON debts FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can insert debts into their own company"
    ON debts FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update debts from their own company"
    ON debts FOR UPDATE
    USING (
        company_id IN (
            SELECT company_id FROM profiles WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM profiles WHERE id = auth.uid()
        )
    );

-- Índices
CREATE INDEX IF NOT EXISTS idx_debts_company_id ON debts(company_id);
CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status);
CREATE INDEX IF NOT EXISTS idx_debts_type_category ON debts(type, category);
