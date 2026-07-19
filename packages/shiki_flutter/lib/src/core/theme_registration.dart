// Theme normalization, ported from Shiki's `textmate/normalize-theme.ts`.
library;

import '../textmate/theme.dart';

const _vscodeFallbackEditorFgLight = '#333333';
const _vscodeFallbackEditorFgDark = '#bbbbbb';
const _vscodeFallbackEditorBgLight = '#fffffe';
const _vscodeFallbackEditorBgDark = '#1e1e1e';

/// A resolved Shiki theme: normalized settings, resolved fg/bg, and color
/// replacements for any non-hex colors that `vscode-textmate` cannot represent.
class ThemeRegistration {
  ThemeRegistration({
    required this.name,
    required this.type,
    required this.settings,
    this.fg,
    this.bg,
    Map<String, String>? colorReplacements,
    Map<String, String>? colors,
  })  : colorReplacements = colorReplacements ?? {},
        colors = colors ?? {};

  final String name;
  String type; // 'light' | 'dark'
  List<RawThemeSetting> settings;
  String? fg;
  String? bg;
  Map<String, String> colorReplacements;
  Map<String, String> colors;

  /// Parses a raw theme JSON map (VS Code / TextMate theme format).
  static ThemeRegistration fromJson(Map<String, dynamic> json) {
    final settingsJson = (json['settings'] ?? json['tokenColors']) as List?;
    final settings = <RawThemeSetting>[];
    if (settingsJson != null) {
      for (final entry in settingsJson) {
        if (entry is Map) settings.add(_settingFromJson(entry));
      }
    }

    final colors = <String, String>{};
    final rawColors = json['colors'];
    if (rawColors is Map) {
      rawColors.forEach((k, v) {
        if (v is String) colors[k.toString()] = v;
      });
    }

    final colorReplacements = <String, String>{};
    final rawReplacements = json['colorReplacements'];
    if (rawReplacements is Map) {
      rawReplacements.forEach((k, v) {
        if (v is String) colorReplacements[k.toString()] = v;
      });
    }

    return ThemeRegistration(
      name: (json['name'] as String?) ?? 'default',
      type: (json['type'] as String?) ?? 'dark',
      settings: settings,
      fg: json['fg'] as String?,
      bg: json['bg'] as String?,
      colorReplacements: colorReplacements,
      colors: colors,
    );
  }

  static RawThemeSetting _settingFromJson(Map entry) {
    final settings = entry['settings'];
    final style = settings is Map ? settings : const {};
    return RawThemeSetting(
      name: entry['name'] as String?,
      scope: entry['scope'],
      settings: ThemeSettingStyle(
        fontStyle: style['fontStyle'] as String?,
        foreground: style['foreground'] as String?,
        background: style['background'] as String?,
      ),
    );
  }

  /// Serializes back to a VS Code / TextMate theme JSON map — the inverse of
  /// [fromJson]. Used to replicate an object-built theme to the async worker,
  /// which only accepts JSON strings. Round-trips through [fromJson] losslessly.
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (fg != null) 'fg': fg,
        if (bg != null) 'bg': bg,
        if (colors.isNotEmpty) 'colors': colors,
        if (colorReplacements.isNotEmpty) 'colorReplacements': colorReplacements,
        'settings': [for (final s in settings) _settingToJson(s)],
      };

  static Map<String, dynamic> _settingToJson(RawThemeSetting s) => {
        if (s.name != null) 'name': s.name,
        // `scope` is a String or List<String>; both are JSON-encodable as-is.
        if (s.scope != null) 'scope': s.scope,
        'settings': {
          if (s.settings.fontStyle != null) 'fontStyle': s.settings.fontStyle,
          if (s.settings.foreground != null) 'foreground': s.settings.foreground,
          if (s.settings.background != null) 'background': s.settings.background,
        },
      };
}

/// Normalizes a raw theme: fills in defaults, guesses fg/bg, and moves non-hex
/// colors into [ThemeRegistration.colorReplacements].
ThemeRegistration normalizeTheme(ThemeRegistration theme) {
  theme.colorReplacements = {...theme.colorReplacements};
  final settings = [...theme.settings];

  var bg = theme.bg;
  var fg = theme.fg;
  if (bg == null || fg == null) {
    RawThemeSetting? globalSetting;
    for (final s in settings) {
      if (s.name == null && s.scope == null) {
        globalSetting = s;
        break;
      }
    }

    fg ??= globalSetting?.settings.foreground;
    bg ??= globalSetting?.settings.background;

    fg ??= theme.colors['editor.foreground'];
    bg ??= theme.colors['editor.background'];

    fg ??= theme.type == 'light'
        ? _vscodeFallbackEditorFgLight
        : _vscodeFallbackEditorFgDark;
    bg ??= theme.type == 'light'
        ? _vscodeFallbackEditorBgLight
        : _vscodeFallbackEditorBgDark;

    theme.fg = fg;
    theme.bg = bg;
  }

  // Ensure the first setting is a no-scope default with fallback colors.
  final hasLeadingDefault = settings.isNotEmpty &&
      settings.first.scope == null &&
      settings.first.name == null;
  if (!hasLeadingDefault) {
    settings.insert(
      0,
      RawThemeSetting(
        settings: ThemeSettingStyle(foreground: theme.fg, background: theme.bg),
      ),
    );
  }

  // Push non-hex colors to color replacements.
  var replacementCount = 0;
  final replacementMap = <String, String>{};
  String getReplacementColor(String value) {
    final existing = replacementMap[value];
    if (existing != null) return existing;
    replacementCount += 1;
    final hex =
        '#${replacementCount.toRadixString(16).padLeft(8, '0').toLowerCase()}';
    replacementMap[value] = hex;
    return hex;
  }

  final newSettings = <RawThemeSetting>[];
  for (final setting in settings) {
    final rawFg = setting.settings.foreground;
    final rawBg = setting.settings.background;
    final replaceFg = rawFg != null && !rawFg.startsWith('#');
    final replaceBg = rawBg != null && !rawBg.startsWith('#');
    if (!replaceFg && !replaceBg) {
      newSettings.add(setting);
      continue;
    }
    var newFg = rawFg;
    var newBg = rawBg;
    if (replaceFg) {
      final replacement = getReplacementColor(rawFg);
      theme.colorReplacements[replacement] = rawFg;
      newFg = replacement;
    }
    if (replaceBg) {
      final replacement = getReplacementColor(rawBg);
      theme.colorReplacements[replacement] = rawBg;
      newBg = replacement;
    }
    newSettings.add(RawThemeSetting(
      name: setting.name,
      scope: setting.scope,
      settings: ThemeSettingStyle(
        fontStyle: setting.settings.fontStyle,
        foreground: newFg,
        background: newBg,
      ),
    ));
  }

  theme.settings = newSettings;
  return theme;
}
