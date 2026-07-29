# Fonts used by `documentRender`

- `Heebo-Variable.ttf` — the original variable font. Used by the legacy
  PDFKit path in `legalDocumentEngine.service.js` (PDFKit has no issue
  embedding variable fonts).
- `Heebo-Regular-static.ttf` / `Heebo-Bold-static.ttf` — fixed-weight
  instances used by the Puppeteer path in `documentRender/`.

## Why the static instances exist

Chromium's PDF/Skia print backend cannot embed an OpenType **variable**
font as a proper CID TrueType font. When a page's `@font-face` points at
one, Chromium silently falls back to embedding it as **Type 3** (each
glyph as a vector-drawing procedure). Visually this is identical, but
Type 3 glyphs have no reliable `ToUnicode` map — the resulting PDF text
is not selectable, searchable, or copy-pasteable, which defeats the
entire point of moving off the old html2canvas+jsPDF rasterization path.

Verified with `pdffonts`:

```
Heebo-Variable.ttf as @font-face  -> Type 3,          emb yes, uni yes  (NOT extractable)
Heebo-Regular-static.ttf          -> CID TrueType, Identity-H (extractable)
```

## Regenerating the static instances

```bash
pip install fonttools
cd backend
python -m fontTools varLib.instancer -o src/assets/fonts/Heebo-Regular-static.ttf src/assets/fonts/Heebo-Variable.ttf wght=400
python -m fontTools varLib.instancer -o src/assets/fonts/Heebo-Bold-static.ttf    src/assets/fonts/Heebo-Variable.ttf wght=700
```

Only needed again if `Heebo-Variable.ttf` is replaced/updated.
