# deploy/

Kant-en-klare bestanden om de app op de gedeelde webserver
(`waterbeheer.debercken.nl`, Apache + MySQL, vaste web-root `htdocs`) te zetten.

De map `deploy/htdocs/` spiegelt exact wat er in de web-root van de server komt te
staan. De volledige stappen staan in **[`docs/deployment.md`](../docs/deployment.md)**.

## Vooraf: `vendor/` bouwen

De host heeft geen Composer; bouw `backend/vendor/` lokaal en upload het mee. Dit
installeert uit de vastgelegde `composer.lock` (reproduceerbaar), alleen
productie-deps:

```bash
cd backend && composer install --no-dev --optimize-autoloader
```

## Complete payload-zip (aanbevolen)

Eén zip met de volledige web-root, dev-rommel er al uit (geen `docker/`,
`Dockerfile`, `test/`, `phpunit*`, `.example`, en géén oude root-restanten):

```bash
python deploy/build-payload.py        # schrijft dist/site-upload.zip
```

Upload `dist/site-upload.zip` naar de web-root en pak uit (File Manager → Extract,
of `unzip`). ⚠️ Bevat je `settings.local.php` mét DB-wachtwoord — niet delen.

## Indeling

```
htdocs/                 ← vaste web-root van de host
├── index.php           ← deploy/htdocs/index.php      (lader)
├── .htaccess           ← deploy/htdocs/.htaccess      (rewrite)
├── init-web.php        ← deploy/htdocs/init-web.php    (EENMALIG; daarna verwijderen)
└── app/                ← NIET de hele repo — alleen deze drie + de .htaccess:
    ├── .htaccess       ← deploy/htdocs/app/.htaccess   (blokkeert directe toegang)
    ├── backend/        (incl. vooraf gebouwde vendor/ en config/settings.local.php)
    ├── frontend/
    └── init.sql
```

De repo-root bevat verder veel dat NIET op de host hoort (`docker-compose.yml`,
`docs/`, `deploy/`, `dist/`, Node-tooling en oude Node/TS-restanten als `js/`,
`php/`, `public/`, `routes/`). De payload-zip hierboven laat dat allemaal weg.
