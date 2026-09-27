<?php

declare(strict_types=1);

namespace Zwembad\Repositories;

use PDO;

/**
 * Port van backend/repositories/ConfiguratieRepository.ts — de generieke
 * `configuratie`-tabel (sleutel/waarde).
 */
class ConfiguratieRepository implements IConfiguratieRepository
{
    /**
     * Standaardconfiguratie — bron van waarheid voor een verse DB.
     * @var list<array{sleutel:string,waarde:string,omschrijving:string,type:string}>
     */
    private const DEFAULT_CONFIGURATIE = [
        ['sleutel' => 'sessie_timeout_minuten', 'waarde' => '5', 'omschrijving' => 'Sessie-time-out (idle/sliding) in minuten', 'type' => 'getal'],
    ];

    public function __construct(private PDO $pdo)
    {
    }

    /**
     * Zaai de standaardconfiguratie. Idempotent en niet-destructief (INSERT IGNORE):
     * een door de beheerder gewijzigde waarde blijft staan.
     */
    public function seedDefaults(): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT IGNORE INTO configuratie (sleutel, waarde, omschrijving, type) VALUES (?, ?, ?, ?)',
        );
        foreach (self::DEFAULT_CONFIGURATIE as $c) {
            $stmt->execute([$c['sleutel'], $c['waarde'], $c['omschrijving'], $c['type']]);
        }
    }

    public function getAll(): array
    {
        return $this->pdo
            ->query('SELECT sleutel, waarde, omschrijving, type FROM configuratie ORDER BY sleutel')
            ->fetchAll();
    }

    public function upsert(string $sleutel, string $waarde): void
    {
        $this->pdo->prepare(
            'INSERT INTO configuratie (sleutel, waarde) VALUES (?, ?)
             ON DUPLICATE KEY UPDATE waarde = VALUES(waarde)',
        )->execute([$sleutel, $waarde]);
    }
}
