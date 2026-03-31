-- ==============================================================================
-- EPIC 4: Fiado & Empréstimos entre Barracas
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
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    quantity INT,
    unit_price BIGINT,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'settled')),
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- PROTEÇÃO DE ACESSO (RLS - Row Level Security)
-- ==============================================================================
ALTER TABLE debts ENABLE ROW LEVEL SECURITY;

-- 1) Políticas de Leitura: Usuários só podem ler dívidas da própria company_id
CREATE POLICY "Users can view debts from their own company"
    ON debts FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM profiles WHERE id = auth.uid()
        )
    );

-- 2) Política de Inserção: Usuários só podem inserir dívidas na própria company_id
CREATE POLICY "Users can insert debts into their own company"
    ON debts FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM profiles WHERE id = auth.uid()
        )
    );

-- 3) Política de Atualização: Usuários só podem mudar dívidas da própria company
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

-- ==============================================================================
-- Índices para performance (Buscamos muito por company_id, tipo e status)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_debts_company_id ON debts(company_id);
CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status);
CREATE INDEX IF NOT EXISTS idx_debts_type_category ON debts(type, category);
