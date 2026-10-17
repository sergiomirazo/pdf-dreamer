#!/usr/bin/env bash
# Isolated packaging/integration tests. The ELF fixture is NOT a runnable app.
set -euo pipefail
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
bundle="$sandbox/bundle input"
mkdir -p "$bundle/data" "$bundle/lib" "$sandbox/output"
# Minimal ELF header: ELF64, little endian, x86-64.
printf '\177ELF\002\001\001\000\000\000\000\000\000\000\000\000\002\000\076\000' > "$bundle/pdf_dreamer"
echo fixture > "$bundle/lib/fixture.so"
echo fixture > "$bundle/data/fixture.dat"
bash "$project_root/scripts/build_linux_archive.sh" --skip-build \
  --bundle-dir "$bundle" --output-dir "$sandbox/output"
archives=("$sandbox/output/"*.tar.gz)
[[ ${#archives[@]} == 1 && -f ${archives[0]} ]]
tar -xzf "${archives[0]}" -C "$sandbox"
packages=("$sandbox"/pdf_dreamer-*-linux-x64)
package=${packages[0]}
[[ -x $package/install.sh && -f $package/bundle/pdf_dreamer ]]
# MSYS checks executable permission using Windows rules, not Linux ELF rules.
if [[ $(uname -s) == Linux ]]; then [[ -x $package/bundle/pdf_dreamer ]]; fi
[[ -f $package/bundle/lib/fixture.so && -f $package/bundle/data/fixture.dat ]]
[[ -f $package/markdown.xml && -f $package/icon.png && -f $package/LICENSE ]]

# Simulate XDG tools only inside this process tree; no real desktop is modified.
export TEST_STATE="$sandbox/state"
mkdir -p "$TEST_STATE"
uname() {
  case "$1" in -s) echo Linux ;; -m) echo "${TEST_MACHINE:-x86_64}" ;; esac
}
id() { echo "${TEST_UID:-1000}"; }
update-mime-database() { printf 'mime:%s\n' "$*" >> "$TEST_STATE/cache.log"; }
update-desktop-database() { printf 'desktop:%s\n' "$*" >> "$TEST_STATE/cache.log"; }
if ! command -v desktop-file-validate >/dev/null; then
  desktop-file-validate() { [[ -f $1 ]]; }
  export -f desktop-file-validate
fi
xdg-mime() {
  printf '%s\n' "$*" >> "$TEST_STATE/xdg.log"
  if [[ $1 == default ]]; then
    [[ ${TEST_DEFAULT_FAILURE:-false} != true ]] || return 4
    printf '%s\n' "$2" > "$TEST_STATE/${3//\//_}"
  elif [[ $1 == query && $2 == default ]]; then
    cat "$TEST_STATE/${3//\//_}"
  else
    return 1
  fi
}
export -f uname id update-mime-database update-desktop-database xdg-mime
export XDG_DATA_HOME="$sandbox/data ágil 50% \$money"
export HOME="$sandbox/home"
desktop="$XDG_DATA_HOME/applications/io.mirazolabs.pdf_dreamer.desktop"

bash "$package/install.sh"
[[ -f $desktop && -f $XDG_DATA_HOME/pdf_dreamer/current/pdf_dreamer ]]
grep -Fq '50%% \\$money' "$desktop"
grep -Fq ' %f' "$desktop"
grep -Fxq 'MimeType=application/pdf;text/markdown;text/x-markdown;' "$desktop"
grep -Fxq 'io.mirazolabs.pdf_dreamer.desktop' "$TEST_STATE/application_pdf"
grep -Fxq 'io.mirazolabs.pdf_dreamer.desktop' "$TEST_STATE/text_markdown"
grep -Fxq 'io.mirazolabs.pdf_dreamer.desktop' "$TEST_STATE/text_x-markdown"
[[ -f $XDG_DATA_HOME/mime/packages/io.mirazolabs.pdf_dreamer-markdown.xml ]]
first_release=$(readlink "$XDG_DATA_HOME/pdf_dreamer/current")

# --no-defaults neither queries nor changes any association during an upgrade.
printf 'other.desktop\n' > "$TEST_STATE/application_pdf"
before=$(wc -l < "$TEST_STATE/xdg.log")
bash "$package/install.sh" --no-defaults
[[ $(wc -l < "$TEST_STATE/xdg.log") == "$before" ]]
grep -Fxq other.desktop "$TEST_STATE/application_pdf"
[[ $(readlink "$XDG_DATA_HOME/pdf_dreamer/current") != "$first_release" ]]
[[ -f $first_release/pdf_dreamer ]]
! grep -Fq text/plain "$TEST_STATE/xdg.log"

# Policy failures must not be reported as successful default configuration.
if TEST_DEFAULT_FAILURE=true bash "$package/install.sh" > "$sandbox/failure.log" 2>&1; then
  echo "Expected default-setting failure." >&2; exit 1
fi
grep -Fq 'some default associations were not applied' "$sandbox/failure.log"

# Reject root and architecture mismatches before copying any files.
for invalid in root architecture; do
  if [[ $invalid == root ]]; then export TEST_UID=0; else export TEST_MACHINE=aarch64; fi
  if bash "$package/install.sh" --no-defaults > "$sandbox/rejection.log" 2>&1; then
    echo "Expected installer rejection: $invalid" >&2; exit 1
  fi
  unset TEST_UID TEST_MACHINE
done

# Never package a Windows binary as a Linux release.
printf MZ > "$bundle/pdf_dreamer"
if bash "$project_root/scripts/build_linux_archive.sh" --skip-build --bundle-dir "$bundle" \
    --output-dir "$sandbox/output" > "$sandbox/invalid.log" 2>&1; then
  echo "Expected non-ELF bundle rejection." >&2; exit 1
fi
grep -Fq 'Expected a 64-bit little-endian Linux ELF executable' "$sandbox/invalid.log"
echo "Linux packaging tests passed (fixture bundle and simulated XDG tools)."
