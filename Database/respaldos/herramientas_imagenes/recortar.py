"""Quita el fondo de estudio (liso o en degradado) de una foto de producto usando solo numpy + PIL."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def ajustar_fondo(img, mascara_fondo, grado=3):
    """Ajusta un polinomio 2D por canal a los píxeles marcados como fondo (modela el degradado del estudio)."""
    h, w, _ = img.shape
    ys, xs = np.nonzero(mascara_fondo)
    sel = np.random.default_rng(0).choice(len(xs), size=min(len(xs), 40000), replace=False)
    ys, xs = ys[sel], xs[sel]

    def terminos(x, y):
        return np.stack([x ** i * y ** j for i in range(grado + 1) for j in range(grado + 1 - i)], axis=-1)

    A = terminos(xs / w, ys / h)
    yy, xx = np.mgrid[0:h, 0:w]
    T = terminos(xx / w, yy / h)
    fondo = np.empty_like(img)
    for c in range(3):
        coef, *_ = np.linalg.lstsq(A, img[ys, xs, c], rcond=None)
        fondo[..., c] = T @ coef
    return fondo


def rellenar_huecos(m):
    """Rellena los huecos internos: es frente todo lo que no se alcanza desde el borde por el fondo."""
    lienzo = Image.fromarray(np.pad(~m, 1, constant_values=True).astype(np.uint8) * 255).copy()
    ImageDraw.floodfill(lienzo, (0, 0), 128)
    return np.array(lienzo)[1:-1, 1:-1] != 128


def regiones_grandes(m, proporcion=0.04):
    """Etiqueta en baja resolución y conserva las regiones de al menos `proporcion` del área de la mayor."""
    h, w = m.shape
    chico = Image.fromarray(m.astype(np.uint8) * 255).resize((w // 4, h // 4), Image.BOX)
    arr = (np.array(chico) > 64).astype(np.uint8) * 255
    trabajo = Image.fromarray(arr).copy()
    etiquetas = []
    ch, cw = arr.shape
    valor = 1
    for y in range(0, ch, 2):
        for x in range(0, cw, 2):
            if trabajo.getpixel((x, y)) != 255:
                continue
            ImageDraw.floodfill(trabajo, (x, y), valor)
            etiquetas.append(valor)
            valor += 1
            if valor >= 250:
                break
        if valor >= 250:
            break
    final = np.array(trabajo)
    if not etiquetas:
        return m
    areas = {v: int((final == v).sum()) for v in etiquetas}
    mayor = max(areas.values())
    keep = np.isin(final, [v for v, a in areas.items() if a >= mayor * proporcion])
    keep_img = Image.fromarray(keep.astype(np.uint8) * 255).resize((w, h), Image.NEAREST).filter(ImageFilter.MaxFilter(9))
    return m & (np.array(keep_img) > 127)


def recortar(ruta, umbral=16.0, umbral_borde=14.0, borde=0.04, abrir_huecos=False, banda_piso=0.13, grad_piso=40.0, abrir_claros=False):
    im = Image.open(ruta).convert('RGB')
    img = np.asarray(im).astype(np.float64)
    h, w, _ = img.shape
    banda = np.zeros((h, w), bool)
    b = max(4, int(min(h, w) * borde))
    banda[:b, :] = banda[:, :b] = banda[:, -b:] = banda[-b:, :] = True
    fondo = ajustar_fondo(img, banda)
    for _ in range(3):
        resid = np.abs(img - fondo).max(axis=-1)
        fondo = ajustar_fondo(img, resid < umbral * 0.6)
    resid = np.abs(img - fondo).max(axis=-1)

    # Bordes (gradiente) para cerrar siluetas de piezas del mismo tono que el fondo
    gris = img.mean(axis=-1)
    gx = np.abs(np.diff(gris, axis=1, prepend=gris[:, :1]))
    gy = np.abs(np.diff(gris, axis=0, prepend=gris[:1, :]))
    grad = np.maximum(gx, gy)
    frente = (resid > umbral) | (grad > umbral_borde)
    mimg = Image.fromarray(frente.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))
    cerrado = np.array(mimg) > 127
    frente = rellenar_huecos(cerrado)
    lum_f = fondo.mean(axis=-1)
    lum = img.mean(axis=-1)
    if abrir_huecos:
        # Motos y piezas caladas: por los huecos (entre ruedas, chasis) se ve fondo o sombra; no se rellenan
        croma = img.max(axis=-1) - img.min(axis=-1)
        huecos = frente & ~cerrado
        fondo_visible = resid < umbral * 0.75
        sombra_visible = (lum < lum_f) & (lum > 0.42 * lum_f) & (croma < 12)
        abrir = huecos & (fondo_visible | sombra_visible)
        if abrir_claros:
            # Piso blanco atrapado entre el objeto y su sombra (fondos claros): tan claro como el fondo y sin color
            abrir |= huecos & (lum >= lum_f - 6) & (lum <= lum_f + 40) & (croma < 12)
        abrir = np.array(Image.fromarray(abrir.astype(np.uint8) * 255).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))) > 127
        frente = frente & ~abrir
    # Piso claro del estudio junto a las ruedas / caballete (franja inferior del objeto): sin color ni textura.
    # Primero se quitan las motas sueltas para que no estiren el alto del objeto.
    frente = regiones_grandes(frente)
    croma = img.max(axis=-1) - img.min(axis=-1)
    filas = np.nonzero(frente.any(axis=1))[0]
    if banda_piso > 0 and len(filas):
        arriba, abajo = filas[0], filas[-1]
        banda_inf = np.zeros_like(frente)
        banda_inf[int(abajo - banda_piso * (abajo - arriba)):, :] = True
        grad_dil = np.array(Image.fromarray(np.clip(grad, 0, 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))).astype(float)
        piso = banda_inf & (lum > 0.5 * lum_f) & (croma < 14) & (grad_dil < grad_piso)
        frente = frente & ~piso
        if abrir_claros and float(np.median(lum_f)) > 200:
            # Sombra de contacto suave (solo en fotos de fondo claro) en la mitad inferior (gris sin color y liso): se vuelve sombra semitransparente
            mitad_inf = np.zeros_like(frente)
            mitad_inf[int(arriba + 0.45 * (abajo - arriba)):, :] = True
            grad_fino = np.array(Image.fromarray(np.clip(grad, 0, 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))).astype(float)
            suave = mitad_inf & (lum > 0.55 * lum_f) & (lum < 0.985 * lum_f) & (croma < 12) & (grad_fino < 6)
            frente = frente & ~suave
    frente = regiones_grandes(frente)

    # Sombra suave: fuera del objeto, lo que es más oscuro que el fondo se guarda como negro semitransparente
    sombra = np.clip((lum_f - lum) / np.maximum(lum_f, 1) * 1.6, 0, 0.55)
    alfa_obj = np.array(Image.fromarray(frente.astype(np.uint8) * 255)
                        .filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.1))) / 255.0
    alfa = np.maximum(alfa_obj, sombra * (1 - alfa_obj))
    a = np.clip(alfa_obj, 1e-3, 1)[..., None]
    desmezcla = np.clip((img - (1 - a) * fondo) / np.maximum(a, 0.45), 0, 255)
    color = np.where(a > 0.98, img, desmezcla) * alfa_obj[..., None]
    rgb = np.where(alfa[..., None] > 1e-4, color / np.maximum(alfa[..., None], 1e-4), 0)
    rgba = np.dstack([np.clip(rgb, 0, 255), alfa * 255]).astype(np.uint8)
    return Image.fromarray(rgba, 'RGBA'), frente
