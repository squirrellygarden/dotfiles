# Plugin for [yazi](https://github.com/sxyazi/yazi) for Krita document preview

## Usage:

1) Ensure, that you have `unzip` in the path
2) Clone this repo into ~/.config/yazi/plugins/krita.yazi directory
3) Add the following content into ~/.config/yazi/yazi.toml file:
```toml
[plugin]
prepend_previewers = [
  { name = "*.kra", run = "krita" }
]

prepend_preloaders = [
  { name = "*.kra", run = "krita" }
]
```
