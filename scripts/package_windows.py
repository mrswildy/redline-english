"""Package only the Windows runtime, data and redistributable license notices."""
from pathlib import Path
import re, shutil, zipfile, hashlib
ROOT=Path(__file__).resolve().parent.parent
version=re.search(r'config/version="([^"]+)"',(ROOT/'project.godot').read_text()).group(1)
stage=ROOT/'outputs/windows';licenses=stage/'licenses';licenses.mkdir(exist_ok=True)
for source in (ROOT/'assets/licenses').iterdir():
 if source.suffix in ('.md','.txt'):shutil.copy2(source,licenses/source.name)
readme=f'''REDLINE: Road Rash {version} — Windows x64

How to play
1. Extract the complete ZIP to a regular folder.
2. Double-click REDLINE.exe to play. Godot does not need to be installed.
3. Keep REDLINE.exe and REDLINE.pck together in the same folder.

Requirements: Windows 10/11, 64-bit Intel/AMD processor, and graphics support for OpenGL 3.3.
Noto Sans SC and all music and game assets are included.

Controls
W / ↑: throttle; S / ↓: brake; A, D / ←, →: steer.
J: punch; K: kick; L: weapon attack; O: disarm; U: block; I: dodge.
Hold Shift to charge, release to boost; Space: attack; C: cruise control; Esc: pause; Enter: start.
Ease off or brake before corners. Watch the recommended speed and roadside arrows.
Adjust sound and music volume separately in Settings.

Save: %APPDATA%\\Godot\\app_userdata\\REDLINE - Road Rash\\career_v2.json
The first launch creates a separate Windows career save.

This package is not signed with Windows Authenticode.
Third-party music, engine recordings, font, and engine licenses are in the licenses folder.
'''
(stage/'README.txt').write_text(readme,encoding='utf-8-sig')
files=[stage/'REDLINE.exe',stage/'REDLINE.pck',stage/'README.txt']+sorted(licenses.glob('*'))
for file in files:
 if not file.is_file() or file.stat().st_size==0:raise RuntimeError(f'Missing package input: {file}')
name=f'REDLINE-v{version.removesuffix(".0")}-Windows-x64'
output=ROOT/'outputs'/f'{name}.zip'
with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for file in files:archive.write(file,Path(name)/file.relative_to(stage))
with zipfile.ZipFile(output) as archive:
 assert archive.testzip() is None
 assert len(archive.namelist())==len(files)
checksum=hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(f'{checksum}  {output.name}\n')
print(f'Windows package: {output} ({output.stat().st_size/1024/1024:.1f} MiB), ZIP CRC passed')
