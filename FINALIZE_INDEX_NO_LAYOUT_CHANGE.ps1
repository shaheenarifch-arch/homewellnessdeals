$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'index.html'
$carouselFile = Join-Path $PSScriptRoot 'litones_carousel_22_items.html'
$output = Join-Path $PSScriptRoot 'index-final.html'

if (-not (Test-Path $source)) { throw 'index.html not found in this folder.' }
if (-not (Test-Path $carouselFile)) { throw 'litones_carousel_22_items.html not found in this folder.' }

Add-Type -AssemblyName System.Web
$originalRaw = [System.IO.File]::ReadAllText($source)

# Decode only when the homepage was saved as escaped HTML.
if ($originalRaw -match '&lt;!DOCTYPE html&gt;' -or $originalRaw -match '&lt;html') {
    $html = [System.Web.HttpUtility]::HtmlDecode($originalRaw)
} else {
    $html = $originalRaw
}

$carousel = [System.IO.File]::ReadAllText($carouselFile).Trim()
if ($carousel -match '&lt;section') {
    $carousel = [System.Web.HttpUtility]::HtmlDecode($carousel)
}

# Remove the incomplete placeholder block only.
$placeholderPattern = '(?s)<!-- START: LitONES carousel -->\s*<section class="collection" id="litones-lighting">.*?\.\.\.\s*22 product cards\s*\.\.\..*?</section>\s*<!-- END: LitONES carousel -->\s*'
$html = [regex]::Replace($html, $placeholderPattern, '')

# Remove an existing complete LitONES block to prevent duplicates.
$completePattern = '(?s)<!-- START: LitONES carousel -->.*?<!-- END: LitONES carousel -->\s*'
$html = [regex]::Replace($html, $completePattern, '')

# Fix the duplicated newsletter opening tag seen in the supplied source.
$html = [regex]::Replace($html, '<section class="newsletter">\s*<section class="newsletter">', '<section class="newsletter">', 1)

$marker = '<section class="newsletter">'
$position = $html.IndexOf($marker)
if ($position -lt 0) { throw 'Newsletter section marker was not found. No output created.' }

# Insert the complete 22-card section before the existing newsletter.
$final = $html.Substring(0, $position) + $carousel + [Environment]::NewLine + $html.Substring($position)

# Small mobile-only safety rules. They do not alter the desktop layout.
$mobileSafety = @'
<style id="litones-mobile-safety">
@media (max-width:650px){
  #litones-lighting{padding-top:62px;padding-bottom:62px;overflow:hidden}
  #litones-lighting .rail{overscroll-behavior-x:contain;-webkit-overflow-scrolling:touch}
  #litones-lighting .card{flex-basis:84vw;max-width:355px}
  #litones-lighting .arrow{width:40px;height:40px}
  #litones-lighting .card-img img{object-fit:contain}
}
</style>
'@
$final = $final.Replace('</head>', $mobileSafety + [Environment]::NewLine + '</head>')

# Production checks.
if (-not $final.TrimStart().StartsWith('<!DOCTYPE html>', [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Output does not begin with a valid DOCTYPE.' }
if ($final -match '\.\.\.\s*22 product cards\s*\.\.\.') { throw 'Placeholder text still exists.' }
if (($final.Split('id="litones-lighting"').Count - 1) -ne 1) { throw 'LitONES section count is not exactly one.' }
if (($final.Split('<section class="newsletter">').Count - 1) -ne 1) { throw 'Newsletter section count is not exactly one.' }
if (($final.Split('<article class="card"').Count - 1) -lt 22) { throw 'Expected product cards were not found.' }

[System.IO.File]::WriteAllText($output, $final, [System.Text.UTF8Encoding]::new($false))
Write-Host "SUCCESS: Created $output" -ForegroundColor Green
Write-Host 'Existing layout preserved. Placeholder removed. One 22-card carousel inserted above the newsletter.'
