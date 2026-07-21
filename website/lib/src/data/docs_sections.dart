/// Metadata for one docs section: its anchor [id] and display [title].
class DocsSection {
  const DocsSection(this.id, this.title);

  final String id;
  final String title;
}

/// A named group of sections, rendered as one labeled block in the nav.
class DocsSectionGroup {
  const DocsSectionGroup(this.title, this.sections);

  final String title;
  final List<DocsSection> sections;
}

/// The docs, grouped and ordered top-to-bottom from first-run basics to
/// advanced tuning. The sidebar and nav popup render these groups with their
/// labels; the reading column and scroll-spy walk the flattened [docsSections]
/// in this order.
const docsGroups = <DocsSectionGroup>[
  DocsSectionGroup('Getting started', [
    DocsSection('introduction', 'Introduction'),
    DocsSection('installation', 'Installation'),
    DocsSection('quick-start', 'Quick start'),
  ]),
  DocsSectionGroup('Rendering code', [
    DocsSection('rendering', 'Rendering code'),
    DocsSection('widgets', 'Widgets'),
    DocsSection('large-files', 'Large files'),
  ]),
  DocsSectionGroup('Themes & languages', [
    DocsSection('themes', 'Themes'),
    DocsSection('extra-themes', 'Extra themes'),
    DocsSection('languages', 'Languages'),
  ]),
  DocsSectionGroup('Performance & platforms', [
    DocsSection('async', 'Async highlighting'),
    DocsSection('engines', 'Engines'),
    DocsSection('web', 'Web setup'),
    DocsSection('configuration', 'Configuration'),
  ]),
  DocsSectionGroup('Advanced', [
    DocsSection('pre-warming', 'Pre-warming'),
    DocsSection('bundle-size', 'Bundle size'),
    DocsSection('custom', 'Custom grammars'),
    DocsSection('limitations', 'Limitations'),
  ]),
];

/// The groups flattened into reading order, for the anchor keys, scroll-spy,
/// and the content column (all index-based).
final docsSections = <DocsSection>[
  for (final group in docsGroups) ...group.sections,
];
