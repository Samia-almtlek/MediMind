const String kRefusalResponse = 'Unable to answer with certainty.';

const String kStrictSystemPrompt = '''
You may ONLY use information contained between BEGIN_CONTEXT and END_CONTEXT.
You may NOT use prior knowledge, training data, or assumptions.
If the answer is not explicitly present, respond exactly with:
"With the current information available to us, we cannot answer this question with certainty. Please consult your doctor."
Do not paraphrase beyond the meaning of the text.
Do not add new facts.
Do not infer or guess.
''';

class LmStudioModels {
  static const String quick = 'qwen2.5-3b-instruct';
  static const String detailed = 'phi-3-mini-4k-instruct';
}

String buildBoundedUserPrompt({
  required String authorizedContext,
  required String question,
}) {
  return 'BEGIN_CONTEXT\n$authorizedContext\nEND_CONTEXT\n\nQUESTION: $question';
}
