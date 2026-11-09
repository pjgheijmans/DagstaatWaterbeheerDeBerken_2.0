<?php

declare(strict_types=1);

/**
 * EENMALIGE database-bootstrap voor hosting ZONDER SSH.
 *
 * De normale init (php bin/init-db.php) vereist een shell; de in-app knop
 * "database initialiseren" vereist een ingelogde beheerder — maar vóór de eerste
 * init bestaan er nog geen tabellen en dus geen account. Dit bestand doorbreekt
 * die kip-en-ei: het maakt het schema (init.sql) + de standaard inlogaccounts aan.
 *
 * GEBRUIK:
 *   1. Zet een eigen, lang token in $token hieronder (vervang GEHEIM_VERANDER_MIJ).
 *   2. Plaats dit bestand in htdocs/ (naast index.php).
 *   3. Open eenmalig:
 *        https://waterbeheer.debercken.nl/init-web.php?token=JOUW-TOKEN
 *   4. Zie je "Klaar"? VERWIJDER init-web.php direct uit htdocs/.
 *
 * Idempotent (veilig bij herhaling), maar het hoort niet blijvend online te staan.
 */

$token = 'GEHEIM_VERANDER_MIJ';

header('Content-Type: text/plain; charset=utf-8');

if ($token === 'GEHEIM_VERANDER_MIJ') {
    http_response_code(500);
    exit("Stel eerst bovenaan init-web.php een eigen \$token in.\n");
}
if (!hash_equals($token, (string) ($_GET['token'] ?? ''))) {
    http_response_code(403);
    exit("Verboden: ongeldig of ontbrekend token.\n");
}

require __DIR__ . '/app/backend/vendor/autoload.php';

use DI\ContainerBuilder;
use Zwembad\Repositories\IDatabaseRepository;

try {
    $builder = new ContainerBuilder();
    $builder->addDefinitions(require __DIR__ . '/app/backend/config/settings.php');
    $builder->addDefinitions(require __DIR__ . '/app/backend/config/dependencies.php');
    $container = $builder->build();

    /** @var IDatabaseRepository $repo */
    $repo = $container->get(IDatabaseRepository::class);
    $repo->runInitSql();        // schema (per statement; dubbele kolommen genegeerd)
    $repo->seedAllDefaults();   // baden, rollen, configuratie, limieten, gebruikers

    echo "Klaar: schema + standaardwaarden aangemaakt.\n";
    echo "VERWIJDER NU init-web.php uit htdocs/ en wijzig de standaardwachtwoorden.\n";
} catch (\Throwable $e) {
    http_response_code(500);
    echo "Fout tijdens initialisatie: " . $e->getMessage() . "\n";
}
