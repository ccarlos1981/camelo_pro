import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lista de estados brasileiros (UF) para o dropdown.
const List<String> _estadosBrasil = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

/// Segmentos de negócio comuns para o público ambulante.
const List<String> _segmentos = [
  'Alimentação',
  'Bebidas',
  'Eletrônicos',
  'Vestuário / Moda',
  'Acessórios',
  'Utilidades',
  'Beleza / Cosméticos',
  'Outros',
];

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedState;
  String? _selectedSegment;
  bool _isLoading = false;

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final company = _companyController.text.trim();
    final city = _cityController.text.trim();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = rawPhone.startsWith('55') ? '+$rawPhone' : '+55$rawPhone';
    final pin = _pinController.text;

    if (name.isEmpty || company.isEmpty || rawPhone.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.')),
      );
      return;
    }

    if (pin.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O seu PIN (Senha) deve ter 6 números.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        phone: phone,
        password: pin,
        channel: OtpChannel.sms,
        data: {
          'full_name': name,
          'company_name': company,
          'state': _selectedState,
          'city': city.isNotEmpty ? city : null,
          'segment': _selectedSegment,
        },
      );

      if (mounted) context.push('/auth/otp', extra: phone);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Houve um erro no cadastro.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Badge de proprietário
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 14, color: Color(0xFFF59E0B)),
                      SizedBox(width: 6),
                      Text(
                        'Cadastro do Proprietário',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cadastre seu negócio.',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essa conta é para o dono da barraca.\nSeus funcionários você cadastra depois, pelo app.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Dados pessoais ──
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Seu Nome Completo',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome da sua Barraca / Negócio',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),

                const SizedBox(height: 24),
                // ── Segmentação geográfica ──
                Text(
                  'Onde fica sua barraca?',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Estado (UF)
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'Estado (UF)',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: _estadosBrasil
                            .map((uf) => DropdownMenuItem(value: uf, child: Text(uf)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedState = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cidade
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Segmento
                DropdownButtonFormField<String>(
                  initialValue: _selectedSegment,
                  decoration: const InputDecoration(
                    labelText: 'Ramo do Negócio',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _segmentos
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSegment = v),
                ),

                const SizedBox(height: 24),
                // ── Acesso ──
                Text(
                  'Acesso ao seu caixa',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Seu WhatsApp (Com DDD)',
                    hintText: 'Ex: 11999998888',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Crie uma Senha PIN (6 Dígitos)',
                    prefixIcon: Icon(Icons.password_rounded),
                    helperText: 'Você usará esses números para acessar seu caixa.',
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Cadastrar Meu Negócio'),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: const Text('Já tenho conta. Fazer Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
