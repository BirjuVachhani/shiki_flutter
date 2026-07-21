// Dumps the metadata the Dart generator needs (scopeName, aliases, embedded,
// displayName, categories, theme type) from tm-grammars / tm-themes into meta.json.
//
// The raw grammar/theme JSON files under node_modules/tm-{grammars,themes} carry
// the payload but NOT the aliases/embedded relationships — those live here in the
// package index. Run this before `dart run tool/generate_bundled.dart`.
import { grammars, injections } from 'tm-grammars';
import { themes } from 'tm-themes';
import { writeFileSync } from 'node:fs';

const pickGrammar = (g) => ({
  name: g.name,
  scopeName: g.scopeName,
  displayName: g.displayName ?? g.name,
  aliases: g.aliases ?? [],
  embedded: g.embedded ?? [],
  categories: g.categories ?? [],
});
const pickTheme = (t) => ({
  name: t.name,
  type: t.type,
  displayName: t.displayName ?? t.name,
});

const meta = {
  grammars: grammars.map(pickGrammar), // top-level, user-pickable
  injections: injections.map(pickGrammar), // embedded-only
  themes: themes.map(pickTheme),
};

writeFileSync(new URL('./meta.json', import.meta.url), JSON.stringify(meta, null, 2));
console.log(
  `grammars=${meta.grammars.length} injections=${meta.injections.length} themes=${meta.themes.length}`,
);
