#!/usr/bin/env python3
"""Bouw dist/site-upload.zip: de volledige web-root, klaar om op de gedeelde host
uit te pakken.

Zie docs/deployment.md. De zip bevat:

    index.php, .htaccess, init-web.php        (web-root lijmbestanden)
    app/.htaccess                             (Require all denied)
    app/init.sql
    app/frontend/...                          (de hele frontend)
    app/backend/...                           (zonder dev-/build-bestanden)

Dev- en build-zaken worden bewust weggelaten (docker/, Dockerfile, test/,
phpunit*, *.example). De oude Node/TS-restanten in de repo-root zitten er sowieso
niet in, omdat we alleen backend/, frontend/ en init.sql meenemen.

LET OP: de zip bevat backend/config/settings.local.php MET je DB-wachtwoord (als dat
bestand bestaat). Deel de zip dus niet.

Gebruik (vanuit de repo-root):  python deploy/build-payload.py
"""

import os
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "dist", "site-upload.zip")

# backend-bestanden/mappen (top-level) die NIET mee hoeven
BACKEND_SKIP_TOP = {
    "test", "docker", "Dockerfile", "phpunit.xml",
    "phpunit.integration.xml", "README.md", ".gitignore",
}


def _backend_skip(rel: str) -> bool:
    top = rel.split("/", 1)[0]
    if top in BACKEND_SKIP_TOP:
        return True
    # voorbeeld-configs (settings.local.php.example e.d.) niet meenemen
    if rel.startswith("config/") and rel.endswith(".example"):
        return True
    return False


def _add_tree(z: zipfile.ZipFile, src_dir: str, arc_prefix: str, skip=lambda rel: False) -> None:
    for dirpath, _dirs, files in os.walk(src_dir):
        for f in files:
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, src_dir).replace(os.sep, "/")
            if skip(rel):
                continue
            z.write(full, f"{arc_prefix}/{rel}")


def main() -> None:
    vendor = os.path.join(ROOT, "backend", "vendor", "autoload.php")
    if not os.path.isfile(vendor):
        raise SystemExit(
            "backend/vendor ontbreekt. Bouw eerst:\n"
            "  cd backend && composer install --no-dev --optimize-autoloader"
        )

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        d = os.path.join(ROOT, "deploy", "htdocs")
        z.write(os.path.join(d, "index.php"), "index.php")
        z.write(os.path.join(d, ".htaccess"), ".htaccess")
        z.write(os.path.join(d, "init-web.php"), "init-web.php")
        z.write(os.path.join(d, "app", ".htaccess"), "app/.htaccess")
        z.write(os.path.join(ROOT, "init.sql"), "app/init.sql")
        _add_tree(z, os.path.join(ROOT, "frontend"), "app/frontend")
        _add_tree(z, os.path.join(ROOT, "backend"), "app/backend", skip=_backend_skip)
        count = len(z.namelist())

    size_mb = os.path.getsize(OUT) / 1024 / 1024
    print(f"Geschreven: {OUT}")
    print(f"Bestanden: {count}  |  Grootte: {size_mb:.2f} MB")


if __name__ == "__main__":
    main()
