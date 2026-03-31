-- Atualizar trigger para trial dinâmico: 90 dias para os 20 primeiros, 45 dias depois
CREATE OR REPLACE FUNCTION public.handle_new_user_registration()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  new_company_id UUID;
  meta_company_name TEXT;
  meta_full_name TEXT;
  meta_state TEXT;
  meta_city TEXT;
  meta_segment TEXT;
  meta_is_employee BOOLEAN;
  meta_company_id UUID;
  company_count INT;
  trial_days INT;
BEGIN
  -- Se profile já existe (criado pela Edge Function), skip
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.id) THEN
    RETURN NEW;
  END IF;

  meta_company_name := NEW.raw_user_meta_data->>'company_name';
  meta_full_name    := NEW.raw_user_meta_data->>'full_name';
  meta_state        := NEW.raw_user_meta_data->>'state';
  meta_city         := NEW.raw_user_meta_data->>'city';
  meta_segment      := NEW.raw_user_meta_data->>'segment';
  meta_is_employee  := COALESCE((NEW.raw_user_meta_data->>'is_employee')::boolean, false);
  meta_company_id   := (NEW.raw_user_meta_data->>'employee_company_id')::uuid;

  IF meta_is_employee AND meta_company_id IS NOT NULL THEN
    -- Funcionário criado pela Edge Function
    INSERT INTO public.profiles (id, company_id, name, phone, role, must_change_password)
    VALUES (
      NEW.id,
      meta_company_id,
      COALESCE(meta_full_name, 'Funcionário(a)'),
      NEW.phone,
      'FUNCIONARIO',
      true
    );
  ELSIF meta_company_name IS NOT NULL THEN
    -- Dono: fluxo original
    INSERT INTO public.profiles (id, company_id, name, email, phone, role)
    VALUES (NEW.id, NULL, COALESCE(meta_full_name, 'Proprietário(a)'), NEW.email, NEW.phone, 'ADMIN_EMPRESA');

    INSERT INTO public.companies (name, owner_user_id, state, city, segment)
    VALUES (meta_company_name, NEW.id, meta_state, meta_city, meta_segment)
    RETURNING id INTO new_company_id;

    UPDATE public.profiles SET company_id = new_company_id WHERE id = NEW.id;

    -- Trial dinâmico: 90 dias para os 20 primeiros donos, 45 dias depois
    SELECT count(*) INTO company_count FROM public.companies;
    IF company_count <= 20 THEN
      trial_days := 90;
    ELSE
      trial_days := 45;
    END IF;

    INSERT INTO public.subscriptions (company_id, plan, expires_at)
    VALUES (new_company_id, 'trial', now() + (trial_days || ' days')::interval);
  ELSE
    -- Cadastro genérico
    INSERT INTO public.profiles (id, company_id, name, email, phone, role)
    VALUES (NEW.id, NULL, COALESCE(meta_full_name, 'Usuário'), NEW.email, NEW.phone, 'FUNCIONARIO');
  END IF;

  RETURN NEW;
END;
$function$;
