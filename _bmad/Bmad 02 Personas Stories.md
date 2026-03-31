# Personas, Epics & User Stories: Camelo Pro

---

## 1. Personas Principais

### Persona A: Seu Manoel da Pipoca (Baixa Literacia Digital)
- **Perfil:** Vendedor tradicional de rua, +45 anos. Itens de giro rápido e baixo valor (pipoca, água, doces, recargas).
- **A Dor:** Depende 100% da memória e do caderno amassado. "Paga para trabalhar" porque não conta transporte e alimentação no custo.
- **Comportamento:** Foge de letras miúdas, mãos ocupadas, digita devagar.
- **O que precisa:** Botões grandes, ícones, fotos. Quanto menos digitar, melhor.

### Persona B: Juninho do Box da Apple (Alta Literacia Digital)
- **Perfil:** Dono de box em camelódromo (Oiapoque, Santa Ifigênia), 25-40 anos. Itens de alto valor.
- **A Dor:** Devoluções, trocas, fiado de maquininha, empréstimos entre vizinhos de box.
- **Comportamento:** Frenético no WhatsApp, sabe usar planilhas.
- **O que precisa:** Scanner de código de barras rápido, registro cirúrgico de pendências com vizinhos.

### Persona C: O Proprietário do SaaS (Cristiano — Superadmin)
- **Perfil:** Dono da plataforma. Acesso web.
- **O que precisa:** Visão global de métricas, gestão de assinaturas, push segmentado por região/segmento.

### Persona D: João, o Ajudante (Funcionário)
- **Perfil:** Trabalha na barraca do Manoel ou do Juninho. Acesso mobile limitado.
- **O que precisa:** Registrar vendas, cadastrar produtos. Sem acesso a relatórios financeiros.

---

## 2. Epics & User Stories

### Epic 1: Autenticação & Onboarding ✅ CONCLUÍDO
> *Garantir acesso seguro e simples sem e-mail, usando apenas telefone + PIN numérico.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 1.1 | Como dono, quero criar conta usando meu telefone e um PIN de 6 dígitos, sem precisar de e-mail | Cadastro com OTP via SMS funciona; trigger cria profile + company + subscription trial | ✅ |
| 1.2 | Como dono, quero informar meu Estado, Cidade e Ramo de negócio no cadastro | Dropdowns de UF, campo de cidade e segmento no signup; dados salvos na tabela companies | ✅ |
| 1.3 | Como dono, quero fazer login só com telefone + PIN | Login por signInWithPassword com phone funciona | ✅ |
| 1.4 | Como novo usuário, quero ver uma introdução do app antes de criar conta | Onboarding com 3 slides + indicadores animados | ✅ |
| 1.5 | Como dono, quero ver meu perfil e poder sair da conta | Tela de perfil com dados, plano trial e logout com confirmação | ✅ |

---

### Epic 2: Catálogo de Produtos — "Scan & Go"
> *Permitir que o vendedor cadastre, visualize e gerencie seus produtos com o mínimo de digitação possível.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 2.1 | Como vendedor, quero adicionar um produto manualmente (nome, preço Pix, preço Cartão, custo) | Formulário salva na tabela `products`; campos de preço duplo com máscara R$ | ✅ |
| 2.2 | Como vendedor, quero bipar o código de barras com a câmera para preencher o produto | Scanner abre câmera; se barcode já existe na minha base, preenche automaticamente | ✅ |
| 2.3 | Como vendedor, quero tirar foto do produto com a câmera do celular | `image_picker` abre câmera; foto é salva no Supabase Storage e vinculada ao produto | ✅ |
| 2.4 | Como vendedor, quero ver a lista dos meus produtos com foto, nome e preço | Tela de listagem com grid de Cards; filtro por "Ativos / Inativos" | ✅ |
| 2.5 | Como vendedor, quero editar nome, preço e quantidade de um produto existente | Tela de edição pré-preenchida; salva no banco | ✅ |
| 2.6 | Como vendedor, quero desativar um produto sem apagá-lo | Toggle `is_active`; produto some da vitrine mas mantém histórico | ✅ |
| 2.7 | Como vendedor, quero criar combos (agrupamento de produtos) | Flag `is_combo` + tabela combo_items + CRUD; preço combo separado | ✅ |
| 2.8 | Como vendedor, quero ver o lucro estimado por produto (preço venda – custo bruto) | Cálculo dinâmico exibido no card e no formulário | ✅ |

---

### Epic 3: Ponto de Venda (PDV) Simplificado
> *Registrar vendas de forma instantânea, sem complicação, direto do celular.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 3.1 | Como vendedor, quero selecionar um produto e registrar uma venda com 1 toque | Tela PDV com grid de produtos; toque adiciona ao carrinho | ⬜ |
| 3.2 | Como vendedor, quero escolher a forma de pagamento (Pix/Dinheiro ou Cartão) | Seletor aplica o preço correto automaticamente | ⬜ |
| 3.3 | Como vendedor, quero ver o resumo da venda antes de confirmar | Tela de revisão com total, itens e meio de pagamento | ⬜ |
| 3.4 | Como vendedor, quero que o estoque atualize automaticamente após cada venda | `stock_quantity` decrementado via transação no banco | ⬜ |
| 3.5 | Como vendedor, quero ver o total de vendas e faturamento do dia | Dashboard atualizado em tempo real na Home | ⬜ |

---

### Epic 4: Fiado & Empréstimos entre Barracas
> *Controlar os "cadernos de fiado" e empréstimos de estoque entre barracas vizinhas.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 4.1 | Como vendedor, quero registrar que vendi fiado para um cliente | Registro de débito com nome do cliente, valor e data | ⬜ |
| 4.2 | Como vendedor, quero marcar quando o cliente pagou o fiado | Status muda de "pendente" para "quitado"; soma atualizada | ⬜ |
| 4.3 | Como vendedor de box, quero registrar que emprestei (ou peguei) mercadoria do vizinho | Registro bidirecional com nome da barraca, item e quantidade | ⬜ |
| 4.4 | Como vendedor, quero ver um resumo de quanto estou devendo / me devem | Painel de saldo consolidado por parceiro | ⬜ |

---

### Epic 5: Custos & Relatórios de Lucro
> *Ajudar o vendedor a entender seu lucro real, incluindo custos invisíveis.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 5.1 | Como vendedor, quero registrar despesas do dia (transporte, alimentação, aluguel) | Formulário de despesas com categorias pré-definidas | ⬜ |
| 5.2 | Como vendedor, quero ver o relatório de lucro líquido do dia | Faturamento − (Custo dos produtos vendidos + Despesas do dia) | ⬜ |
| 5.3 | Como vendedor, quero ver o relatório semanal/mensal de lucro | Gráfico simples de barras com evolução | ⬜ |
| 5.4 | Como vendedor, quero saber o custo bruto real de cada produto (custo + rateio de despesas) | Cálculo automático de markup baseado nas despesas registradas | ⬜ |

---

### Epic 6: Gestão de Funcionários
> *Permitir que o dono da barraca dê acesso controlado a ajudantes.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 6.1 | Como dono, quero convidar um funcionário pelo telefone dele | Convite gera registro em profiles com role=FUNCIONARIO e company_id vinculado | ⬜ |
| 6.2 | Como dono, quero definir permissões (pode cadastrar produto? pode ver relatório?) | Campo `permissions` JSONB no profile controla acesso | ⬜ |
| 6.3 | Como dono, quero remover o acesso de um funcionário | Desvincula company_id do profile do funcionário | ⬜ |
| 6.4 | Como funcionário, quero acessar o app com meu telefone e ver só o que tenho permissão | UI esconde abas/botões conforme permissions | ⬜ |

---

### Epic 7: Assinaturas & Monetização
> *Converter usuários trial em assinantes pagantes.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 7.1 | Como dono, quero ver quantos dias faltam do meu trial | Banner na Home mostra contagem regressiva | ⬜ |
| 7.2 | Como dono expirado, quero assinar o plano via Cartão de Crédito | Integração com gateway (Asaas/Stripe) atualiza tabela subscriptions | ⬜ |
| 7.3 | Como dono expirado, quero pagar via Pix avulso | Geração de QR code Pix; webhook confirma pagamento | ⬜ |
| 7.4 | Como superadmin, quero ver a lista de assinantes e inadimplentes | Painel web com filtros por status e plano | ⬜ |

---

### Epic 8: Painel Superadmin (Web)
> *Dashboard web exclusivo do proprietário para visão onisciente da plataforma.*

| ID | Story | Critério de Aceite | Status |
|----|-------|--------------------|--------|
| 8.1 | Como superadmin, quero ver métricas globais (total de barracas, vendas, faturamento) | Dashboard web com cards de KPI em tempo real | ⬜ |
| 8.2 | Como superadmin, quero ver barracas por Estado e Segmento | Mapa ou tabela com filtros geográficos | ⬜ |
| 8.3 | Como superadmin, quero enviar push notifications segmentados | Seletor de UF + Segmento → envio via Supabase Edge Functions | ⬜ |
| 8.4 | Como superadmin, quero bloquear/desbloquear uma barraca | Toggle de status na company; RLS impede acesso | ⬜ |

---

## 3. Prioridade de Execução (Roadmap)

```
Sprint 1: Epic 1 ✅ (Autenticação)
Sprint 2: Epic 2 ✅ (Catálogo de Produtos)
Sprint 3: Epic 3 ← PRÓXIMO (PDV)
Sprint 4: Epic 5 (Custos & Relatórios)
Sprint 5: Epic 4 (Fiado & Empréstimos)
Sprint 6: Epic 6 (Funcionários)
Sprint 7: Epic 7 (Assinaturas)
Sprint 8: Epic 8 (Painel Superadmin Web)
```

> **Nota:** Epics 2 e 3 são o coração do MVP. Sem produtos e sem vendas, não há razão para o vendedor abrir o app uma segunda vez.
