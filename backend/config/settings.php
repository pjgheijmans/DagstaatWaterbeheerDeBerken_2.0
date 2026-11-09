<?php

declare(strict_types=1);

/**
 * Configuratie-entry 'settings' voor de DI-container.
 *
 * Volgorde van voorrang voor de DB-gegevens (hoog → laag):
 *   1. Omgevingsvariabelen DB_HOST/DB_NAME/DB_USER/DB_PASSWORD (zoals in Docker).
 *   2. settings.local.php — een niet-gecommit bestand voor gedeelde hosting zonder
 *      env-ondersteuning (zie settings.local.php.example). Houdt wachtwoorden uit git.
 *   3. De hardgecodeerde standaarden hieronder (dev/Docker-defaults).
 */

function env(string $sleutel, string $standaard): string
{
    $waarde = getenv($sleutel);
    return $waarde !== false && $waarde !== '' ? $waarde : $standaard;
}

// Optionele hosting-override. Env-variabelen blijven altijd winnen (zie env()).
$lokaal = is_file(__DIR__ . '/settings.local.php')
    ? (require __DIR__ . '/settings.local.php')
    : [];

return [
    'settings' => [
        'db' => [
            'host' => env('DB_HOST', $lokaal['host'] ?? 'localhost'),
            'name' => env('DB_NAME', $lokaal['name'] ?? 'zwembad_status'),
            'user' => env('DB_USER', $lokaal['user'] ?? 'root'),
            'pass' => env('DB_PASSWORD', $lokaal['pass'] ?? 'geheim_wachtwoord'),
        ],
    ],
];
