<?php

declare(strict_types=1);

namespace Zwembad\Tests\Unit\Services;

use PHPUnit\Framework\TestCase;
use Zwembad\Repositories\IDatabaseRepository;
use Zwembad\Services\DatabaseService;

/**
 * Borgt dat het legen van de gebruikers-tabel altijd de standaardgebruikers
 * herstelt — zodat je jezelf nooit buitensluit — en dat andere tabellen dat NIET
 * triggeren. Werkt met een gemockte repository (geen echte DB nodig).
 */
final class DatabaseServiceTest extends TestCase
{
    public function testLegenVanGebruikersHersteltStandaardgebruikers(): void
    {
        $repo = $this->createMock(IDatabaseRepository::class);
        $repo->expects(self::once())->method('truncate')->with('gebruikers');
        $repo->expects(self::once())->method('herstelStandaardGebruikers');

        (new DatabaseService($repo))->truncate('gebruikers');
    }

    public function testLegenVanAndereTabelHersteltGeenGebruikers(): void
    {
        $repo = $this->createMock(IDatabaseRepository::class);
        $repo->expects(self::once())->method('truncate')->with('logboek');
        $repo->expects(self::never())->method('herstelStandaardGebruikers');

        (new DatabaseService($repo))->truncate('logboek');
    }

    public function testWisAllesHersteltStandaardgebruikers(): void
    {
        $repo = $this->createMock(IDatabaseRepository::class);
        $repo->expects(self::once())->method('truncateAll');
        $repo->expects(self::once())->method('herstelStandaardGebruikers');

        (new DatabaseService($repo))->wisAlles();
    }
}
