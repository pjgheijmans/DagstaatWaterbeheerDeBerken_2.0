# Deployment — gedeelde Apache/MySQL-hosting

Hoe je de Digitale Dagstaat op de productieserver zet
(`waterbeheer.debercken.nl`). De server draait **Apache + mod_php (PHP 8.0)** en
**MySQL** op de standaardpoorten. Er is **geen Docker** op de server — de
containers zijn alleen de lokale ontwikkelomgeving. Apache voert de PHP-bestanden
rechtstreeks uit, precies zoals de code lokaal ook draait.

Twee host-eigenaardigheden sturen deze aanpak:

- De **web-root ligt vast op `htdocs/`** en is niet te verplaatsen.
- De **databasenaam ligt vast op `2372waterbeheer`**.

## Hoe het werkt (in één alinea)

De app verwacht dat Apache's document-root naar `backend/public/` wijst. Dat kan
hier niet, dus we zetten de hele repo in `htdocs/app/` en plaatsen in `htdocs/`
een piepklein `index.php` dat het verzoek doorgeeft aan
`app/backend/public/index.php`. Die echte front controller gebruikt alleen
`__DIR__`-relatieve paden, dus alle interne verwijzingen blijven kloppen. De
frontend-assets (`/js`, `/css`, `/images`) worden door PHP uitgeserveerd
(`FrontendController`), niet rechtstreeks door Apache — ze hoeven dus niet in de
web-root te staan. Een `.htaccess` in `app/` blokkeert directe web-toegang tot de
broncode.

## Mapindeling op de server

```
htdocs/                 ← vaste web-root
├── index.php           ← uit deploy/htdocs/index.php      (lader)
├── .htaccess           ← uit deploy/htdocs/.htaccess      (rewrite naar index.php)
├── init-web.php        ← uit deploy/htdocs/init-web.php    (EENMALIG, daarna wissen)
└── app/                ← de HELE repo
    ├── .htaccess       ← uit deploy/htdocs/app/.htaccess   (Require all denied)
    ├── backend/
    │   ├── public/  src/  config/  bin/
    │   └── vendor/     ← VOORAF gebouwd (staat niet in git)
    ├── frontend/
    └── init.sql
```

> **"htdocs" = jouw web-root.** De naam verschilt per host. Bij veel hosters is de
> **FTP-root meteen de web-root**: log je met FTP in en land je direct tussen de
> sitebestanden, dan is díe map je "htdocs" en gaan `index.php`, `.htaccess`,
> `init-web.php` en `app/` daar rechtstreeks in. Zie je na inloggen juist een map
> als `www`, `htdocs`, `httpdocs`, `public_html` of `web`, dan is dát de web-root —
> ga daarin. Twijfel je? Zie stap 0.

## Stappenplan

### 0. Vind je web-root (als je het niet zeker weet)

Upload `deploy/probe.php` naar de map waarvan je denkt dat het de web-root is en
open `https://waterbeheer.debercken.nl/probe.php`:

- **"WEB-ROOT OK — PHP 8.0.x"** → dit is de web-root én PHP 8.0 draait
  (en `pdo_mysql` wordt meteen gecontroleerd). Hier komt alles in.
- **404 / downloadvenster / maplijst** → niet de web-root; probeer een submap.

Verwijder `probe.php` zodra je het weet.

### 1. Bouw `vendor/` (eenmalig, lokaal)

`vendor/` staat niet op schijf (lokaal leeft het in een Docker-volume) en niet in
git. Bouw het zodat het mee-geüpload kan worden. Kies één:

```bash
# A. Uit de draaiende container kopiëren:
docker compose up -d web
docker compose exec web composer install --no-dev --optimize-autoloader
docker cp zwembad_web:/var/www/html/backend/vendor ./backend/vendor

# B. Of met een wegwerp-Composer-container (vanuit backend/):
docker run --rm -v "$PWD:/app" -w /app composer:2 \
  install --no-dev --optimize-autoloader --ignore-platform-reqs
```

Het resultaat is pure PHP (alleen `pdo_mysql` nodig), dus de Linux-build draait
ongewijzigd op de host. `composer.json` pint `platform.php = 8.0.30`.

### 2. Zet de DB-gegevens klaar

Kopieer `backend/config/settings.local.php.example` naar
`backend/config/settings.local.php` en vul in:

```php
return [
    'host' => 'localhost',
    'name' => '2372waterbeheer',   // vaste naam van de host
    'user' => '…db-gebruiker…',
    'pass' => '…db-wachtwoord…',
];
```

`settings.local.php` staat in `.gitignore` → je wachtwoord komt niet in
git/OneDrive. (Env-variabelen `DB_*` overrulen dit bestand; op de host zijn die er
meestal niet, dus dit bestand wint.)

### 3. Maak de database aan

Maak in het hosting-paneel een **lege** database `2372waterbeheer` + een
DB-gebruiker met rechten erop. `init.sql` doet géén `CREATE DATABASE`; het vult
alleen de tabellen in een bestaande database.

### 4. Upload

- De **hele repo** → `htdocs/app/` (inclusief de zojuist gebouwde `backend/vendor/`
  en je `backend/config/settings.local.php`).
- De vier glue-bestanden uit `deploy/htdocs/` → op hun plek
  (`htdocs/index.php`, `htdocs/.htaccess`, `htdocs/init-web.php`,
  `htdocs/app/.htaccess`).

Zorg dat verborgen bestanden (`.htaccess`) meegaan in je FTP-client.

### 5. Initialiseer het schema (eenmalig)

> **Niet** `mysql < init.sql` gebruiken — dat breekt op de bewuste dubbele
> `ALTER TABLE`-migraties (zie CLAUDE.md).

- **Heb je SSH?** `cd htdocs/app/backend && php bin/init-db.php`.
- **Geen SSH** (de normale situatie hier): gebruik `init-web.php`:
  1. Zet bovenin `init-web.php` een eigen, lang `$token`.
  2. Open eenmalig
     `https://waterbeheer.debercken.nl/init-web.php?token=JOUW-TOKEN`.
  3. Zie je **"Klaar"**? **Verwijder `init-web.php`** meteen uit `htdocs/`.

De in-app knop "database initialiseren" (`/api/database/initialiseer`) kan dit
**niet** doen bij een lege database: die vereist een ingelogde beheerder, en er is
nog geen account. Daarom is `init-web.php` nodig voor de allereerste keer.

### 6. Eerste login + afronden

- Open `https://waterbeheer.debercken.nl/` en log in met een standaardaccount
  (uit `seedAllDefaults()`).
- **Wijzig direct de standaardwachtwoorden** (bij eerste login worden ze naar
  bcrypt omgezet).
- Controleer dat `init-web.php` weg is.

## Controlelijst voor de host

- PHP **8.0** actief, met extensie **`pdo_mysql`**.
- `mod_rewrite` aan en `AllowOverride All` voor `htdocs/` (nodig voor `.htaccess`).
  Bij de meeste shared hosts staat dit standaard aan.
- **HTTPS** + een redirect van http → https (de sessiecookie hoort over TLS).

## Latere updates

Code wijzigen = de betreffende bestanden in `htdocs/app/` overschrijven. Alleen bij
gewijzigde dependencies opnieuw `vendor/` bouwen en uploaden. Een schemawijziging
in `init.sql` pas je toe via de in-app knop "database initialiseren" (als beheerder
ingelogd) — die draait dezelfde idempotente `runInitSql()`.

## Waarom geen "detecteer server, schakel containers uit"?

Dat is niet nodig: de PHP-code weet niet of hij in een container draait en hoeft
dat ook niet te weten. Docker is puur het lokale dev-gereedschap; op de host staat
er geen Docker en draait Apache de bestanden direct. Het enige verschil tussen
lokaal en host is configuratie (DB-gegevens via `settings.local.php`) en de
web-root-constructie hierboven — geen code-tak.
