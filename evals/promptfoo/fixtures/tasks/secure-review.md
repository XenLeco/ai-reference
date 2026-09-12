Security review of `api/users.py`. Report findings in the shape the skill defines.

```python
import sqlite3
import subprocess
from flask import request, jsonify

db = sqlite3.connect("app.db", check_same_thread=False)

def get_user():
    name = request.args.get("name", "")
    cur = db.execute(f"SELECT id, name, email FROM users WHERE name = '{name}'")
    return jsonify(cur.fetchall())

def convert_avatar():
    path = request.form["path"]
    subprocess.run(f"convert {path} -resize 128x128 /srv/avatars/out.png", shell=True)
    return "ok"
```
