import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const List<String> promptFiles = [
  'assets/story/prompts/kroll-prompt.txt',
  'assets/story/prompts/knatterbach-prompt.txt',
  'assets/story/prompts/bozzi-prompt.txt',
  'assets/story/prompts/knöchelbein-prompt.txt',
  'assets/story/prompts/tschulli-prompt.txt',
];
final RegExp signalTagPattern = RegExp(
  r'<npc-signal>\s*\{\s*"signal"\s*:\s*"([^"]+)"[\s\S]*?\}\s*</npc-signal>',
);

Set<String> extractFullSignalTags(
  String input, {
  bool onlyInSignaleSection = false,
}) {
  final signalTagPattern = RegExp(
    r'<npc-signal>\s*\{[\s\S]*?\}\s*</npc-signal>',
    caseSensitive: true,
  );

  final relevantText =
      onlyInSignaleSection
          ? input
                  .split(RegExp(r'##\s*Signale', caseSensitive: false))
                  .elementAtOrNull(1) ??
              ''
          : input.split(RegExp(r'##\s*Signale', caseSensitive: false)).first;

  return signalTagPattern
      .allMatches(relevantText)
      .map((m) => m.group(0)!.trim())
      .toSet();
}

Set<String> extractSignalsInText(String input) {
  // Split into content and ## Signale section
  final parts = input.split(RegExp(r'##\s*Signale', caseSensitive: false));
  final mainContent = parts.isNotEmpty ? parts[0] : input;

  final matches = signalTagPattern.allMatches(mainContent);
  final signals = <String>{};

  for (final match in matches) {
    if (match.groupCount >= 1) {
      signals.add(match.group(1)!);
    }
  }

  return signals;
}

Set<String> extractSignalsFromSignaleSection(String input) {
  // Split text at '## Signale' section
  final parts = input.split(RegExp(r'##\s*Signale', caseSensitive: false));
  if (parts.length < 2) return {};

  final signaleSection = parts[1];
  final matches = signalTagPattern.allMatches(signaleSection);
  final signals = <String>{};

  for (final match in matches) {
    if (match.groupCount >= 1) {
      signals.add(match.group(1)!);
    }
  }

  return signals;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Prompt signal consistency test', () {
    for (final filePath in promptFiles) {
      test(
        'Signals used in text match signals listed in ## Signale section',
        () async {
          //final prompt = await Prompt.createPrompt('npc-kroll.txt'); // Beispiel-Dateiname
          final file = File(filePath);
          final promptText = await file.readAsString();

          final usedSignals = extractSignalsInText(promptText);
          final documentedSignals = extractSignalsFromSignaleSection(
            promptText,
          );

          expect(
            usedSignals,
            equals(documentedSignals),
            reason:
                'Used signals and documented signals must match in $filePath',
          );
        },
      );

      test(
        'Full signal tags match documented signal tags in $filePath',
        () async {
          final file = File(filePath);
          final promptText = await file.readAsString();

          final fullUsedSignals = extractFullSignalTags(promptText);
          final fullDocumentedSignals = extractFullSignalTags(
            promptText,
            onlyInSignaleSection: true,
          );

          expect(
            fullUsedSignals,
            equals(fullDocumentedSignals),
            reason:
                'Full signal tags must match exactly in $filePath (including formatting and attributes).',
          );
        },
      );
    }
  });
}
