class MovieCountry {
  final String code;
  final String name;
  final String shortName;
  final String flag;

  const MovieCountry({
    required this.code,
    required this.name,
    required this.shortName,
    required this.flag,
  });

  static const usa = MovieCountry(
    code: 'US',
    name: 'Estados Unidos',
    shortName: 'USA',
    flag: '🇺🇸',
  );
  static const mexico = MovieCountry(
    code: 'MX',
    name: 'México',
    shortName: 'MÉX',
    flag: '🇲🇽',
  );
  static const germany = MovieCountry(
    code: 'DE',
    name: 'Alemania',
    shortName: 'ALEMANIA',
    flag: '🇩🇪',
  );
  static const japan = MovieCountry(
    code: 'JP',
    name: 'Japón',
    shortName: 'JAP',
    flag: '🇯🇵',
  );

  static const supported = [usa, mexico, germany, japan];

  static String flagForCode(String code) {
    final normalizedCode = code.toUpperCase();
    for (final country in supported) {
      if (country.code == normalizedCode) return country.flag;
    }

    if (normalizedCode.length != 2 ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCode)) {
      return '🌍';
    }

    return String.fromCharCodes(
      normalizedCode.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
    );
  }
}
