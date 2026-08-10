# PDF DREAMER

A cross-platform document workspace built with Flutter. Read, review, sign, and convert PDF and Markdown files — all in one place.

<p align="center">
  <img src="assets/img/PDF-DREAMER-LOGO.png" alt="PDF DREAMER logo" width="128" />
</p>

---

## Features

- **PDF viewer** — high-fidelity rendering with zoom, scroll, and page navigation via [pdfrx](https://pub.dev/packages/pdfrx)
- **Markdown viewer** — rich rendering with zoom support via [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus)
- **Draw signatures** — freehand brush tool with configurable color and width
- **Image stamps** — upload signature images or watermarks, move, resize, and pin them
- **Undo / Redo** — full history for all edits
- **Save & Export** — persist annotations and convert between PDF and Markdown
- **Multi-language** — Español, Português, English
- **Dark & Light themes** — respects system preference by default, manually selectable
- **Responsive** — works on Windows, macOS, Linux, Android, iOS, and Web

---

## Platforms

| Platform | Status |
|----------|--------|
| Windows  | Stable |
| macOS    | Stable |
| Linux    | Stable |
| Android  | Stable |
| iOS      | Stable |
| Web      | Stable |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.8.1
- A supported platform toolchain (Android Studio, Xcode, Visual Studio, or GTK)

### Setup

```bash
git clone https://github.com/mirazolabs/pdf_dreamer.git
cd pdf_dreamer
flutter pub get
```

### Run

```bash
# Desktop (default host platform)
flutter run

# Specific platform
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome
```

### Build

```bash
flutter build windows
flutter build macos
flutter build linux
flutter build apk
flutter build web
```

---

## Architecture

The project follows a **feature-first, layered architecture**:

```
lib/
├── main.dart                     # Entry point, platform init
├── app/
│   └── pdf_dreamer_app.dart      # Composition root (providers, theme, i18n)
├── core/
│   ├── theme/
│   │   └── app_theme.dart        # Light + dark theme definitions
│   └── localization/
│       └── app_localizations.dart # JSON-based i18n delegate
└── features/
    ├── document/
    │   ├── data/services/        # File picker, export services
    │   ├── domain/entities/      # Pure Dart models
    │   └── presentation/
    │       ├── controllers/      # ChangeNotifier (state management)
    │       ├── pages/            # Full-screen pages
    │       └── widgets/          # Reusable UI components
    └── settings/
        └── presentation/
            ├── controllers/      # Theme & locale state
            └── widgets/          # Settings panel
```

### State Management

[Provider](https://pub.dev/packages/provider) + **ChangeNotifier**. Two controllers manage all app state:

| Controller | Responsibilities |
|------------|-----------------|
| `DocumentController` | Document lifecycle, tools, brush strokes, image stamps, zoom, undo/redo, save/export |
| `SettingsController` | Locale, theme mode (persisted via SharedPreferences) |

### Localization

Translations are stored as static JSON files under `assets/i18n/`. The `AppLocalizations` delegate loads the correct language at runtime and falls back to English if a key is missing. Currently supported:

- `es` — Español
- `pt` — Português
- `en` — English

To add a new language, create a `xx.json` file under `assets/i18n/`, copy the keys from an existing file, translate the values, and register the locale in `pdf_dreamer_app.dart` and `_AppLocalizationsDelegate`.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [provider](https://pub.dev/packages/provider) | State management |
| [pdfrx](https://pub.dev/packages/pdfrx) | PDF rendering |
| [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) | Markdown rendering |
| [file_picker](https://pub.dev/packages/file_picker) | File system dialogs |
| [pdf](https://pub.dev/packages/pdf) | PDF generation (markdown-to-PDF) |
| [window_manager](https://pub.dev/packages/window_manager) | Desktop window controls |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Persist user settings |
| [path](https://pub.dev/packages/path) | Path utilities |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Open document |
| `Ctrl+S` | Save changes |
| `Ctrl+Shift+C` | Convert PDF ↔ Markdown |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |
| `F5` / `Ctrl+Meta+F` | Toggle fullscreen |

---

## Windows: Set as default app for PDF & Markdown

On first launch, PDF Dreamer registers itself as an available handler for `.pdf` and `.md` files via the Windows Registry (HKCU — no admin required).

To set PDF Dreamer as the **default** application:

1. Right-click any `.pdf` or `.md` file
2. Select **Open with → Choose another app**
3. Find **pdf_dreamer** in the list and check **"Always use this app"**

You can also configure it via Windows Settings:

- **Settings → Apps → Default Apps → Choose defaults by file type**
- Find `.pdf` and `.md`, then select PDF Dreamer

To **unregister** file associations, delete the registry key:
```
HKCU\Software\Classes\Applications\pdf_dreamer.exe
```

---

## Custom App Icon

The app icon is embedded via `windows/runner/resources/app_icon.ico`. To replace it:

1. Generate a `.ico` file containing sizes 16, 32, 48, 64, 128, and 256 px from your source image
2. Overwrite `windows/runner/resources/app_icon.ico`
3. Rebuild: `flutter build windows`

On Linux, replace the icon assets under `linux/`. On macOS, replace the `.icns` in `macos/Runner/Assets.xcassets`.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## About

Developed by [Mirazo Labs](https://mirazolabs.io) — building tools that empower creators.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/mirazolabs/pdf_dreamer).

### Development

```bash
# Run analyzer
flutter analyze

# Run tests
flutter test
```
