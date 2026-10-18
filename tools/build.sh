#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
revision=fd415517ecd9f6379ffc8ff2081ed69de53f1201
source_dir="${EGUI_SOURCE_DIR:-$PWD/.build/egui}"
mkdir -p .build site
if [[ ! -d "$source_dir/.git" ]]; then
  git clone https://github.com/0x53A/egui "$source_dir"
fi
git -C "$source_dir" checkout "$revision"
# Use browser-loaded copies of the bundled fonts, without the Rust font backend.
if git -C "$source_dir" apply --check "$PWD/tools/browser-demo.patch"; then
  git -C "$source_dir" apply "$PWD/tools/browser-demo.patch"
else
  git -C "$source_dir" apply --reverse --check "$PWD/tools/browser-demo.patch"
fi
rustup target add --toolchain 1.97.1 wasm32-unknown-unknown
cargo +1.97.1 build --manifest-path "$source_dir/Cargo.toml" --locked \
  -p egui_demo_app --lib --release --target wasm32-unknown-unknown \
  --no-default-features --features web_app,glow
# Set WASM_BINDGEN to an existing matching binary to avoid installing the CLI.
if [[ -z "${WASM_BINDGEN:-}" ]]; then
  cargo +1.97.1 install --root "$PWD/.tools" wasm-bindgen-cli --version 0.2.126 --locked
  WASM_BINDGEN="$PWD/.tools/bin/wasm-bindgen"
fi
"$WASM_BINDGEN" "$source_dir/target/wasm32-unknown-unknown/release/egui_demo_app.wasm" \
  --out-dir site --out-name egui_demo_app --no-modules --no-typescript
wasm-opt site/egui_demo_app_bg.wasm -O2 --fast-math -o site/egui_demo_app_bg.wasm
# Do not copy upstream CNAME (egui.rs).
cp "$source_dir/web_demo/index.html" "$source_dir/web_demo/favicon.ico" site/
sed -i 's/<title>.*<\/title>/<title>egui demo — browser fonts<\/title>/' site/index.html
mkdir -p site/fonts
for file in Ubuntu-Light.ttf Hack-Regular.ttf egui-icons.ttf UFL.txt Hack-Regular.txt emoji-icon-font-mit-license.txt; do
  cp "$source_dir/crates/epaint_default_fonts/fonts/$file" site/fonts/
done
sed -i '/<script src=".\/egui_demo_app.js"><\/script>/a\    <script src="./fonts.js"></script>' site/index.html
sed -i 's/wasm_bindgen(".\/egui_demo_app_bg.wasm")/Promise.all([loadEguiFonts(), wasm_bindgen(".\/egui_demo_app_bg.wasm")])/' site/index.html
printf '%s\n' "$revision" > site/revision.txt
