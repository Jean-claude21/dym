"""Petite boîte à outils Lottie (formes, images, images clés)."""
import base64
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OLD = os.path.join(HERE, 'anciens')

C = {
    'brand': '#145C43', 'deep': '#0E4632', 'leaf': '#3FA06B', 'plantain': '#F6C343',
    'piment': '#D93F33', 'bg': '#FAFAF7', 'mint': '#E8F2EC', 'card': '#FFFFFF',
    'line': '#DCE3DE', 'peche': '#F8E3D3', 'text2': '#4E5852', 'sky': '#E3E6F4',
}


def rgb(h, a=1):
    return [int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)] + [a]


def k(v):
    return {'a': 0, 'k': v}


def anim(*frames, ease=(0.3, 0, 0.3, 1)):
    out = []
    for i, (t, v) in enumerate(frames):
        kf = {'t': t, 's': v if isinstance(v, list) else [v]}
        if i < len(frames) - 1:
            n = len(kf['s'])
            kf['o'] = {'x': [ease[0]] * n, 'y': [ease[1]] * n}
            kf['i'] = {'x': [ease[2]] * n, 'y': [ease[3]] * n}
        out.append(kf)
    return {'a': 1, 'k': out}


def tr(p=None, a=None, s=None, r=None, o=None):
    return {'ty': 'tr', 'p': p or k([0, 0]), 'a': a or k([0, 0]), 's': s or k([100, 100]),
            'r': r or k(0), 'o': o or k(100), 'sk': k(0), 'sa': k(0)}


def rect(w, h, r=0, c=None):
    return {'ty': 'rc', 'p': k([0, 0]), 's': k([w, h]), 'r': k(r)}


def ellipse(w, h):
    return {'ty': 'el', 'p': k([0, 0]), 's': k([w, h])}


def path(v, closed=False, i=None, o=None):
    n = len(v)
    return {'ty': 'sh', 'ks': k({'i': i or [[0, 0]] * n, 'o': o or [[0, 0]] * n,
                                 'v': [list(p) for p in v], 'c': closed})}


def fill(c, o=100):
    return {'ty': 'fl', 'c': k(rgb(c)), 'o': k(o), 'r': 1}


def stroke(c, w, dash=None):
    s = {'ty': 'st', 'c': k(rgb(c)), 'o': k(100), 'w': k(w), 'lc': 2, 'lj': 2, 'ml': 4}
    if dash:
        s['d'] = [{'n': 'd', 'nm': 'dash', 'v': k(dash[0])}, {'n': 'g', 'nm': 'gap', 'v': k(dash[1])},
                  {'n': 'o', 'nm': 'offset', 'v': dash[2] if len(dash) > 2 else k(0)}]
    return s


def trim(a, b, start=None):
    return {'ty': 'tm', 's': start or k(0), 'e': anim((a, 0), (b, 100)), 'o': k(0), 'm': 1}


def group(*items, t=None):
    return {'ty': 'gr', 'it': [*items, t or tr()]}


def layer(ind, name, shapes, p, a=(0, 0), s=None, o=None, r=None, op=90):
    return {'ddd': 0, 'ind': ind, 'ty': 4, 'nm': name, 'sr': 1, 'ao': 0, 'ip': 0, 'op': op, 'st': 0,
            # Lottie peint le premier élément au-dessus : on écrit de l'arrière
            # vers l'avant, on inverse ici.
            'bm': 0, 'shapes': list(reversed(shapes)),
            'ks': {'o': o or k(100), 'r': r or k(0), 'p': p if isinstance(p, dict) else k([*p, 0]),
                   'a': k([*a, 0]), 's': s or k([100, 100, 100])}}


_cache = {}


def image(assets, name, height):
    """Image d'un légume (WebP intégré) ; renvoie (identifiant, largeur)."""
    key = (name, height)
    if key in _cache:
        return _cache[key]
    im = Image.open(os.path.join(OLD, f'base_{name}.png')).convert('RGBA')
    w = round(im.width * height / im.height)
    im = im.resize((w, height), Image.LANCZOS)
    p = os.path.join(HERE, f'v_{name}_{height}.webp')
    im.save(p, 'WEBP', quality=80, method=6)
    data = base64.b64encode(open(p, 'rb').read()).decode()
    aid = f'img_{len(assets)}'
    assets.append({'id': aid, 'w': w, 'h': height, 'u': '', 'p': f'data:image/webp;base64,{data}', 'e': 1})
    _cache[key] = (aid, w)
    return aid, w


def image_layer(ind, aid, w, h, p, s=None, o=None, r=None, op=90):
    return {'ddd': 0, 'ind': ind, 'ty': 2, 'nm': aid, 'refId': aid, 'sr': 1, 'ao': 0, 'ip': 0, 'op': op,
            'st': 0, 'bm': 0,
            'ks': {'o': o or k(100), 'r': r or k(0), 'p': p if isinstance(p, dict) else k([*p, 0]),
                   'a': k([w / 2, h / 2, 0]), 's': s or k([100, 100, 100])}}


def doc(name, w, h, op, layers, assets):
    return {'v': '5.7.4', 'fr': 30, 'ip': 0, 'op': op, 'w': w, 'h': h, 'nm': name, 'ddd': 0,
            'assets': assets, 'layers': layers}


def pop(t0, size=100, over=112):
    """Apparition « pop » : 0 → dépasse → taille."""
    return anim((t0, [0, 0, 100]), (t0 + 8, [over * size / 100, over * size / 100, 100]),
                (t0 + 13, [size, size, 100]))


def bag_shapes(color, handle, sw=6, scale=1.0):
    """Sac DYM centré sur (0, 0), largeur ~ 177 × scale."""
    def P(x, y):
        return [(-30 + x * 2 - 141.5) * scale, (6 + y * 2 - 107) * scale]
    body = [P(59.5, 22), P(112, 22), P(130, 101), P(41.5, 101)]
    fold = [P(59.5, 22), P(86, 52.5), P(112, 22)]
    spine = [P(86, 52.5), P(86, 101)]
    h0, h1, tl, trr, h4, h5 = P(73, 29.5), P(73, 15), P(73, 0), P(99, 0), P(99, 15), P(99, 29.5)
    hi = [[0, 0], [0, 0], [trr[0] - h4[0], trr[1] - h4[1]], [0, 0]]
    ho = [[0, 0], [tl[0] - h1[0], tl[1] - h1[1]], [0, 0], [0, 0]]
    return [
        group(path(body, True), fill('#FFFFFF'), ),
        group(path(body, True), path(fold), path(spine), stroke(color, sw * scale)),
        group(path([h0, h1, h4, h5], False, hi, ho), stroke(handle, sw * scale)),
    ]
