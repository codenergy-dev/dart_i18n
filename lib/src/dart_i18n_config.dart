class DartI18nConfig {
  final String? openaiApiKey;

  DartI18nConfig({
    this.openaiApiKey,
  });

  factory DartI18nConfig.fromJson(Map<String, dynamic> json) {
    return DartI18nConfig(
      openaiApiKey: json['openaiApiKey'],
    );
  }
}