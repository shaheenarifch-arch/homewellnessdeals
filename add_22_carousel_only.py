from pathlib import Path

SOURCE = Path('index.html')
CAROUSEL = Path('litones_carousel_22_items.html')
OUTPUT = Path('index-with-litones.html')

if not SOURCE.exists():
    raise SystemExit('ERROR: index.html was not found in this folder.')
if not CAROUSEL.exists():
    raise SystemExit('ERROR: litones_carousel_22_items.html was not found in this folder.')

original = SOURCE.read_text(encoding='utf-8')
carousel = CAROUSEL.read_text(encoding='utf-8').strip()

if not original.lstrip().lower().startswith('<!doctype html>'):
    raise SystemExit('ERROR: index.html is not the full unescaped homepage. Restore the working index.html first.')
if '&lt;!DOCTYPE html&gt;' in original or '&lt;html' in original:
    raise SystemExit('ERROR: index.html is HTML-escaped. Use the working unescaped homepage.')
if 'id="litones-lighting"' in original:
    raise SystemExit('ERROR: The LitONES carousel already exists. No changes made.')

marker = '<section class="newsletter">'
position = original.find(marker)
if position == -1:
    raise SystemExit('ERROR: Newsletter section was not found. No changes made.')

updated = original[:position] + carousel + '\n' + original[position:]
OUTPUT.write_text(updated, encoding='utf-8')

# Verify byte-for-byte preservation outside the one inserted block.
assert updated[:position] == original[:position]
assert updated[position + len(carousel) + 1:] == original[position:]
assert updated.count('id="litones-lighting"') == 1
print('Created:', OUTPUT.resolve())
print('Only one change was made: the 22-card carousel was inserted before the newsletter section.')
