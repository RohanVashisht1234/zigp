TMP_DIR=$(mktemp -d)
echo "Created: $TMP_DIR"
cd "$TMP_DIR" || exit 1
git clone https://github.com/Zigistry/zigp --depth=1
cd zigp
echo "Installing zigp: $TMP_DIR"
zig build install --prefix ~/.local

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc 2>/dev/null || true
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
  echo "Added ~/.local/bin to your PATH (will apply on next shell start)"
fi

rm -rf "$TMP_DIR"
cd ~
