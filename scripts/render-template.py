#!/usr/bin/env python3
"""Render @NAME@ placeholders without echoing private values."""
import argparse, os, re, sys
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('template',type=Path)
p.add_argument('output',type=Path)
p.add_argument('--env-file',type=Path,default=Path.home()/'.config/homeserver/runtime.env')
a=p.parse_args()
values={}
for raw in a.env_file.read_text().splitlines():
    line=raw.strip()
    if not line or line.startswith('#') or '=' not in line: continue
    k,v=line.split('=',1); values[k]=v
text=a.template.read_text()
needed=set(re.findall(r'@([A-Z][A-Z0-9_]*)@',text))
missing=sorted(needed-values.keys())
if missing:
    print('Missing render variables: '+', '.join(missing),file=sys.stderr);raise SystemExit(2)
for key in needed:text=text.replace('@'+key+'@',values[key])
a.output.parent.mkdir(parents=True,exist_ok=True)
tmp=a.output.with_name('.'+a.output.name+'.tmp')
tmp.write_text(text);os.chmod(tmp,0o600);os.replace(tmp,a.output)
print(f'Rendered {a.template} -> {a.output} ({len(needed)} variables; values redacted)')
