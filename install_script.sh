TMP_DIR=$(mktemp -d)
echo "Created: $TMP_DIR"
cd "$TMP_DIR" || exit 1
git clone https://github.com/rohanvashisht1234/zigp --depth=1
cd zigp
echo "Installing zigp: $TMP_DIR"
zig build install --prefix ~/.local/zigp

if [[ ":$PATH:" != *":$HOME/.local/zigp/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/zigp/bin:$PATH"' >> ~/.bashrc 2>/dev/null || true
  echo 'export PATH="$HOME/.local/zigp/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
  echo "Added ~/.local/bin/zigp to your PATH (will apply on next shell start)"
fi

rm -rf "$TMP_DIR"
cd ~
