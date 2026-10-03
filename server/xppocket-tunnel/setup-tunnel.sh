#!/usr/bin/env bash
# Regenera credentials + reinicia túnel con config local (3 hostnames).
set -euo pipefail
TOKEN=$(cloudflared tunnel token xppocket)
python3 << PY
import base64, json, pathlib
token = "$TOKEN"
data = json.loads(base64.b64decode(token + "==="))
path = pathlib.Path.home() / ".cloudflared" / f"{data['t']}.json"
path.write_text(json.dumps({
    "AccountTag": data["a"],
    "TunnelSecret": data["s"],
    "TunnelID": data["t"],
    "Endpoint": "",
}))
path.chmod(0o400)
print(f"Wrote {path}")
PY
pm2 delete xppocket-tunnel 2>/dev/null || true
pm2 start /usr/local/bin/cloudflared --name xppocket-tunnel -- \
  tunnel --config /home/genexix05/docker/xppocket-tunnel/config.yml run
pm2 save
