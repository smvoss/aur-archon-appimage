# Maintainer: smvoss

pkgname=archon-appimage
_pkgapp=archon
pkgver=9.0.1
pkgrel=1
pkgdesc="Desktop uploader app for Archon packaged from the upstream AppImage"
arch=('x86_64')
url='https://www.archon.gg/download'
license=('custom')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'cairo'
  'cups'
  'dbus'
  'expat'
  'gcc-libs'
  'glib2'
  'glibc'
  'gtk3'
  'libdrm'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'mesa'
  'nspr'
  'nss'
  'pango'
)
optdepends=(
  'libappindicator-gtk3: tray icon support on some desktop environments'
)
provides=('archon')
conflicts=('archon' 'archon-bin')
source=(
  "${_pkgapp}-v${pkgver}.AppImage::https://github.com/RPGLogs/Uploaders-archon/releases/download/v${pkgver}/archon-v${pkgver}.AppImage"
)
sha256sums=(
  '72128a05e40f0ccb27154c91dc2cacb6d9535d974c51b84d91426afddc8974d6'
)
options=(!strip)

prepare() {
  cd "${srcdir}"

  chmod +x "${_pkgapp}-v${pkgver}.AppImage"
  ./"${_pkgapp}-v${pkgver}.AppImage" --appimage-extract >/dev/null
}

package() {
  cd "${srcdir}"

  install -dm755 "${pkgdir}/opt/${pkgname}"
  cp -a squashfs-root/. "${pkgdir}/opt/${pkgname}/"

  printf '#!/bin/sh\nexec /opt/%s/AppRun --no-sandbox "$@"\n' "${pkgname}" \
    > "${srcdir}/${_pkgapp}"
  install -Dm755 "${srcdir}/${_pkgapp}" "${pkgdir}/usr/bin/${_pkgapp}"

  install -Dm644 \
    "${pkgdir}/opt/${pkgname}/usr/share/icons/hicolor/512x512/apps/Archon App.png" \
    "${pkgdir}/usr/share/icons/hicolor/512x512/apps/archon.png"

  install -Dm644 \
    "${pkgdir}/opt/${pkgname}/Archon App.desktop" \
    "${pkgdir}/usr/share/applications/archon.desktop"
  sed -i \
    -e 's|^Exec=.*|Exec=/usr/bin/archon %U|' \
    -e 's|^Icon=.*|Icon=archon|' \
    "${pkgdir}/usr/share/applications/archon.desktop"

  install -Dm644 \
    "${pkgdir}/opt/${pkgname}/LICENSE.electron.txt" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE.electron.txt"
  install -Dm644 \
    "${pkgdir}/opt/${pkgname}/LICENSES.chromium.html" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSES.chromium.html"
}
