class LmStudioConfig {
  static const String _envKey = 'LM_STUDIO_BASE_URL';
  static const String _rawBaseUrl = String.fromEnvironment(_envKey);

  static String? get baseUrl {
    final normalized = _rawBaseUrl.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static Uri? get completionUri {
    final configuredBaseUrl = baseUrl;
    if (configuredBaseUrl == null) {
      return null;
    }

    final trimmed = configuredBaseUrl.replaceAll(RegExp(r'/+$'), '');

    if (trimmed.endsWith('/v1/chat/completions')) {
      return Uri.tryParse(trimmed);
    }
    if (trimmed.endsWith('/v1')) {
      return Uri.tryParse('$trimmed/chat/completions');
    }

    return Uri.tryParse('$trimmed/v1/chat/completions');
  }
}
