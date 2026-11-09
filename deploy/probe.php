<?php

/**
 * TIJDELIJK testbestand om de web-root te vinden en PHP te controleren.
 *
 * 1. Upload dit bestand naar de map waarvan je DENKT dat het de web-root is
 *    (bijv. je FTP-root).
 * 2. Open in de browser:  https://waterbeheer.debercken.nl/probe.php
 *    - Zie je "WEB-ROOT OK ..." met versie 8.0.x  → dat is inderdaad de web-root
 *      én PHP 8.0 draait. Hier komen index.php, .htaccess, init-web.php en app/.
 *    - Krijg je 404 / een downloadvenster / de maplijst → het is NIET de web-root;
 *      probeer een submap (www/htdocs/httpdocs/public_html).
 * 3. VERWIJDER probe.php zodra je het weet.
 */

echo 'WEB-ROOT OK — PHP ' . PHP_VERSION . ' (' . php_sapi_name() . ")\n";
echo 'pdo_mysql: ' . (extension_loaded('pdo_mysql') ? 'ja' : 'NEE — vereist!') . "\n";
echo 'Map op schijf: ' . __DIR__ . "\n";
