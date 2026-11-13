"""Animations d'accueil (Lottie, 360 × 300, 30 i/s, boucle 90 images = 3 s).

1. onb-marche : les légumes du quartier sautent dans le sac DYM.
2. onb-panier : trois boutiques, un seul panier (compteur 1 → 3).
3. onb-livraison : paiement validé puis la moto suit la route jusqu'à la maison.
4. onb-vendeuse : l'étal reçoit des commandes (cartes qui arrivent, cloche).
5. onb-livreur : la moto roule, les repères défilent.
"""
import json
import math
import os

from lkit import (C, anim, bag_shapes, doc, ellipse, fill, group, image, image_layer, k, layer,
                  path, pop, rect, stroke, tr, trim)

HERE = os.path.dirname(os.path.abspath(__file__))
W, H, OP = 360, 300, 90


def halo(ind, x=180, y=150, size=250, color='mint'):
    return layer(ind, 'halo', [group(ellipse(size, size), fill(C[color]))], (x, y),
                 s=anim((0, [96, 96, 100]), (45, [104, 104, 100]), (90, [96, 96, 100]),
                        ease=(0.45, 0, 0.55, 1)))


def ground(ind, y=258, w=300):
    return layer(ind, 'sol', [group(ellipse(w, 18), fill(C['line'], 60))], (180, y))


def bounce_path(x0, y0, x1, y1, t0, dur=16, height=70):
    """Saut en arc de (x0, y0) à (x1, y1)."""
    frames = []
    for n in range(0, dur + 1, 4):
        u = n / dur
        frames.append((t0 + n, [x0 + (x1 - x0) * u, y0 + (y1 - y0) * u - math.sin(math.pi * u) * height, 0]))
    return {'a': 1, 'k': [
        {'t': t, 's': v, **({'o': {'x': [0.4], 'y': [0]}, 'i': {'x': [0.6], 'y': [1]}} if j < len(frames) - 1 else {})}
        for j, (t, v) in enumerate(frames)]}


def save(name, d):
    p = os.path.join(HERE, f'{name}.json')
    json.dump(d, open(p, 'w', encoding='utf-8'), separators=(',', ':'))
    print(name, os.path.getsize(p) // 1024, 'Ko')


# ---------------------------------------------------------------- 1. marché
def scene_market():
    assets, layers = [], []
    veg = [('brocoli', 104, -70, -34), ('cebolla', 92, 70, 30), ('rabanos', 112, -105, -8), ('verde', 86, 110, 12)]
    for n, (nm, h, x0, x1) in enumerate(veg):
        aid, w = image(assets, nm, h)
        t0 = 6 + n * 10
        # Le légume arrive du bord, saute dans le sac et y reste, la tête dépassant.
        layers.append(image_layer(
            30 + n, aid, w, h,
            p=bounce_path(180 + x0 * 1.5, 60, 180 + x1, 150 - n * 2, t0, 18, 70),
            s=anim((t0, [100, 100, 100]), (t0 + 18, [62, 62, 100])),
            o=anim((t0 - 4, 0), (t0, 100)),
            r=anim((t0, -25 if x0 < 0 else 25), (t0 + 18, -8 if x1 < 0 else 8))))
    # Sac (au-dessus des légumes qui « entrent ») et rebond à chaque arrivée.
    sc = []
    for n in range(4):
        t = 6 + n * 10 + 18
        sc += [(t, [100, 100, 100]), (t + 3, [106, 94, 100]), (t + 7, [100, 100, 100])]
    layers.insert(0, layer(10, 'sac', bag_shapes(C['brand'], C['deep'], 6, 0.82), (180, 172),
                           s=anim((0, [100, 100, 100]), *sc)))
    # Petits repères « quartier » autour.
    for n, (x, y, t0) in enumerate([(70, 70, 4), (292, 92, 12), (300, 220, 20)]):
        layers.append(layer(40 + n, 'repère', [
            group(path([[0, 0], [-9, -14], [0, -24], [9, -14]], True,
                       [[0, 0], [0, 6], [-6, 0], [0, -6]], [[0, 0], [0, -6], [6, 0], [0, 6]]),
                  fill(C['leaf'])),
            group(ellipse(7, 7), fill('#FFFFFF'), t=tr(p=k([0, -14])))], (x, y), s=pop(t0)))
    layers += [ground(60, 262, 220), halo(61)]
    return doc('onb-marche', W, H, OP, layers, assets)


# ---------------------------------------------------------------- 2. panier
def store(ind, x, color, icon_color, t0):
    """Petite boutique : toit rayé, façade."""
    # Toit rayé à festons : bandes alternées + demi-cercles sous chaque bande.
    awning = []
    for j in range(4):
        c = color if j % 2 == 0 else '#FFFFFF'
        awning.append(group(rect(20, 16, 0), fill(c), t=tr(p=k([-30 + j * 20, 0]))))
        awning.append(group(ellipse(20, 14), fill(c), t=tr(p=k([-30 + j * 20, 8]))))
    awning.append(group(rect(84, 16, 4), stroke(color, 2.5), t=tr(p=k([0, 0]))))
    return layer(ind, 'boutique', [
        group(rect(72, 46, 6), fill('#FFFFFF'), stroke(C['line'], 2), t=tr(p=k([0, 6]))),
        group(rect(22, 26, 3), fill(icon_color), t=tr(p=k([0, 16]))),
        group(*awning, t=tr(p=k([0, -28]))),
    ], (x, 92), s=pop(t0))


def scene_cart():
    assets, layers = [], []
    stores = [(70, C['piment'], C['peche'], 0), (180, C['brand'], C['mint'], 6), (290, C['plantain'], '#FBF1D3', 12)]
    for n, (x, col, ic, t0) in enumerate(stores):
        layers.append(store(10 + n, x, col, ic, t0))
    veg = ['cebolla', 'brocoli', 'rabanos']
    for n, nm in enumerate(veg):
        aid, w = image(assets, nm, 72)
        t0 = 24 + n * 12
        x0 = stores[n][0]
        layers.append(image_layer(
            20 + n, aid, w, 46, p=bounce_path(x0, 92, 180, 222, t0, 16, 50),
            o=anim((t0 - 2, 0), (t0, 100), (t0 + 14, 100), (t0 + 17, 0)),
            s=anim((t0, [100, 100, 100]), (t0 + 16, [60, 60, 100]))))
    # Panier : corps arrondi + anse, rebond à chaque produit.
    basket = [
        group(path([[-30, -12], [-60, -32]]), stroke(C['deep'], 5)),
        group(rect(96, 46, 12), fill(C['brand']), t=tr(p=k([0, 6]))),
        group(rect(96, 8, 4), fill(C['deep']), t=tr(p=k([0, -16]))),
        *[group(rect(4, 24, 2), fill('#FFFFFF', 55), t=tr(p=k([-30 + j * 20, 8]))) for j in range(4)],
    ]
    sc = []
    for n in range(3):
        t = 24 + n * 12 + 16
        sc += [(t, [100, 100, 100]), (t + 3, [107, 93, 100]), (t + 7, [100, 100, 100])]
    layers.append(layer(30, 'panier', basket, (180, 226), s=anim((0, [100, 100, 100]), *sc)))
    # Pastille compteur 1 → 3 (trois pastilles superposées qui se succèdent).
    for n in range(3):
        t = 24 + n * 12 + 16
        digit = {
            0: [group(path([[0, -7], [0, 7]]), stroke('#FFFFFF', 3))],
            1: [group(path([[-4, -5], [4, -5], [4, 0], [-4, 0], [-4, 6], [4, 6]]), stroke('#FFFFFF', 2.6))],
            2: [group(path([[-4, -6], [4, -6], [4, 6], [-4, 6]]), path([[-2, 0], [4, 0]]), stroke('#FFFFFF', 2.6))],
        }[n]
        layers.append(layer(40 + n, f'compteur {n + 1}', [group(ellipse(24, 24), fill(C['piment'])), *digit],
                            (222, 196), s=pop(t), o=anim((t, 100), (t + 11, 100), (t + 12, 0 if n < 2 else 100))))
    layers += [ground(60, 258, 200), halo(61, 180, 160, 260)]
    return doc('onb-panier', W, H, OP, layers, assets)


# ---------------------------------------------------------------- 3. livraison
def scooter(color=C['brand']):
    return [
        group(ellipse(22, 22), stroke(C['deep'], 5), t=tr(p=k([-22, 14]))),
        group(ellipse(22, 22), stroke(C['deep'], 5), t=tr(p=k([24, 14]))),
        group(path([[-22, 14], [-8, -6], [16, -6], [24, 14]]), stroke(color, 6)),
        group(rect(22, 20, 4), fill(C['plantain']), t=tr(p=k([-14, -18]))),
        group(path([[16, -6], [20, -22], [28, -22]]), stroke(C['deep'], 4)),
        group(ellipse(14, 14), fill(C['deep']), t=tr(p=k([6, -30]))),
    ]


def house():
    return [
        group(path([[-26, -4], [0, -26], [26, -4]], True), fill(C['piment'])),
        group(rect(40, 30, 3), fill('#FFFFFF'), stroke(C['line'], 2), t=tr(p=k([0, 10]))),
        group(rect(12, 16, 2), fill(C['brand']), t=tr(p=k([0, 17]))),
    ]


def scene_delivery():
    layers = []
    route = [[50, 210], [120, 150], [220, 200], [300, 130]]
    ri = [[0, 0], [-30, 10], [-30, -10], [-20, 20]]
    ro = [[30, -20], [30, -10], [30, 10], [0, 0]]
    layers.append(layer(5, 'route', [group(path(route, False, ri, ro),
                                           stroke(C['line'], 4, (k(2), k(10)))),
                                     group(path(route, False, ri, ro), stroke(C['brand'], 4), trim(20, 70))],
                        (0, 0)))
    # Téléphone : paiement validé (coche) avant le départ.
    phone = [
        group(rect(46, 78, 10), fill('#FFFFFF'), stroke(C['deep'], 3)),
        group(ellipse(26, 26), fill(C['leaf']), t=tr(p=k([0, -4]), s=pop(6, 100, 120))),
        group(path([[-6, -4], [-1, 2], [8, -9]]), stroke('#FFFFFF', 3.5), trim(12, 20), t=tr(p=k([0, -4]))),
    ]
    layers.append(layer(10, 'téléphone', phone, (50, 160), s=pop(0)))
    layers.append(layer(11, 'maison', house(), (306, 118), s=pop(8)))
    # La moto suit la route (positions échantillonnées sur la courbe).
    pts = []
    for n in range(0, 51, 5):
        u = n / 50
        # Bézier cubique par morceaux, approximée par les sommets.
        seg = min(int(u * 3), 2)
        lu = u * 3 - seg
        p0, p3 = route[seg], route[seg + 1]
        p1 = [p0[0] + ro[seg][0], p0[1] + ro[seg][1]]
        p2 = [p3[0] + ri[seg + 1][0], p3[1] + ri[seg + 1][1]]
        x = (1 - lu) ** 3 * p0[0] + 3 * (1 - lu) ** 2 * lu * p1[0] + 3 * (1 - lu) * lu ** 2 * p2[0] + lu ** 3 * p3[0]
        y = (1 - lu) ** 3 * p0[1] + 3 * (1 - lu) ** 2 * lu * p1[1] + 3 * (1 - lu) * lu ** 2 * p2[1] + lu ** 3 * p3[1]
        pts.append((20 + n, [x, y - 26, 0]))
    layers.append(layer(20, 'moto', scooter(), anim(*pts, ease=(0.5, 0, 0.5, 1)), s=k([88, 88, 100]),
                        o=anim((18, 0), (21, 100), (72, 100), (76, 0))))
    # Arrivée : la maison sautille, un cœur plantain s'envole.
    layers.append(layer(21, 'arrivée', [group(ellipse(16, 16), fill(C['plantain']))], (306, 80),
                        s=pop(70), o=anim((70, 100), (86, 0))))
    layers += [halo(61, 180, 160, 270)]
    return doc('onb-livraison', W, H, OP, layers, [])


# ---------------------------------------------------------------- 4. vendeuse
def scene_vendor():
    assets, layers = [], []
    # Étal : planche + toit rayé.
    awning = []
    for j in range(6):
        c = C['brand'] if j % 2 == 0 else '#FFFFFF'
        awning.append(group(rect(36, 22, 0), fill(c), t=tr(p=k([-90 + j * 36, 0]))))
        awning.append(group(ellipse(36, 20), fill(c), t=tr(p=k([-90 + j * 36, 11]))))
    awning.append(group(rect(220, 22, 4), stroke(C['brand'], 3)))
    stall = [group(*awning, t=tr(p=k([0, -60]))),
             group(rect(220, 16, 4), fill(C['deep']), t=tr(p=k([0, 40]))),
             group(rect(10, 70, 2), fill(C['deep']), t=tr(p=k([-100, 0]))),
             group(rect(10, 70, 2), fill(C['deep']), t=tr(p=k([100, 0])))]
    layers.append(layer(10, 'étal', stall, (140, 200), s=pop(0, 100, 106)))
    for n, nm in enumerate(['rabanos', 'brocoli', 'cebolla']):
        aid, w = image(assets, nm, 70)
        layers.append(image_layer(15 + n, aid, w, 52, (80 + n * 60, 208), s=pop(6 + n * 4)))
    # Commandes qui arrivent (cartes) et cloche.
    for n in range(3):
        t0 = 24 + n * 14
        card = [group(rect(92, 34, 8), fill('#FFFFFF'), stroke(C['line'], 2)),
                group(ellipse(14, 14), fill(C['leaf']), t=tr(p=k([-32, 0]))),
                group(rect(46, 6, 3), fill(C['text2'], 70), t=tr(p=k([8, -5]))),
                group(rect(30, 6, 3), fill(C['plantain']), t=tr(p=k([0, 6])))]
        layers.append(layer(30 + n, 'commande', card,
                            anim((t0, [400, 64 + n * 42, 0]), (t0 + 12, [296, 64 + n * 42, 0])),
                            o=anim((t0, 0), (t0 + 6, 100))))
    bell = [group(path([[-12, 8], [-10, -6], [0, -14], [10, -6], [12, 8]], True), fill(C['plantain'])),
            group(ellipse(7, 7), fill(C['deep']), t=tr(p=k([0, 12])))]
    layers.append(layer(40, 'cloche', bell, (40, 60),
                        r=anim((24, 0), (28, -18), (32, 16), (36, -10), (40, 0)), s=pop(20)))
    layers += [halo(61, 180, 150, 270)]
    return doc('onb-vendeuse', W, H, OP, layers, assets)


# ---------------------------------------------------------------- 5. livreur
def scene_courier():
    layers = []
    # Bandes de route qui défilent (boucle parfaite sur 90 images).
    for n in range(5):
        layers.append(layer(5 + n, 'bande', [group(rect(36, 6, 3), fill(C['line']))],
                            anim((0, [380 - n * 90, 236, 0]), (90, [-70 - n * 90 + 450 - 450, 236, 0]),
                                 ease=(0, 0, 1, 1))))
    layers.append(layer(4, 'route', [group(rect(420, 4, 2), fill(C['line']))], (180, 254)))
    # Moto : léger tangage.
    layers.append(layer(20, 'moto', scooter(), (170, 192), s=k([150, 150, 100]),
                        r=anim((0, 0), (22, -2), (45, 0), (68, 2), (90, 0), ease=(0.45, 0, 0.55, 1))))
    # Repères (épingles) qui passent en haut.
    for n in range(3):
        t0 = n * 30
        pin = [group(path([[0, 0], [-10, -16], [0, -28], [10, -16]], True,
                          [[0, 0], [0, 7], [-7, 0], [0, -7]], [[0, 0], [0, -7], [7, 0], [0, 7]]),
                     fill(C['leaf'] if n != 1 else C['piment'])),
               group(ellipse(8, 8), fill('#FFFFFF'), t=tr(p=k([0, -16])))]
        layers.append(layer(30 + n, 'repère', pin,
                            anim((t0, [400, 110, 0]), (t0 + 60, [-40, 110, 0]), ease=(0, 0, 1, 1)),
                            o=anim((t0, 0), (t0 + 6, 100), (t0 + 54, 100), (t0 + 60, 0))))
    layers += [halo(61, 180, 160, 270)]
    return doc('onb-livreur', W, H, OP, layers, [])


for nm, fn in [('onb-marche', scene_market), ('onb-panier', scene_cart), ('onb-livraison', scene_delivery),
               ('onb-vendeuse', scene_vendor), ('onb-livreur', scene_courier)]:
    save(nm, fn())
