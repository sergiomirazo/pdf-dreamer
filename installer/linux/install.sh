#!/usr/bin/env bash
# Installs only for the current user. No shell commands are read from metadata.
set -euo pipefail

set_defaults=true
case "${1:-}" in
  --no-defaults) set_defaults=false; shift ;;
  --help|-h)
    echo "Usage: bash install.sh [--no-defaults]"
    echo "Installs for the current user and makes PDF Dreamer the PDF/Markdown default."
    echo "Use --no-defaults to preserve existing default applications."
    exit 0 ;;
esac
(($# == 0)) || { echo "Unknown arguments: $*" >&2; exit 1; }
[[ $(uname -s) == Linux ]] || { echo "This installer requires Linux." >&2; exit 1; }
[[ $(id -u) != 0 ]] || { echo "Run install.sh as your desktop user, without sudo." >&2; exit 1; }

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
metadata="$source_dir/package.conf"
[[ -f $metadata ]] || { echo "Extract the complete release archive before installing." >&2; exit 1; }
read_metadata() { sed -n "s/^$1=//p" "$metadata"; }
app_name=$(read_metadata APP_NAME)
app_id=$(read_metadata APP_ID)
version=$(read_metadata APP_VERSION)
arch=$(read_metadata APP_ARCH)
[[ $app_name =~ ^[a-z_][a-z0-9_]*$ && $app_id =~ ^[a-zA-Z0-9_.-]+$ && $version =~ ^[0-9][a-zA-Z0-9.+-]*$ ]] || {
  echo "Invalid package metadata." >&2; exit 1;
}
case "$(uname -m):$arch" in
  x86_64:x64|amd64:x64|aarch64:arm64|arm64:arm64) ;;
  *) echo "This $arch package does not match the host architecture." >&2; exit 1 ;;
esac
[[ -f $source_dir/bundle/$app_name && -d $source_dir/bundle/lib && -d $source_dir/bundle/data ]] || {
  echo "The application bundle is incomplete." >&2; exit 1;
}
for tool in update-mime-database update-desktop-database; do
  command -v "$tool" >/dev/null || { echo "Missing $tool. Install shared-mime-info and desktop-file-utils." >&2; exit 1; }
done
if [[ $set_defaults == true ]]; then
  command -v xdg-mime >/dev/null || { echo "Install xdg-utils to configure default applications." >&2; exit 1; }
fi

data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
[[ $data_home == /* && $data_home != *$'\n'* && $data_home != *$'\r'* && $data_home != *$'\t'* ]] || {
  echo "XDG_DATA_HOME must be an absolute path without control characters." >&2; exit 1;
}
install_root="$data_home/$app_name"
applications="$data_home/applications"
icons="$data_home/icons"
mkdir -p -- "$install_root/releases" "$applications" "$icons" "$data_home/mime/packages"
# Separate release directories avoid mixing DLLs/assets from different builds.
# Existing releases are retained, including files in use by running processes.
release=$(mktemp -d "$install_root/releases/$version-$arch.XXXXXX")
cp -a -- "$source_dir/bundle/." "$release/"
chmod 755 "$release/$app_name"
ln -sfnT -- "$release" "$install_root/current"
cp -- "$source_dir/icon.png" "$icons/$app_id.png"
cp -- "$source_dir/markdown.xml" "$data_home/mime/packages/$app_id-markdown.xml"

# Exec uses desktop-entry quoting, then string-value escaping. It is not a shell
# command. %f passes one local filename; literal percent signs must be doubled.
desktop_exec() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$/\\\$}
  value=${value//\`/\\\`}
  value=${value//%/%%}
  value=${value//\\/\\\\}
  printf '"%s"' "$value"
}
icon_path=${icons//\\/\\\\}
desktop_id="$app_id.desktop"
desktop_file="$applications/$desktop_id"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=PDF Dreamer
Comment=Read, review, sign, and convert PDF and Markdown documents
Exec=$(desktop_exec "$install_root/current/$app_name") %f
Icon=$icon_path/$app_id.png
Terminal=false
Categories=Office;Viewer;
MimeType=application/pdf;text/markdown;text/x-markdown;
StartupWMClass=$app_id
EOF
chmod 644 "$desktop_file"
if command -v desktop-file-validate >/dev/null; then
  desktop-file-validate "$desktop_file"
fi
update-mime-database "$data_home/mime"
update-desktop-database "$applications"
echo "Installed PDF Dreamer: $install_root/current"

if [[ $set_defaults == true ]]; then
  failed=false
  for mime in application/pdf text/markdown text/x-markdown; do
    if xdg-mime default "$desktop_id" "$mime" &&
        [[ $(xdg-mime query default "$mime") == "$desktop_id" ]]; then
      echo "Default confirmed: $mime -> PDF Dreamer"
    else
      echo "Could not confirm default for $mime. Choose PDF Dreamer in your desktop settings." >&2
      failed=true
    fi
  done
  if [[ $failed == true ]]; then
    echo "The app is installed, but some default associations were not applied." >&2
    exit 1
  fi
else
  echo "Existing default applications were preserved (--no-defaults)."
fi
echo "Launch PDF Dreamer from your applications menu."
