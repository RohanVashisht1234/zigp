# Experimental Zig CLI package manager

To install run:

```bash
curl https://raw.githubusercontent.com/rohanvashisht1234/zigp/main/install_script.sh -sSf | sh
```


### What all can this do right now?

#### Adding a package to your zig project:

```bash
zigp add gh/<owner-name>/<repo-name>

# Example:
zigp add gh/capy-ui/capy
```

#### Installing a program as a binary file (This will also export it to your $PATH):

```bash
zigp install gh/<owner-name>/<repo-name>

# Example:
zigp install gh/zigtools/zls
```

#### Seeing info of a specific repository

```bash
zigp info gh/<owner-name>/<repo-name>

# Example:
zigp info gh/zigtools/zls
```
#### Self updating zigp to the latest version

```bash
zigp self-update
```
