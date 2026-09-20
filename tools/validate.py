from pathlib import Path
import json, sys
root = Path(__file__).resolve().parents[1]
project = json.loads((root/'default.project.json').read_text())
files = sorted((root/'src').rglob('*.lua'))
assert files, 'No Luau files found'
required = [
    root/'src/ReplicatedStorage/Shared/Config.lua',
    root/'src/ReplicatedStorage/Shared/Net.lua',
    root/'src/ServerScriptService/HubServer.server.lua',
    root/'src/ServerScriptService/Services/HubBuilder.lua',
    root/'src/ServerScriptService/Services/SessionService.lua',
    root/'src/StarterGui/HubUI.client.lua',
    root/'src/StarterPlayer/StarterPlayerScripts/HubCamera.client.lua',
]
for f in required: assert f.exists(), f'Missing {f}'
for f in files:
    s=f.read_text()
    assert '\x00' not in s, f'Binary byte in {f}'
    assert s.count('function ') >= 1 or 'return ' in s, f'Unexpected empty script {f}'
print(f'Validated project manifest and {len(files)} Luau files.')
