from pathlib import Path
import re

src=Path("index.html")
out=Path("index-litones.html")
section=Path("litones_carousel_22_items.html").read_text(encoding="utf-8")
text=src.read_text(encoding="utf-8")
# Remove the malformed AWIN block if it was pasted inside the search handler.
text=re.sub(r",\s*<!-- START ADVERTISER: LitONES from awin\.com -->.*?<!-- END ADVERTISER: LitONES from awin\.com -->\s*", "", text, count=1, flags=re.S)
marker='<section class="newsletter">'
if marker not in text: raise SystemExit("Newsletter marker not found; no output created.")
if 'id="litones-lighting"' not in text: text=text.replace(marker, section+"\n"+marker, 1)
out.write_text(text,encoding="utf-8")
print(out.resolve())
