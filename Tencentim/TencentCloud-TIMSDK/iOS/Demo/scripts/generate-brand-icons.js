/**
 * Generate 云链通 brand icons for iOS from Android ic_brand_logo / ic_launcher vectors.
 * Android refs: ic_brand_logo.xml, ic_launcher.xml (108dp canvas).
 */
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const REF = 108;
const COLOR_START = [0x15, 0x65, 0xc0];
const COLOR_END = [0x42, 0xa5, 0xf5];
const LAUNCHER_BG = [0x15, 0x65, 0xc0];
const STROKE = [0x8c, 0xff, 0xff, 0xff];

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function gradientAt(x, y, w, h) {
  const t = (x / w + y / h) * 0.5;
  return [
    Math.round(lerp(COLOR_START[0], COLOR_END[0], t)),
    Math.round(lerp(COLOR_START[1], COLOR_END[1], t)),
    Math.round(lerp(COLOR_START[2], COLOR_END[2], t)),
    255,
  ];
}

function roundedRectContains(left, top, w, h, r, x, y) {
  r = Math.min(r, w / 2, h / 2);
  const right = left + w;
  const bottom = top + h;

  if (x >= left + r && x < right - r && y >= top && y < bottom) return true;
  if (y >= top + r && y < bottom - r && x >= left && x < right) return true;

  const corners = [
    [left + r, top + r],
    [right - r, top + r],
    [left + r, bottom - r],
    [right - r, bottom - r],
  ];
  for (const [cx, cy] of corners) {
    const dx = x + 0.5 - cx;
    const dy = y + 0.5 - cy;
    if (dx * dx + dy * dy <= r * r) return true;
  }
  return false;
}

function distanceToRoundedRectEdge(x, y, left, top, w, h, r) {
  r = Math.min(r, w / 2, h / 2);
  const right = left + w;
  const bottom = top + h;

  if (x >= left + r && x < right - r) {
    return Math.min(y - top, bottom - y);
  }
  if (y >= top + r && y < bottom - r) {
    return Math.min(x - left, right - x);
  }

  let best = Infinity;
  const corners = [
    [left + r, top + r],
    [right - r, top + r],
    [left + r, bottom - r],
    [right - r, bottom - r],
  ];
  for (const [cx, cy] of corners) {
    const dx = x + 0.5 - cx;
    const dy = y + 0.5 - cy;
    const dist = Math.sqrt(dx * dx + dy * dy);
    best = Math.min(best, Math.abs(dist - r));
  }
  return best;
}

function setPixel(data, size, x, y, rgba) {
  if (x < 0 || y < 0 || x >= size || y >= size) return;
  const i = (size * y + x) << 2;
  data[i] = rgba[0];
  data[i + 1] = rgba[1];
  data[i + 2] = rgba[2];
  data[i + 3] = rgba[3];
}

function drawBrandLogo(png, offsetX, offsetY, drawSize) {
  const { width: size, data } = png;
  const outerR = (22 / REF) * drawSize;
  const inset = (18 / REF) * drawSize;
  const innerR = (12 / REF) * drawSize;
  const strokeW = Math.max(1, (2.5 / REF) * drawSize);

  for (let y = 0; y < drawSize; y++) {
    for (let x = 0; x < drawSize; x++) {
      const gx = offsetX + x;
      const gy = offsetY + y;
      if (!roundedRectContains(offsetX, offsetY, drawSize, drawSize, outerR, gx, gy)) continue;

      const innerX = offsetX + inset;
      const innerY = offsetY + inset;
      const innerW = drawSize - inset * 2;
      const innerH = drawSize - inset * 2;

      if (roundedRectContains(innerX, innerY, innerW, innerH, innerR, gx, gy)) {
        const edgeDist = distanceToRoundedRectEdge(gx, gy, innerX, innerY, innerW, innerH, innerR);
        if (edgeDist <= strokeW / 2) {
          setPixel(data, size, gx, gy, STROKE);
        }
        continue;
      }

      setPixel(data, size, gx, gy, gradientAt(x, y, drawSize, drawSize));
    }
  }
}

function renderLauncherIcon(size) {
  const png = new PNG({ width: size, height: size });
  const outerR = (22 / REF) * size;
  const logoInset = (16 / REF) * size;
  const logoSize = size - logoInset * 2;

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (roundedRectContains(0, 0, size, size, outerR, x, y)) {
        setPixel(png.data, size, x, y, [...LAUNCHER_BG, 255]);
      }
    }
  }

  drawBrandLogo(png, logoInset, logoInset, logoSize);
  return png;
}

function renderBrandLogo(size) {
  const png = new PNG({ width: size, height: size });
  drawBrandLogo(png, 0, 0, size);
  return png;
}

function renderBrandLogoCentered(canvasW, canvasH, logoSize) {
  const png = new PNG({ width: canvasW, height: canvasH });
  const ox = Math.round((canvasW - logoSize) / 2);
  const oy = Math.round((canvasH - logoSize) / 2);
  drawBrandLogo(png, ox, oy, logoSize);
  return png;
}

function writePng(png, outPath) {
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, PNG.sync.write(png));
  console.log('wrote', outPath);
}

const demoRoot = path.resolve(__dirname, '..');
const assets = path.join(demoRoot, 'TUIKitDemo', 'Assets.xcassets');
const themeRoot = path.join(demoRoot, 'TUIKitDemo', 'TIMAppKit', 'Resources', 'TUIDemoTheme.bundle');

writePng(renderLauncherIcon(1024), path.join(assets, 'AppIcon.appiconset', 'AppIcon.png'));
writePng(renderLauncherIcon(120), path.join(assets, 'AppIcon.appiconset', 'AppIcon120.png'));
writePng(renderLauncherIcon(180), path.join(assets, 'AppIcon.appiconset', 'AppIcon180.png'));

const login3x = 168;
const login2x = 112;
writePng(renderBrandLogo(login3x), path.join(assets, 'public_login_logo.imageset', 'public_login_logo@3x.png'));
writePng(renderBrandLogo(login2x), path.join(assets, 'login_logo.imageset', 'login_logo@2x.png'));
writePng(renderBrandLogo(login3x), path.join(assets, 'login_logo.imageset', 'login_logo@3x.png'));

const launchW = 480;
const launchH = 240;
const launchLogo = 168;

for (const theme of ['light', 'dark', 'lively', 'serious']) {
  const themeDir = path.join(themeRoot, theme);
  writePng(renderBrandLogo(login3x), path.join(themeDir, 'public_login_logo.png'));
  writePng(
    renderBrandLogoCentered(launchW, launchH, launchLogo),
    path.join(themeDir, 'launch_page_logo.png')
  );
}

console.log('Done — brand icons generated from Android ic_brand_logo design.');
