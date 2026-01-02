# consult-vulpea

Use [Consult](https://github.com/minad/consult) in tandem with [Vulpea](https://github.com/d12frosted/vulpea).

## Features

- **Live previews**: When selecting notes via `vulpea-find` or `vulpea-insert`, get a live preview of the note file as you navigate through candidates.
- **Consult-powered grep/find**: Use `consult-vulpea-grep` and `consult-vulpea-find` to search within your vulpea directories with live previews.

## Installation

### Manual

Clone this repository and add to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/consult-vulpea")
(require 'consult-vulpea)
(consult-vulpea-mode 1)
```

### package-vc (Emacs 29+)

```elisp
(package-vc-install "https://github.com/fabcontigiani/consult-vulpea")
(require 'consult-vulpea)
(consult-vulpea-mode 1)
```

### use-package with package-vc (Emacs 30+)

```elisp
(use-package consult-vulpea
  :vc (:url "https://github.com/fabcontigiani/consult-vulpea")
  :after vulpea
  :config
  (consult-vulpea-mode 1))
```

### Doom Emacs

Add to `packages.el`:

```elisp
(package! consult-vulpea
  :recipe (:host github :repo "fabcontigiani/consult-vulpea"))
```

Add to `config.el`:

```elisp
(use-package! consult-vulpea
  :after vulpea
  :config
  (consult-vulpea-mode 1))
```

### Elpaca

```elisp
(use-package consult-vulpea
  :ensure (:host github :repo "fabcontigiani/consult-vulpea")
  :after vulpea
  :config
  (consult-vulpea-mode 1))
```

> [!IMPORTANT]
> Do not use `:after consult` — this can prevent the package from loading properly at startup.

## Commands

| Command | Description |
|---------|-------------|
| `consult-vulpea-grep` | Search vulpea notes using ripgrep with live preview |
| `consult-vulpea-find` | Find vulpea note files with live preview |

## Customization

| Variable | Default | Description |
|----------|---------|-------------|
| `consult-vulpea-grep-command` | `consult-ripgrep` | Grep command to use (can also be `consult-grep`) |
| `consult-vulpea-find-command` | `consult-find` | Find command to use |

## How it works

When `consult-vulpea-mode` is enabled, the package advises `vulpea-select-from` with a consult-powered replacement. This means all vulpea commands that use the note selection interface (like `vulpea-find` and `vulpea-insert`) automatically gain consult features.

## Requirements

- Emacs 28.1+
- [vulpea](https://github.com/d12frosted/vulpea) 2.0.0+
- [consult](https://github.com/minad/consult) 2.2+

## Related

- [consult-denote](https://github.com/protesilaos/consult-denote) — Similar integration for [Denote](https://github.com/protesilaos/denote)

## License

GPL-3.0
