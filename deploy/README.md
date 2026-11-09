# deploy/

Kant-en-klare bestanden om de app op de gedeelde webserver
(`waterbeheer.debercken.nl`, Apache + MySQL, vaste web-root `htdocs`) te zetten.

De map `deploy/htdocs/` spiegelt exact wat er in de web-root van de server komt te
staan. De volledige stappen staan in **[`docs/deployment.md`](../docs/deployment.md)**.

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
