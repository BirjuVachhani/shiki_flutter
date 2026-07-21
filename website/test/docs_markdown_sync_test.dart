import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter_website/src/data/docs_sections.dart';
import 'package:shiki_flutter_website/src/data/supported.dart';

/// Guards the served Markdown against drifting from the docs page (the source
/// of truth). `web/docs.md` is maintained by hand from the docs content; these
/// checks catch the most common ways it goes stale: a section added/renamed and
/// not reflected, or the language list falling out of sync. They do not verify
/// prose word-for-word, only structural coverage.
void main() {
  late final String docs;
  late final String llms;

  setUpAll(() {
    docs = File('web/docs.md').readAsStringSync();
    llms = File('web/llms.txt').readAsStringSync();
  });

  test('every docs section appears as a heading in web/docs.md', () {
    final missing = <String>[];
    for (final section in docsSections) {
      if (!docs.contains('## ${section.title}')) missing.add(section.title);
    }
    expect(
      missing,
      isEmpty,
      reason:
          'web/docs.md is missing `## ` headings for these docs sections: '
          '$missing. Update web/docs.md to match the docs page.',
    );
  });

  test('every supported language id appears in web/docs.md', () {
    final missing = supportedLanguages
        .map((l) => l.id)
        .where((id) => !docs.contains(id))
        .toList();
    expect(
      missing,
      isEmpty,
      reason:
          'web/docs.md does not list these language ids: $missing. Refresh the '
          'Languages id list in web/docs.md from lib/src/data/supported.dart.',
    );
  });

  test('web/docs.md advertises the current language count', () {
    // The Languages section states the bundled grammar count in prose; keep it
    // in step with the actual list length.
    expect(
      docs,
      contains('${supportedLanguages.length} languages'),
      reason:
          'The language count in web/docs.md no longer matches '
          'supportedLanguages.length (${supportedLanguages.length}).',
    );
  });

  test('web/llms.txt points readers at the full docs.md', () {
    expect(llms, contains('# shiki_flutter'));
    expect(
      llms,
      contains('docs.md'),
      reason: 'llms.txt should link to the full docs.md so an LLM fetches it.',
    );
  });
}
