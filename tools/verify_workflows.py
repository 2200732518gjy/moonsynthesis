"""Protocol, CSV, SVG, malformed IO and sensitivity integration checks; stdlib only."""
import csv, io, json, pathlib, subprocess, tempfile, xml.etree.ElementTree as ET
ROOT = pathlib.Path(__file__).resolve().parents[1]
CLI = ROOT/'tools/synthesis.mjs'

def invoke(body, file=False):
    with tempfile.TemporaryDirectory() as d:
        if file:
            p = pathlib.Path(d)/'request.json'; p.write_bytes(body)
            return subprocess.run(['node',str(CLI),str(p)], capture_output=True, timeout=30)
        return subprocess.run(['node',str(CLI)],input=body,capture_output=True,timeout=30)

body = (ROOT/'examples/request.json').read_bytes()
process = invoke(body)
assert process.returncode == 0
response = json.loads(process.stdout)
assert response['ok']
r = response['results']
assert set(r) == {'summary','studies','leave-one-out','cumulative','subgroups','csv','svg'}
assert len(r['leave-one-out']) == 4 and len(r['cumulative']) == 3
assert r['cumulative'][-1]['analysis'] == r['summary']
assert len(r['subgroups']['groups']) == 2
rows = list(csv.reader(io.StringIO(r['csv'], newline='')))
assert len(rows) == 6 and all(len(row)==10 for row in rows)
assert rows[-1][0] == 'pooled'
ET.fromstring(r['svg'])
# Labels must round-trip in JSON, quote safely in CSV and remain passive SVG text.
request = json.loads(body)
request['studies'][0]['id'] = ' =SUM(1,2)"\n<script>&'
hostile = json.loads(invoke(json.dumps(request).encode()).stdout)['results']
assert hostile['studies'][0]['id'] == request['studies'][0]['id']
parsed = list(csv.reader(io.StringIO(hostile['csv'], newline='')))
assert parsed[1][1] == "'"+request['studies'][0]['id']
ET.fromstring(hostile['svg'])
assert '<script>' not in hostile['svg']
for bad in [b'{}', b'[]', b'{"version":1,"version":1}', b'NaN', b'{"version":1e999}']:
    p = invoke(bad)
    assert p.returncode == 0 and json.loads(p.stdout)['ok'] is False
for bad in [b'\xff', b'x'*1048577]:
    assert invoke(bad).returncode == 2
assert json.loads(invoke(body, file=True).stdout)['ok']
assert invoke(b'x'*1048577, file=True).returncode == 2
print(json.dumps(dict(workflow='seven outputs, sensitivity, hostile labels, malformed JSON, bounded UTF8 IO', passed=True)))
