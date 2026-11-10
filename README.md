# Digitale Dagstaat Zwembad

[![PHP tests](https://github.com/pjgheijmans/NewSiteWaterbeheerDeBercken/actions/workflows/php-tests.yml/badge.svg)](https://github.com/pjgheijmans/NewSiteWaterbeheerDeBercken/actions/workflows/php-tests.yml)
[![Frontend tests](https://github.com/pjgheijmans/NewSiteWaterbeheerDeBercken/actions/workflows/frontend-tests.yml/badge.svg)](https://github.com/pjgheijmans/NewSiteWaterbeheerDeBercken/actions/workflows/frontend-tests.yml)

Full-stack webapplicatie voor het bijhouden van de dagelijkse waterkwaliteit van een
zwembad: meetwaarden, verbruik, coördinator-checklists, automatisch gegenereerde
acties/taken en trendanalyse. Drie rollen — **Waterbeheerder**, **Coördinator**,
**Administrator** — elk met hun eigen schermen.

**Stack:** PHP 8.0 (Slim 4 + PHP-DI) backend, vanilla-JS-frontend (ES6-klassen, geen
bundler), MySQL 8. Draait op gedeelde Apache+MySQL-hosting in productie (zie
[`docs/deployment.md`](docs/deployment.md)); dev/test gecontaineriseerd met Docker.
Code en comments zijn in het Nederlands.

---

## Starten

```bash
docker compose up -d
```

Webapplicatie op `http://localhost:8888`, MySQL op `localhost:3306`. Volledige
dev-commando's (herstarten, resetten, logs, functietracing, lokaal zonder Docker) en
een aantal niet-triviale gotchas staan in [`CLAUDE.md`](CLAUDE.md).

---

## Documentatie

Elk document heeft een eigen rol — geen overlap:

| Document                                                                  | Vertelt je…                                                                                   |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`CLAUDE.md`](CLAUDE.md)                                                  | Dev-commando's, architectuurconventies, niet-triviale gotchas — het startpunt om te bouwen      |
| [`backend/README.md`](backend/README.md)                                 | Backend-specifiek: endpoints per domein, lokaal draaien zonder Docker                          |
| [`docs/deployment.md`](docs/deployment.md)                               | Stap-voor-stap deployen naar de gedeelde host (vaste web-root/DB-naam, geen SSH): mapindeling, `vendor/` bouwen, `settings.local.php`, schema-init |
| [`docs/architecture.md`](docs/architecture.md) + [`docs/architecture/`](docs/architecture/) | De structuur: lagen, modules, ER-diagram, sequencediagrammen — geen requirement-/besluit-ID's |
| [`docs/EPS.md`](docs/EPS.md)                                             | De formele requirements per rol, met traceerbare ID's (`GEN-…`, `WB-…`, …)                     |
| [`docs/EDS.md`](docs/EDS.md)                                             | De ontwerpbesluiten (`DD-…`) die elke requirement invullen, met verwijzing terug naar het EPS-ID |
| [`docs/TPS.md`](docs/TPS.md) / [`docs/TAR.md`](docs/TAR.md)              | Testgevallen per requirement, en een gedateerde momentopname van een testrun                    |

---

## Tests

```bash
docker compose exec web composer test               # backend unit
docker compose exec web composer test:integration    # backend integratie (DB)
npm test                                              # frontend (Jest + jsdom)
```

Zie [`CLAUDE.md`](CLAUDE.md#testing) voor de volledige teststrategie en CI-opzet.
