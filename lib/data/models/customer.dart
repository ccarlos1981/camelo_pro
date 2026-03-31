/// Modelo de cliente para CRM e promoções via WhatsApp.
class Customer {
  final String id;
  final String companyId;
  final String name;
  final String? phone;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.companyId,
    required this.name,
    this.phone,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'company_id': companyId,
    'name': name,
    'phone': phone,
    'notes': notes,
    'created_by': createdBy,
  };

  Customer copyWith({String? name, String? phone, String? notes}) {
    return Customer(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  /// Retorna o número formatado para link WhatsApp (55DDDNUMERO).
  String? get whatsappNumber {
    if (phone == null || phone!.isEmpty) return null;
    final digits = phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('55')) return digits;
    return '55$digits';
  }
}
