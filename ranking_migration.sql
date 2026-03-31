-- Migração para Adição de Metas (Ranking de Vendedores)
-- Adiciona a coluna monthly_sales_goal na tabela public.profiles

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS monthly_sales_goal BIGINT DEFAULT 0;

-- Optional: Comentário para documentar o banco
COMMENT ON COLUMN public.profiles.monthly_sales_goal IS 'Meta mensal do vendedor em centavos.';
