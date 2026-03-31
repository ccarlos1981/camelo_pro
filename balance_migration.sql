-- 1. Adicionar `unit_cost` no item da venda
-- Isso registrará o preço de custo real do produto no exato minuto em que ele foi vendido.
-- ALTER TABLE public.sale_items
-- ADD COLUMN unit_cost bigint NOT NULL DEFAULT 0;

-- Atualizar o histórico (opcionalmente) baseado no custo atual do produto 
-- para as vendas antigas. (Ignorar se isso for muito pesado, mas é recomendado para retroatividade inicial)
UPDATE public.sale_items si
SET unit_cost = p.buy_price + p.gross_cost_markup
FROM public.products p
WHERE si.product_id = p.id AND si.unit_cost = 0;


-- 2. Tabela de Despesas (Expenses)
CREATE TABLE IF NOT EXISTS public.expenses (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    description text NOT NULL,
    amount bigint NOT NULL, -- Valor em centavos
    expense_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

-- Ativar Row Level Security
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Policy: Empresas só podem ver/modificar suas próprias despesas
CREATE POLICY "Users can view expenses of their company"
    ON public.expenses FOR SELECT
    USING (company_id IN (
        SELECT company_id
        FROM public.profiles
        WHERE id = auth.uid()
    ));

CREATE POLICY "Users can insert expenses of their company"
    ON public.expenses FOR INSERT
    WITH CHECK (company_id IN (
        SELECT company_id
        FROM public.profiles
        WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update expenses of their company"
    ON public.expenses FOR UPDATE
    USING (company_id IN (
        SELECT company_id
        FROM public.profiles
        WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete expenses of their company"
    ON public.expenses FOR DELETE
    USING (company_id IN (
        SELECT company_id
        FROM public.profiles
        WHERE id = auth.uid()
    ));

-- Configurar Trigger de 'updated_at' usando função plpgsql genérica
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER handle_updated_at_expenses
BEFORE UPDATE ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
