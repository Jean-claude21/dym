# Clips verticaux 720x1280, 8 s, zoom lent, à partir des images de la galerie DYM.
$ErrorActionPreference = 'Continue'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
$ff = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ff) { $ff = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
Write-Host "ffmpeg: $ff"
$src = 'D:\JC\programmation\dym\apps\dym_gallery\assets\demo'
$out = 'C:\Users\Jean-Claude\dev-setup\videos'
New-Item -ItemType Directory -Force $out | Out-Null
$images = @('stores\etal-akossiwa', 'stores\cour-esi', 'stores\epicerie-kodjo', 'products\tomates', 'products\gombo',
  'products\bissap', 'products\poisson-fume', 'products\piment', 'aisles\fruits', 'aisles\legumes', 'illustrations\panier', 'products\pack-jus')
$i = 0
foreach ($img in $images) {
  $i++
  $dest = Join-Path $out ('clip{0:D2}.mp4' -f $i)
  if (Test-Path $dest) { Write-Host "$img déjà fait"; continue }
  $vf = "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,zoompan=z='min(zoom+0.0012,1.25)':d=240:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=720x1280:fps=30"
  & $ff -hide_banner -loglevel error -y -loop 1 -i "$src\$img.webp" -vf $vf -t 8 -c:v libx264 -preset ultrafast -crf 26 -pix_fmt yuv420p -movflags +faststart $dest
  Write-Host ("{0} -> {1} ({2} Ko)" -f $img, $dest, [int]((Get-Item $dest).Length / 1KB))
}
Write-Host 'VIDEOS TERMINE'
