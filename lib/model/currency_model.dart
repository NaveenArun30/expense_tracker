class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'symbol': symbol,
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          symbol == other.symbol &&
          name == other.name;

  @override
  int get hashCode => code.hashCode ^ symbol.hashCode ^ name.hashCode;
}

const List<Currency> availableCurrencies = [
  Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
  Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
  Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
  Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
  Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
  Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
  Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
  Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
  Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
  Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
  Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
  Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
  Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  Currency(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso'),
  Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
  Currency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
  Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
  Currency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
  Currency(code: 'SAR', symbol: 'SR', name: 'Saudi Riyal'),
  Currency(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
  Currency(code: 'ILS', symbol: '₪', name: 'Israeli Shekel'),
  Currency(code: 'PLN', symbol: 'zł', name: 'Polish Zloty'),
  Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
];
