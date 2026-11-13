"""Marque DYM v2 : couleurs actuelles, deux feuilles qui sortent du sac.

Produit : logo-dym.svg (sac + nom), icone-dym.svg (fond vert), icone-dym-clair.svg
et l'animation Lottie splash-dym.json (390 × 844, 30 i/s, boucle 60–120).
"""
import base64
import json
import math
import os

from fontTools.pens.basePen import BasePen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OLD = os.path.join(HERE, 'anciens')
FONT = os.path.join(HERE, '..', '..', '..', '..', 'packages', 'ui', 'dym_ui', 'fonts', 'Inter[opsz,wght].ttf')

BRAND, DEEP, LEAF, PLANTAIN, BG, MINT = '#145C43', '#0E4632', '#3FA06B', '#F6C343', '#FAFAF7', '#E8F2EC'


def rgb(h):
    return [int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)] + [1]


# ------------------------------------------------------------ géométrie
K, OX, OY = 2.0, -30, 6


def P(x, y):
    return (OX + x * K, OY + y * K)


BODY = [P(59.5, 22), P(112, 22), P(130, 101), P(41.5, 101)]
FOLD = [P(59.5, 22), P(86, 52.5), P(112, 22)]
SPINE = [P(86, 52.5), P(86, 101)]
H0, H1, TL, TR, H4, H5 = P(73, 29.5), P(73, 15), P(73, 0), P(99, 0), P(99, 15), P(99, 29.5)
MOUTH = P(86, 25)  # base des feuilles, entre les pieds de l'anse


def leaf(base, angle, length, width):
    """Feuille : deux courbes de Bézier de la base à la pointe."""
    a = math.radians(angle)
    tip = (base[0] + math.cos(a) * length, base[1] - math.sin(a) * length)
    nx, ny = -math.sin(a), -math.cos(a)  # normale
    mx, my = (base[0] + tip[0]) / 2, (base[1] + tip[1]) / 2
    c1 = (mx + nx * width, my + ny * width)
    c2 = (mx - nx * width, my - ny * width)
    return base, tip, c1, c2


LEAVES = [leaf(MOUTH, 118, 30, 9), leaf(MOUTH, 62, 36, 10)]

# ------------------------------------------------------------ nom (Inter)
font = instantiateVariableFont(TTFont(FONT), {'wght': 750, 'opsz': 32})
gs, cmap, upm = font.getGlyphSet(), font.getBestCmap(), font['head'].unitsPerEm


def adv(ch, size):
    return gs[cmap[ord(ch)]].width * size / upm - 0.01 * size


def width(text, size):
    return sum(adv(c, size) for c in text)


SIZE = 100 * 262 / width('DoYourMarket', 100)
X0 = (282 - width('DoYourMarket', SIZE)) / 2
BASELINE = 268


def svg_text(text, x):
    pen = SVGPathPen(gs)
    sc = SIZE / upm
    for ch in text:
        gs[cmap[ord(ch)]].draw(TransformPen(pen, (sc, 0, 0, -sc, x, BASELINE)))
        x += adv(ch, SIZE)
    return pen.getCommands()


# ------------------------------------------------------------ SVG
def pts(ps):
    return ' '.join(f'{x:.1f},{y:.1f}' for x, y in ps)


def svg_bag(body, handle, leaf_c, stroke=6.5):
    leaves = ''.join(
        f'<path d="M{b[0]:.1f},{b[1]:.1f} Q{c1[0]:.1f},{c1[1]:.1f} {t[0]:.1f},{t[1]:.1f} '
        f'Q{c2[0]:.1f},{c2[1]:.1f} {b[0]:.1f},{b[1]:.1f} Z" fill="{leaf_c}"/>'
        for b, t, c1, c2 in LEAVES)
    return f'''
  {leaves}
  <g fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="{stroke}">
    <polygon points="{pts(BODY)}" stroke="{body}"/>
    <polyline points="{pts(FOLD)}" stroke="{body}"/>
    <polyline points="{pts(SPINE)}" stroke="{body}"/>
    <path d="M{H0[0]},{H0[1]} L{H1[0]},{H1[1]} C{TL[0]},{TL[1]} {TR[0]},{TR[1]} {H4[0]},{H4[1]} L{H5[0]},{H5[1]}" stroke="{handle}"/>
  </g>
  <circle cx="{H0[0]}" cy="{H0[1]}" r="4.2" fill="{handle}"/>
  <circle cx="{H5[0]}" cy="{H5[1]}" r="4.2" fill="{handle}"/>'''


def write(name, s):
    open(os.path.join(HERE, name), 'w', encoding='utf-8').write(s)


w_do = width('Do', SIZE)
write('logo-dym.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 282 290" width="282" height="290">
  <title>DoYourMarket</title>{svg_bag(BRAND, DEEP, LEAF)}
  <path d="{svg_text('Do', X0)}" fill="{DEEP}"/>
  <path d="{svg_text('YourMarket', X0 + w_do)}" fill="{BRAND}"/>
</svg>
''')
write('icone-dym.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-29 -63 340 340" width="1024" height="1024">
  <rect x="-29" y="-63" width="340" height="340" fill="{BRAND}"/>{svg_bag('#FFFFFF', PLANTAIN, PLANTAIN, 8)}
</svg>
''')
write('icone-dym-avant.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-29 -63 340 340" width="1024" height="1024">
  {svg_bag('#FFFFFF', PLANTAIN, PLANTAIN, 8)}
</svg>
''')
write('icone-dym-clair.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-29 -63 340 340" width="1024" height="1024">
  <rect x="-29" y="-63" width="340" height="340" fill="{BG}"/>{svg_bag(BRAND, DEEP, LEAF, 8)}
</svg>
''')


# ------------------------------------------------------------ Lottie
W, H, FR, OP = 390, 844, 30, 120


def k(v):
    return {'a': 0, 'k': v}


def anim(*frames, ease=(0.25, 0, 0.35, 1)):
    out = []
    for i, (t, v) in enumerate(frames):
        kf = {'t': t, 's': v if isinstance(v, list) else [v]}
        if i < len(frames) - 1:
            n = len(kf['s'])
            kf['o'] = {'x': [ease[0]] * n, 'y': [ease[1]] * n}
            kf['i'] = {'x': [ease[2]] * n, 'y': [ease[3]] * n}
        out.append(kf)
    return {'a': 1, 'k': out}


def tr(**kw):
    base = {'ty': 'tr', 'p': k([0, 0]), 'a': k([0, 0]), 's': k([100, 100]), 'r': k(0),
            'o': k(100), 'sk': k(0), 'sa': k(0)}
    base.update(kw)
    return base


def sh(v, closed, i=None, o=None):
    n = len(v)
    return {'ty': 'sh', 'ks': k({'i': i or [[0, 0]] * n, 'o': o or [[0, 0]] * n,
                                 'v': [list(p) for p in v], 'c': closed})}


def st(c, w):
    return {'ty': 'st', 'c': k(rgb(c)), 'o': k(100), 'w': k(w), 'lc': 2, 'lj': 2, 'ml': 4}


def fl(c, o=100):
    return {'ty': 'fl', 'c': k(rgb(c)), 'o': k(o), 'r': 1}


def tm(a, b):
    return {'ty': 'tm', 's': k(0), 'e': anim((a, 0), (b, 100)), 'o': k(0), 'm': 1}


CENTER = (141, 160)
POS = (W / 2, H / 2 - 40)
SC = 190 / 177 * 100
BREATH = anim((60, [SC, SC]), (90, [SC * 1.035, SC * 1.035]), (120, [SC, SC]),
              ease=(0.45, 0, 0.55, 1))


def ks(o=None, a=None):
    return {'o': o or k(100), 'r': k(0), 'p': k([*POS, 0]), 'a': a or k([*CENTER, 0]), 's': BREATH}


def layer(ind, name, shapes, kss):
    return {'ddd': 0, 'ind': ind, 'ty': 4, 'nm': name, 'sr': 1, 'ks': kss, 'ao': 0,
            'shapes': shapes, 'ip': 0, 'op': OP, 'st': 0, 'bm': 0}


def rel(p, q):
    return [p[0] - q[0], p[1] - q[1]]


# Halo menthe derrière le logo.
glow = {'ddd': 0, 'ind': 30, 'ty': 4, 'nm': 'halo', 'sr': 1, 'ao': 0, 'ip': 0, 'op': OP, 'st': 0, 'bm': 0,
        'ks': {'o': anim((0, 0), (30, 100)), 'r': k(0), 'p': k([W / 2, H / 2 - 70, 0]), 'a': k([0, 0, 0]),
               's': anim((0, [60, 60, 100]), (30, [100, 100, 100]), (90, [108, 108, 100]), (120, [100, 100, 100]))},
        'shapes': [{'ty': 'gr', 'it': [
            {'ty': 'el', 'p': k([0, 0]), 's': k([330, 330])},
            {'ty': 'gf', 'o': k(100), 'r': 1, 't': 2, 's': k([0, 0]), 'e': k([165, 0]),
             'g': {'p': 2, 'k': k([0, *rgb(MINT)[:3], 1, *rgb(BG)[:3], 0, 1, 1, 0])}},
            tr()]}]}

bag = layer(10, 'sac', [{'ty': 'gr', 'it': [
    sh(BODY, True), sh(FOLD, False), sh(SPINE, False), st(BRAND, 6.5), tm(0, 26), tr()]}], ks())

handle_v = [H0, H1, H4, H5]
handle_i = [[0, 0], [0, 0], rel(TR, H4), [0, 0]]
handle_o = [[0, 0], rel(TL, H1), [0, 0], [0, 0]]
dots = [{'ty': 'gr', 'it': [{'ty': 'el', 'p': k([0, 0]), 's': k([8.4, 8.4])}, fl(DEEP),
                            tr(p=k(list(c)), s=anim((24, [0, 0]), (34, [115, 115]), (38, [100, 100])))]}
        for c in (H0, H5)]
handle = layer(9, 'anse', [{'ty': 'gr', 'it': [sh(handle_v, False, handle_i, handle_o), st(DEEP, 6.5),
                                               tm(16, 34), tr()]}, *dots], ks())

leaf_groups = []
for n, (b, t, c1, c2) in enumerate(LEAVES):
    # Q → C : c = point + 2/3 (contrôle − point)
    o0 = [2 / 3 * (c1[0] - b[0]), 2 / 3 * (c1[1] - b[1])]
    i1 = [2 / 3 * (c1[0] - t[0]), 2 / 3 * (c1[1] - t[1])]
    o1 = [2 / 3 * (c2[0] - t[0]), 2 / 3 * (c2[1] - t[1])]
    i0 = [2 / 3 * (c2[0] - b[0]), 2 / 3 * (c2[1] - b[1])]
    t0 = 34 + n * 5
    leaf_groups.append({'ty': 'gr', 'it': [
        sh([b, t], True, [i0, i1], [o0, o1]), fl(LEAF),
        tr(p=k(list(b)), a=k(list(b)),
           s=anim((t0, [0, 0]), (t0 + 9, [118, 118]), (t0 + 14, [100, 100])),
           r=anim((t0, -25 if n else 25), (t0 + 14, 0)))]})
leaves = layer(11, 'feuilles', leaf_groups, ks())


class LPen(BasePen):
    def __init__(self, glyphset):
        super().__init__(glyphset)
        self.contours, self.cur = [], None

    def _moveTo(self, p):
        self.cur = {'v': [list(p)], 'i': [[0, 0]], 'o': [[0, 0]]}

    def _lineTo(self, p):
        self.cur['v'].append(list(p))
        self.cur['i'].append([0, 0])
        self.cur['o'].append([0, 0])

    def _curveToOne(self, c1, c2, p):
        a = self.cur['v'][-1]
        self.cur['o'][-1] = rel(c1, a)
        self.cur['v'].append(list(p))
        self.cur['i'].append(rel(c2, p))
        self.cur['o'].append([0, 0])

    def _qCurveToOne(self, q, p):
        a = self.cur['v'][-1]
        c1 = (a[0] + 2 / 3 * (q[0] - a[0]), a[1] + 2 / 3 * (q[1] - a[1]))
        c2 = (p[0] + 2 / 3 * (q[0] - p[0]), p[1] + 2 / 3 * (q[1] - p[1]))
        self._curveToOne(c1, c2, p)

    def _closePath(self):
        c = self.cur
        if len(c['v']) > 1 and max(abs(c['v'][-1][j] - c['v'][0][j]) for j in (0, 1)) < 1e-6:
            c['i'][0] = c['i'][-1]
            for key in ('v', 'i', 'o'):
                c[key].pop()
        self.contours.append(c)
        self.cur = None

    _endPath = _closePath


def glyph_shapes(text, x, color):
    pen = LPen(gs)
    sc = SIZE / upm
    for ch in text:
        gs[cmap[ord(ch)]].draw(TransformPen(pen, (sc, 0, 0, -sc, x, BASELINE)))
        x += adv(ch, SIZE)
    return {'ty': 'gr', 'it': [
        *[{'ty': 'sh', 'ks': k({'i': c['i'], 'o': c['o'], 'v': c['v'], 'c': True})} for c in pen.contours],
        fl(color), tr()]}


name = layer(8, 'nom', [glyph_shapes('Do', X0, DEEP), glyph_shapes('YourMarket', X0 + w_do, BRAND)],
             ks(o=anim((40, 0), (56, 100)), a=anim((40, [CENTER[0], CENTER[1] - 16, 0]),
                                                  (58, [CENTER[0], CENTER[1], 0]))))


def asset(idx, nm, height):
    im = Image.open(os.path.join(OLD, f'base_{nm}.png')).convert('RGBA')
    w = round(im.width * height / im.height)
    im = im.resize((w, height), Image.LANCZOS)
    path = os.path.join(HERE, f'veg_{nm}.webp')
    im.save(path, 'WEBP', quality=82, method=6)
    data = base64.b64encode(open(path, 'rb').read()).decode()
    return {'id': f'img_{idx}', 'w': w, 'h': height, 'u': '', 'p': f'data:image/webp;base64,{data}', 'e': 1}, w


specs = [('verde', 320, None, -90, (120, -120), 8), ('cebolla', 300, -175, 40, (-140, -60), 14),
         ('brocoli', 310, -150, H - 310 + 85, (-140, 140), 20), ('rabanos', 210, None, H - 210 + 45, (140, 120), 26)]
assets, vegs = [], []
for idx, (nm, h, x, y, (dx, dy), t0) in enumerate(specs):
    a, w = asset(idx, nm, h)
    if x is None:
        x = W + (170 if nm == 'verde' else 60) - w
    assets.append(a)
    fy = 6 if idx % 2 == 0 else -6
    vegs.append({'ddd': 0, 'ind': 20 + idx, 'ty': 2, 'nm': nm, 'refId': a['id'], 'sr': 1, 'ao': 0,
                 'ks': {'o': anim((t0, 0), (t0 + 14, 100)), 'r': anim((t0, -8 if dx < 0 else 8), (t0 + 20, 0)),
                        'p': anim((t0, [x + dx, y + dy, 0]), (t0 + 20, [x, y, 0]), (90, [x, y + fy, 0]),
                                  (120, [x, y, 0])),
                        'a': k([0, 0, 0]), 's': k([100, 100, 100])},
                 'ip': 0, 'op': OP, 'st': 0, 'bm': 0})

doc = {'v': '5.7.4', 'fr': FR, 'ip': 0, 'op': OP, 'w': W, 'h': H, 'nm': 'DYM splash', 'ddd': 0,
       'assets': assets, 'markers': [{'tm': 60, 'cm': 'boucle', 'dr': 60}],
       'layers': [leaves, handle, bag, name, *vegs, glow]}
json.dump(doc, open(os.path.join(HERE, 'splash-dym.json'), 'w', encoding='utf-8'), separators=(',', ':'))
print('ok', os.path.getsize(os.path.join(HERE, 'splash-dym.json')) // 1024, 'Ko')
