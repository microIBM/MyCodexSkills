# Storybook PDF OCR Coverage

- Generated at: `2026-07-12T07:01:01+08:00`
- Method: PyMuPDF page rendering plus RapidOCR; all four PDFs have no embedded text layer in sampling.
- Completeness means every PDF page has a cached OCR pass and is included in the generated Markdown.

| Slug | Source PDF | Pages | Recognized | Missing | Empty OCR | Low Char | Total Chars | Output |
|---|---|---:|---:|---:|---:|---:|---:|---|
| 48_youzi_shang | 48位柚子悟道心法上册.pdf | 275 | 275 | 0 | 0 | 0 | 120472 | `E:\TraePrj\youziskill\extracted\full_ocr\48_youzi_shang_full_ocr.md` |
| 48_youzi_xia | 48位柚子悟道心法下册.pdf | 239 | 239 | 0 | 0 | 0 | 110177 | `E:\TraePrj\youziskill\extracted\full_ocr\48_youzi_xia_full_ocr.md` |
| jiaogedan | 著名游资实战交割单.pdf | 227 | 227 | 0 | 0 | 0 | 154002 | `E:\TraePrj\youziskill\extracted\full_ocr\jiaogedan_full_ocr.md` |
| yangjia_xinfa | 养家心法.pdf | 235 | 235 | 0 | 0 | 1 | 96516 | `E:\TraePrj\youziskill\extracted\full_ocr\yangjia_xinfa_full_ocr.md` |

## Destination Files

### 48_youzi_shang
- `C:\Users\haoxi\.codex\skills\youzi-48-xinfa\references\research\full-ocr\48_youzi_shang_full_ocr.md`

### 48_youzi_xia
- `C:\Users\haoxi\.codex\skills\youzi-48-xinfa\references\research\full-ocr\48_youzi_xia_full_ocr.md`

### jiaogedan
- `C:\Users\haoxi\.codex\skills\youzi-48-xinfa\references\research\jiaogedan\jiaogedan_full_ocr.md`
- `C:\Users\haoxi\.codex\skills\youzi-yangjia-local-deep\references\research\full-ocr\jiaogedan_full_ocr.md`

### yangjia_xinfa
- `C:\Users\haoxi\.codex\skills\youzi-yangjia-local-deep\references\research\full-ocr\yangjia_xinfa_full_ocr.md`
- Low character pages: 2
