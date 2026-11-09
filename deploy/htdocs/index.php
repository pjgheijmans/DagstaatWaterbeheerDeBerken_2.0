<?php

declare(strict_types=1);

/**
 * Front controller-lader voor gedeelde hosting met een VASTE web-root (htdocs).
 *
 * De hele applicatie (de repo) staat in htdocs/app/. Dit mini-bestand geeft elk
 * verzoek door aan de echte front controller in app/backend/public/index.php.
 * Die gebruikt uitsluitend __DIR__-relatieve paden, dus alle interne verwijzingen
 * (vendor/, config/, frontend/, init.sql) blijven vanzelf kloppen.
 *
 * Verander hieronder niets — tenzij je app/ een andere naam geeft.
 */

require __DIR__ . '/app/backend/public/index.php';
