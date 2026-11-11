"""Check the literal Chinese README consumer using a separate Moon workspace.

Workspace membership resolves the exact local release candidate before publication;
post-publication acceptance additionally installs the registry version with no cache.
"""
import json, os, pathlib, re, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
readme = (ROOT/'README.md').read_text(encoding='utf-8')
blocks = re.findall(r'```moonbit\n(.*?)```', readme, re.S)
assert len(blocks) >= 2
manifest = (ROOT/'moon.mod').read_text(encoding='utf-8')
version = re.search(r'^version\s*=\s*"([^"]+)"',manifest,re.M).group(1)
assert f'moon add 2200732518gjy/moonsynthesis@{version}' in readme
with tempfile.TemporaryDirectory(prefix='moonsynthesis-readme-') as directory:
    work = pathlib.Path(directory)
    consumer = work/'consumer'; consumer.mkdir()
    (work/'moon.work').write_text('members = '+json.dumps([os.path.relpath(ROOT, work).replace('\\','/'),'consumer'])+'\n',encoding='utf-8')
    (consumer/'moon.mod').write_text('name = "example/readme-consumer"\nimport { "2200732518gjy/moonsynthesis@'+version+'" }\n',encoding='utf-8')
    (consumer/'moon.pkg').write_text(blocks[0],encoding='utf-8')
    (consumer/'synthesis_test.mbt').write_text(blocks[1],encoding='utf-8')
    for target in ['wasm-gc','js']:
        for action in ['check','test']:
            subprocess.run(['moon',action,'--target',target,'--deny-warn'],cwd=consumer,check=True)
print(json.dumps(dict(workflow='literal Chinese README consumer',version=version,targets=['wasm-gc','js'],passed=True)))
