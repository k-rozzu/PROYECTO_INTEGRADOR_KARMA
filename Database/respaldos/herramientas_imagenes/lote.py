"""Convierte las fotos nuevas del Catálogo (PNG) a WebP: fondo transparente, encuadre uniforme y centrado,
miniaturas para menús. Escribe en una carpeta de salida (no toca el proyecto)."""
import sys, os, glob, time
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from recortar import recortar

ORIGEN = 'C:/xampp/htdocs/PROYECTO_INTEGRADOR_KARMA/assets/Catalogo'
SALIDA = sys.argv[1]
SOLO = sys.argv[2].split(',') if len(sys.argv) > 2 and sys.argv[2] else None


def encuadrar(rgba, frente, lienzo, caja, centro_y=0.5):
    """Recorta al objeto, lo escala para caber en `caja` (fracción del lienzo) y lo centra en un lienzo transparente."""
    W, H = lienzo
    ys, xs = np.nonzero(frente)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    # Incluye la sombra que queda pegada debajo del objeto (hasta 8 % de su altura)
    extra = int((y1 - y0) * 0.08)
    recorte = rgba.crop((x0, y0, x1, min(rgba.height, y1 + extra)))
    ow, oh = x1 - x0, y1 - y0
    s = min(caja[0] * W / ow, caja[1] * H / oh)
    nw, nh = max(1, round(recorte.width * s)), max(1, round(recorte.height * s))
    escalado = recorte.convert('RGBa').resize((nw, nh), Image.LANCZOS).convert('RGBA')
    final = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = round((W - ow * s) / 2)
    py = round(H * centro_y - oh * s / 2)
    final.alpha_composite(escalado, (px, max(0, py)))
    return final


def guardar(img, ruta, calidad=82):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    img.save(ruta, 'WEBP', quality=calidad, method=6)


trabajos = []
for marca in ('audi', 'porsche', 'ducati'):
    for f in sorted(glob.glob(f'{ORIGEN}/vehiculos/{marca}/*.png')):
        trabajos.append(('vehiculo', marca, f))
for f in sorted(glob.glob(f'{ORIGEN}/accesorios/*.png')):
    trabajos.append(('accesorio', None, f))
for f in sorted(glob.glob(f'{ORIGEN}/sucursales/*.png')):
    trabajos.append(('sucursal', None, f))

for tipo, marca, f in trabajos:
    nombre = os.path.splitext(os.path.basename(f))[0]
    if SOLO and nombre not in SOLO:
        continue
    t = time.time()
    if tipo == 'vehiculo':
        moto = marca == 'ducati'
        rgba, frente = recortar(f, abrir_huecos=moto, banda_piso=0.13 if moto else 0.10)
        caja = (0.80, 0.84) if moto else (0.88, 0.74)
        grande = encuadrar(rgba, frente, (1280, 800), caja, centro_y=0.5)
        guardar(grande, f'{SALIDA}/vehiculos/{marca}/{nombre}.webp')
        mini = grande.convert('RGBa').resize((480, 300), Image.LANCZOS).convert('RGBA')
        guardar(mini, f'{SALIDA}/vehiculos/{marca}/miniaturas/{nombre}.webp', 80)
        destino = f'vehiculos/{marca}/{nombre}.webp'
    elif tipo == 'accesorio':
        rgba, frente = recortar(f, abrir_huecos=True, banda_piso=0.04 if nombre.startswith('parabrisas') else 0.12,
                                 grad_piso=40.0 if nombre.startswith('parabrisas') else 999.0,
                                 abrir_claros=not nombre.startswith('parabrisas'))
        grande = encuadrar(rgba, frente, (1200, 900), (0.84, 0.80), centro_y=0.5)
        guardar(grande, f'{SALIDA}/accesorios/{nombre}.webp')
        destino = f'accesorios/{nombre}.webp'
    else:
        im = Image.open(f).convert('RGB')
        im.thumbnail((1500, 1000), Image.LANCZOS)
        guardar(im, f'{SALIDA}/sucursales/{nombre}.webp', 80)
        destino = f'sucursales/{nombre}.webp'
    print(f'{destino:50s} {os.path.getsize(SALIDA + "/" + destino) // 1024:4d} KB  {time.time() - t:.1f}s', flush=True)
