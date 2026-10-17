# PDF Dreamer for Linux

Extract the complete `.tar.gz` archive, open a terminal in the extracted directory,
and run this as your desktop user (do not use `sudo`):

```bash
bash install.sh
```

This installs PDF Dreamer for the current user and requests it as the default
reader for PDF and Markdown. Run in your normal graphical desktop session.
To install without changing existing defaults:

```bash
bash install.sh --no-defaults
```

The archive includes the complete Flutter bundle. You do not need Flutter or
development tools on the destination computer. You do need a compatible Linux
desktop, GTK 3 and the system libraries required by the bundle, plus `xdg-utils`,
`shared-mime-info`, and `desktop-file-utils` for integration. On Ubuntu/Debian,
install those integration tools using your system package manager. The installer
does not run package-manager commands or use elevated privileges.

Builds are architecture-specific (x64 or ARM64) and depend on the Linux/glibc
version used to compile them. They are not universal binaries for every distro.
Use `ldd bundle/pdf_dreamer` and check libraries in `bundle/lib/` to diagnose
missing runtime dependencies. Markdown-to-PDF export also requires Microsoft Edge,
Google Chrome, or Chromium.

Files are installed under `${XDG_DATA_HOME:-$HOME/.local/share}/pdf_dreamer`.
The application menu entry is `io.mirazolabs.pdf_dreamer.desktop` under the
`applications` directory of the same data home. Markdown MIME metadata and the
app icon are also registered there. No general `text/plain` default is changed.

The installer checks each default with `xdg-mime query default`. Your desktop or
system policy may still require selecting PDF Dreamer in its default-app settings.
Verify in a file manager that both PDF and Markdown open correctly, including
paths with spaces and accented characters. Each launch opens a separate window.
The `%f` desktop field supplies a single local document to the existing viewer.

Re-running the installer installs a separate release and switches the `current`
symlink. Older release directories are retained so running windows can keep using
their files. Close old windows before manually removing old release directories.
Installation with defaults enabled applies the requested defaults again; use
`--no-defaults` during upgrades to preserve later preference changes.

To remove the app, first select another PDF/Markdown reader in desktop settings.
Then remove the `pdf_dreamer` installation directory, its application menu entry,
`icons/io.mirazolabs.pdf_dreamer.png`, and
`mime/packages/io.mirazolabs.pdf_dreamer-markdown.xml` from your data home. Refresh
the desktop and MIME databases with `update-desktop-database` and
`update-mime-database`. The installer does not automatically restore old defaults.

PDF Dreamer is developed by Mirazo Labs. See the included `LICENSE` file.
