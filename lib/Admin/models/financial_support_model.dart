/// نموذج بيانات دعم المقرأة (FinancialSupportModel)
class FinancialSupportModel {
  final String id;
  final String providerName; // اسم المحفظة أو البنك
  final String accountHolderName; // اسم صاحب الحساب
  final bool isDivided; // هل مقسم إلى شمال وجنوب
  final String accountYemeni;
  final String accountSaudi;
  final String accountDollar;
  final String accountNorthYemeni;
  final String accountNorthSaudi;
  final String accountNorthDollar;
  final String accountSouthYemeni;
  final String accountSouthSaudi;
  final String accountSouthDollar;
  final DateTime? createdAt;

  FinancialSupportModel({
    required this.id,
    required this.providerName,
    this.accountHolderName = '',
    this.isDivided = false,
    this.accountYemeni = '',
    this.accountSaudi = '',
    this.accountDollar = '',
    this.accountNorthYemeni = '',
    this.accountNorthSaudi = '',
    this.accountNorthDollar = '',
    this.accountSouthYemeni = '',
    this.accountSouthSaudi = '',
    this.accountSouthDollar = '',
    this.createdAt,
  });

  factory FinancialSupportModel.fromJson(Map<String, dynamic> json) {
    return FinancialSupportModel(
      id: json['id']?.toString() ?? '',
      providerName: json['provider_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      isDivided: json['is_divided'] ?? false,
      accountYemeni: json['account_yemeni'] ?? '',
      accountSaudi: json['account_saudi'] ?? '',
      accountDollar: json['account_dollar'] ?? '',
      accountNorthYemeni: json['account_north_yemeni'] ?? '',
      accountNorthSaudi: json['account_north_saudi'] ?? '',
      accountNorthDollar: json['account_north_dollar'] ?? '',
      accountSouthYemeni: json['account_south_yemeni'] ?? '',
      accountSouthSaudi: json['account_south_saudi'] ?? '',
      accountSouthDollar: json['account_south_dollar'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_name': providerName,
      'account_holder_name': accountHolderName,
      'is_divided': isDivided,
      'account_yemeni': accountYemeni,
      'account_saudi': accountSaudi,
      'account_dollar': accountDollar,
      'account_north_yemeni': accountNorthYemeni,
      'account_north_saudi': accountNorthSaudi,
      'account_north_dollar': accountNorthDollar,
      'account_south_yemeni': accountSouthYemeni,
      'account_south_saudi': accountSouthSaudi,
      'account_south_dollar': accountSouthDollar,
    };
  }

  FinancialSupportModel copyWith({
    String? id,
    String? providerName,
    String? accountHolderName,
    bool? isDivided,
    String? accountYemeni,
    String? accountSaudi,
    String? accountDollar,
    String? accountNorthYemeni,
    String? accountNorthSaudi,
    String? accountNorthDollar,
    String? accountSouthYemeni,
    String? accountSouthSaudi,
    String? accountSouthDollar,
    DateTime? createdAt,
  }) {
    return FinancialSupportModel(
      id: id ?? this.id,
      providerName: providerName ?? this.providerName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      isDivided: isDivided ?? this.isDivided,
      accountYemeni: accountYemeni ?? this.accountYemeni,
      accountSaudi: accountSaudi ?? this.accountSaudi,
      accountDollar: accountDollar ?? this.accountDollar,
      accountNorthYemeni: accountNorthYemeni ?? this.accountNorthYemeni,
      accountNorthSaudi: accountNorthSaudi ?? this.accountNorthSaudi,
      accountNorthDollar: accountNorthDollar ?? this.accountNorthDollar,
      accountSouthYemeni: accountSouthYemeni ?? this.accountSouthYemeni,
      accountSouthSaudi: accountSouthSaudi ?? this.accountSouthSaudi,
      accountSouthDollar: accountSouthDollar ?? this.accountSouthDollar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
