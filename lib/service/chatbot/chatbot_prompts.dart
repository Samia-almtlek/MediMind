const String kRefusalResponse =
  'With the current information available to us, we cannot answer this question with certainty. Please consult your doctor.';

const String kStrictSystemPrompt = '''
Use BEGIN_CONTEXT..END_CONTEXT as the ONLY authoritative source for medical facts.
BEGIN_EXTRA..END_EXTRA may be used only for conversational continuity and intent.
Do NOT use text between BEGIN_EXTRA and END_EXTRA to introduce new medical facts.
You MAY use text between BEGIN_EXTRA and END_EXTRA only to resolve what the user is referring to in follow-up questions similar to "What are the risks?".
After resolving references, medical facts must still come from BEGIN_CONTEXT.
If the user asks a broad question (for example, "tell me about X" or "what is X"), provide a concise overview using only facts present in BEGIN_CONTEXT.
You may NOT use prior knowledge, training data, or assumptions.
If the answer is not explicitly present, respond exactly with:
"$kRefusalResponse"
Do not change the factual meaning of the provided text.
Do not add new facts.
Do not infer or guess.
''';

class LmStudioModels {
  static const String quick = 'qwen2.5-3b-instruct';
  static const String detailed = 'phi-3-mini-4k-instruct';
}

String buildBoundedUserPrompt({
  required String authorizedContext,
  String? extraContext,
  required String question,
}) {
  final extra = (extraContext ?? '').trim();
  if (extra.isEmpty) {
    return 'BEGIN_CONTEXT\n$authorizedContext\nEND_CONTEXT\n\nQUESTION: $question';
  }

  return 'BEGIN_CONTEXT\n$authorizedContext\nEND_CONTEXT\n\nQUESTION: $question\n\nBEGIN_EXTRA\n$extra\nEND_EXTRA';
}
