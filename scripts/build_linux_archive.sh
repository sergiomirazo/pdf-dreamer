#!/usr/bin/env bash
# Build on Linux, or package a prebuilt Linux bundle using --skip-build.
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
skip_build=false
bundle_dir=
output_dir="$project_root/build/installer"
usage() {
  echo "Usage: bash scripts/build_linux_archive.sh [--skip-build] [--bundle-dir DIR] [--output-dir DIR]"
}
while (($#)); do
  case "$1" in
    --skip-build) skip_build=true; shift ;;
    --bundle-dir|--output-dir)
      (($# >= 2)) || { usage >&2; exit 1; }
      if [[ $1 == --bundle-dir ]]; then bundle_dir=$2; else output_dir=$2; fi
      shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

cd -- "$project_root"
app_name=$(sed -nE 's/^name:[[:space:]]*([a-z_][a-z0-9_]*).*$/\1/p' pubspec.yaml | tr -d '\r')
version=$(sed -nE 's/^version:[[:space:]]*([^[:space:]#]+).*$/\1/p' pubspec.yaml | tr -d '\r')
app_id=$(sed -nE 's/^set\(APPLICATION_ID "([^"]+)"\).*/\1/p' linux/CMakeLists.txt | tr -d '\r')
[[ $app_name =~ ^[a-z_][a-z0-9_]*$ && $version =~ ^[0-9][a-zA-Z0-9.+-]*$ && $app_id =~ ^[a-zA-Z0-9_.-]+$ ]] || {
  echo "Cannot read application metadata from pubspec.yaml and linux/CMakeLists.txt." >&2; exit 1;
}
if [[ $skip_build == false ]]; then
  [[ $(uname -s) == Linux ]] || { echo "Flutter Linux builds must run on Linux." >&2; exit 1; }
  flutter build linux --release
fi
if [[ -z $bundle_dir ]]; then
  case "$(uname -m)" in
    x86_64|amd64) arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported host architecture. Supply --bundle-dir for a prebuilt bundle." >&2; exit 1 ;;
  esac
  bundle_dir="$project_root/build/linux/$arch/release/bundle"
fi
bundle_dir=$(cd -- "$bundle_dir" && pwd)
binary="$bundle_dir/$app_name"
[[ -f $binary && -d $bundle_dir/lib && -d $bundle_dir/data ]] || {
  echo "Incomplete Linux bundle: expected $app_name, lib/ and data/ in $bundle_dir" >&2; exit 1;
}
# Inspect the ELF header rather than labelling a Windows EXE as a Linux release.
header=$(od -An -tx1 -N20 -- "$binary" | tr -d ' \n\r')
[[ ${header:0:12} == 7f454c460201 ]] || { echo "Expected a 64-bit little-endian Linux ELF executable." >&2; exit 1; }
case "${header:36:4}" in
  3e00) arch=x64 ;;
  b700) arch=arm64 ;;
  *) echo "Unsupported ELF architecture." >&2; exit 1 ;;
esac

mkdir -p -- "$output_dir"
output_dir=$(cd -- "$output_dir" && pwd)
package="$app_name-$version-linux-$arch"
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT
mkdir -p -- "$staging/$package/bundle"
cp -a -- "$bundle_dir/." "$staging/$package/bundle/"
cp -- installer/linux/install.sh installer/linux/markdown.xml LICENSE "$staging/$package/"
cp -- assets/img/PDF-DREAMER-LOGO.png "$staging/$package/icon.png"
printf 'APP_NAME=%s\nAPP_ID=%s\nAPP_VERSION=%s\nAPP_ARCH=%s\n' \
  "$app_name" "$app_id" "$version" "$arch" > "$staging/$package/package.conf"
cp -- installer/linux/README.md "$staging/$package/README.md"
chmod 755 "$staging/$package/install.sh" "$staging/$package/bundle/$app_name"
archive="$output_dir/$package.tar.gz"
# Write to a temporary archive first so a failed build cannot replace a release.
tar -czf "$staging/archive.tar.gz" -C "$staging" "$package"
mv -f -- "$staging/archive.tar.gz" "$archive"
echo "Archive created: $archive"
