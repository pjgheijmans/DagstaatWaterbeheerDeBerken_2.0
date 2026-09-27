<?php

declare(strict_types=1);

namespace Zwembad\Repositories;

/**
 * Port van backend/repositories/IDatabaseRepository.ts.
 */
interface IDatabaseRepository
{
    /** @return array<int,array<string,mixed>> */
    public function exportRows(string $tabel): array;

    public function runInitSql(): void;

    public function truncate(string $tabel): void;

    public function truncateAll(): void;

    public function seedAllDefaults(): void;

    /**
     * Herstel de standaardgebruikers nadat de gebruikers-tabel is geleegd, zodat
     * er altijd een account overblijft om mee in te loggen (geen uitsluiting).
     */
    public function herstelStandaardGebruikers(): void;

    public function getBadId(string $badNaam): ?int;

    /**
     * @param string[] $columns
     * @param array<int,string|int|float|null> $values
     */
    public function importRow(string $actualTabel, array $columns, array $values): void;

    public function setForeignKeyChecks(bool $on): void;
}
