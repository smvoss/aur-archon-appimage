# archon-appimage

AUR packaging repo for the Archon Linux AppImage release.

## Release source

- Download page: <https://www.archon.gg/download>
- Release assets: <https://github.com/RPGLogs/Uploaders-archon/releases>

## Publishing

Regenerate `.SRCINFO` before each push:

```bash
makepkg --printsrcinfo > .SRCINFO
```
