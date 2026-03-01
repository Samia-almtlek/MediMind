import 'package:flutter_test/flutter_test.dart';
import 'package:medimind/service/chatbot/chatbot_prompts.dart';

void main() {
  test('strict prompt keeps exact refusal response', () {
    expect(kStrictSystemPrompt.contains('"$kRefusalResponse"'), isTrue);
  });

  test('bounded user prompt contains required context markers', () {
    final prompt = buildBoundedUserPrompt(
      authorizedContext: 'Acetaminophen may cause nausea in some users.',
      question: 'Can acetaminophen cause nausea?',
    );

    expect(prompt.contains('BEGIN_CONTEXT'), isTrue);
    expect(prompt.contains('END_CONTEXT'), isTrue);
    expect(prompt.contains('QUESTION: Can acetaminophen cause nausea?'), isTrue);
  });

  test('bounded user prompt supports separate extra context markers', () {
    final prompt = buildBoundedUserPrompt(
      authorizedContext: 'DRUG: Ibuprofen',
      extraContext: 'RECENT_TURNS:\n- USER: what does it do?',
      question: 'What does ibuprofen do?',
    );

    expect(prompt.contains('BEGIN_CONTEXT'), isTrue);
    expect(prompt.contains('END_CONTEXT'), isTrue);
    expect(prompt.contains('BEGIN_EXTRA'), isTrue);
    expect(prompt.contains('END_EXTRA'), isTrue);
    expect(prompt.indexOf('QUESTION:'), lessThan(prompt.indexOf('BEGIN_EXTRA')));
  });
}
