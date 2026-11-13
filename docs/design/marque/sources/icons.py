"""Icônes Android (héritées + adaptatives) et image du splash natif des apps.

Chaque app a son fond pour se distinguer sur le téléphone :
client vert marque, vendeuse claire, livreur plantain.
"""
import os
import subprocess
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..'))
EDGE = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
OUT = os.path.join(HERE, 'build')
os.makedirs(OUT, exist_ok=True)

LEAVES = ('M142.0,56.0 Q127.0,47.0 127.9,29.5 Q142.9,38.5 142.0,56.0 Z',
          'M142.0,56.0 Q141.6,35.4 158.9,24.2 Q159.3,44.8 142.0,56.0 Z')

APPS = {
    # app: (fond, sac, anse, feuilles)
    'dym_client': ('#145C43', '#FFFFFF', '#F6C343', '#F6C343'),
    'dym_vendor': ('#FAFAF7', '#145C43', '#0E4632', '#3FA06B'),
    'dym_delivery': ('#F6C343', '#0E4632', '#145C43', '#145C43'),
}


def svg(bg, bag, handle, leaves, box):
    """box = taille du cadre (340 : icône pleine ; 460 : zone sûre adaptative)."""
    x0, y0 = 141 - box / 2, 107 - box / 2
    rect = f'<rect x="{x0}" y="{y0}" width="{box}" height="{box}" fill="{bg}"/>' if bg else ''
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {box} {box}" width="1024" height="1024">
  {rect}
  <path d="{LEAVES[0]}" fill="{leaves}"/><path d="{LEAVES[1]}" fill="{leaves}"/>
  <g fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="12">
    <polygon points="89.0,50.0 194.0,50.0 230.0,208.0 53.0,208.0" stroke="{bag}"/>
    <polyline points="89.0,50.0 142.0,111.0 194.0,50.0" stroke="{bag}"/>
    <polyline points="142.0,111.0 142.0,208.0" stroke="{bag}"/>
    <path d="M116.0,65.0 L116.0,36.0 C116.0,6.0 168.0,6.0 168.0,36.0 L168.0,65.0" stroke="{handle}"/>
  </g>
  <circle cx="116.0" cy="65.0" r="6" fill="{handle}"/>
  <circle cx="168.0" cy="65.0" r="6" fill="{handle}"/>
</svg>'''


def render(name, content):
    """SVG → PNG 1024 (Edge sans tête, fond transparent)."""
    sp = os.path.join(OUT, name + '.svg')
    pp = os.path.join(OUT, name + '.png')
    open(sp, 'w', encoding='utf-8').write(content)
    html = os.path.join(OUT, name + '.html')
    open(html, 'w', encoding='utf-8').write(
        f'<html><body style="margin:0;background:transparent"><img src="{name}.svg" width="1024" height="1024"></body></html>')
    subprocess.run([EDGE, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--default-background-color=00000000', '--window-size=1024,1024',
                    f'--screenshot={pp}', 'file:///' + html.replace('\\', '/')],
                   check=True, capture_output=True)
    return Image.open(pp).convert('RGBA').crop((0, 0, 1024, 1024))


LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
ADAPT = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
SPLASH = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def rounded(im, radius):
    mask = Image.new('L', im.size, 0)
    from PIL import ImageDraw
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius, fill=255)
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


# Image du splash natif : sac vert sur transparent (fond #FAFAF7), commun.
splash = render('splash_logo', svg(None, '#145C43', '#0E4632', '#3FA06B', 340))
# Android 12+ : icône animée 240 dp dont 160 dp visibles → cadre élargi.
splash12 = render('splash_icon', svg(None, '#145C43', '#0E4632', '#3FA06B', 520))

for app, (bg, bag, handle, leaves) in APPS.items():
    full = render(f'{app}_full', svg(bg, bag, handle, leaves, 340))
    fg = render(f'{app}_fg', svg(None, bag, handle, leaves, 460))
    mono = render(f'{app}_mono', svg(None, '#FFFFFF', '#FFFFFF', '#FFFFFF', 460))
    res = os.path.join(REPO, 'apps', app, 'android', 'app', 'src', 'main', 'res')
    for d, px in LEGACY.items():
        rounded(full, 180).resize((px, px), Image.LANCZOS).save(os.path.join(res, f'mipmap-{d}', 'ic_launcher.png'))
    for d, px in ADAPT.items():
        fg.resize((px, px), Image.LANCZOS).save(os.path.join(res, f'mipmap-{d}', 'ic_launcher_foreground.png'))
        mono.resize((px, px), Image.LANCZOS).save(os.path.join(res, f'mipmap-{d}', 'ic_launcher_monochrome.png'))
    for d, f in SPLASH.items():
        os.makedirs(os.path.join(res, f'drawable-{d}'), exist_ok=True)
        px = round(160 * f)
        splash.resize((px, px), Image.LANCZOS).save(os.path.join(res, f'drawable-{d}', 'splash_logo.png'))
        px = round(240 * f)
        splash12.resize((px, px), Image.LANCZOS).save(os.path.join(res, f'drawable-{d}', 'splash_icon.png'))
    os.makedirs(os.path.join(res, 'mipmap-anydpi-v26'), exist_ok=True)
    open(os.path.join(res, 'mipmap-anydpi-v26', 'ic_launcher.xml'), 'w', encoding='utf-8').write(
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''')
    open(os.path.join(res, 'values', 'colors.xml'), 'w', encoding='utf-8').write(
        f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Fond de l'icône adaptative (docs/design/marque/). -->
    <color name="ic_launcher_background">{bg}</color>
    <!-- Fond du splash natif, identique au splash animé de l'app. -->
    <color name="splash_background">#FAFAF7</color>
</resources>
''')
    full.save(os.path.join(OUT, f'{app}_apercu.png'))
print('ok')
