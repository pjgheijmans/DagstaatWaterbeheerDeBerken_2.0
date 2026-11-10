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

Optioneel, voor hosts met een File Manager die kan uitpakken: een kant-en-klare zip
met forward-slash-paden (werkt op Linux-hosts) komt in `dist/vendor.zip`
(git-genegeerd). Uitpakken in `app/backend/` geeft `app/backend/vendor/`. Heb je
alleen FTP zonder "Extract", upload dan de map `backend/vendor/` als bestanden.

## Indeling

Kort:

```
htdocs/                 ← vaste web-root van de host
├── index.php           ← deploy/htdocs/index.php      (lader)
├── .htaccess           ← deploy/htdocs/.htaccess      (rewrite)
├── init-web.php        ← deploy/htdocs/init-web.php    (EENMALIG; daarna verwijderen)
└── app/                ← de HELE repo hierin uploaden
    ├── .htaccess       ← deploy/htdocs/app/.htaccess   (blokkeert directe toegang)
    ├── backend/        (incl. vooraf gebouwde vendor/ en config/settings.local.php)
    ├── frontend/
    └── init.sql
```
