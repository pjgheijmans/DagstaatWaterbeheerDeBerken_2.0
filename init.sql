-- Schema-definitie voor de Digitale Dagstaat. Wordt idempotent toegepast via
-- runInitSql() (per statement, met try/catch) — zie bin/init-db.php.
--
-- De tabellen staan hier in hun definitieve vorm: eerdere per-kolom-migraties
-- (ALTER TABLE) zijn opgenomen in de CREATE-definities. Voor een BESTAANDE
-- database met een oudere structuur voegt "CREATE TABLE IF NOT EXISTS" geen
-- ontbrekende kolommen toe; zulke databases moeten éénmalig los worden
-- bijgewerkt. Nieuwe schema-wijzigingen: pas de CREATE aan én, waar een
-- bestaande database mee moet, voeg tijdelijk een kale ALTER toe (GEEN
-- "IF NOT EXISTS" — dat is MariaDB-syntax en een harde fout op MySQL 8;
-- runInitSql vangt de onschadelijke "Duplicate column" op).

CREATE TABLE IF NOT EXISTS baden (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naam VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS metingen_coordinatoren (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bad_id INT,
    datum DATE NOT NULL,
    tijdstip TIME NOT NULL DEFAULT '00:00:00',
    auteur VARCHAR(100) NULL,
    ph_waarde DECIMAL(4,2) NULL,
    chloor_waarde DECIMAL(4,2) NULL,
    chloor_vrij DECIMAL(4,2) NULL,
    chloor_totaal DECIMAL(4,2) NULL,
    chloor_gebonden DECIMAL(4,2) NULL,
    watertemperatuur DECIMAL(3,1) NULL,
    helderheid VARCHAR(20) NULL,
    bad_gebruikt TINYINT(1) NULL,
    FOREIGN KEY (bad_id) REFERENCES baden(id),
    UNIQUE KEY unieke_meting_coord (bad_id, datum, tijdstip)
);

CREATE TABLE IF NOT EXISTS metingen_diep_ondiep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bad_id INT,
    datum DATE NOT NULL,
    ph_waarde DECIMAL(4,2) NULL,
    chloor_waarde DECIMAL(4,2) NULL,
    temperatuur DECIMAL(4,1) NULL,
    flow INT NULL,
    filter_druk_in DECIMAL(4,2) NULL,
    filter_druk_uit DECIMAL(4,2) NULL,
    kathodische_bescherming DECIMAL(4,2) NULL,
    water DECIMAL(10,2) NULL,
    versie INT NOT NULL DEFAULT 0,
    auteur VARCHAR(100) NULL,
    bijgewerkt_op TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (bad_id) REFERENCES baden(id),
    UNIQUE KEY unieke_meting_diep_ondiep (bad_id, datum)
);

CREATE TABLE IF NOT EXISTS metingen_peuterbad (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bad_id INT,
    datum DATE NOT NULL,
    ph_waarde DECIMAL(4,2) NULL,
    chloor_waarde DECIMAL(4,2) NULL,
    flow INT NULL,
    filter_druk_in DECIMAL(4,2) NULL,
    water INT NULL,
    chemicalien_chloor INT NULL,
    chemicalien_zwavelzuur INT NULL,
    versie INT NOT NULL DEFAULT 0,
    auteur VARCHAR(100) NULL,
    bijgewerkt_op TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (bad_id) REFERENCES baden(id),
    UNIQUE KEY unieke_meting_peuterbad (bad_id, datum)
);

-- Standaardbaden worden in code gezaaid (DatabaseRepository::seedBaden, via
-- seedAllDefaults). Zie de toelichting bij de limieten hieronder.

-- Tabel voor de centrale limieten. min/max zijn DECIMAL(10,2) zodat grote
-- meterstanden passen.
CREATE TABLE IF NOT EXISTS limieten (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parameter_naam VARCHAR(50) NULL UNIQUE,
    min_waarde DECIMAL(10,2) NULL,
    max_waarde DECIMAL(10,2) NULL
);

-- Standaardlimieten worden in code gezaaid — LimietenRepository::seedDefaults()
-- (DEFAULT_LIMIETEN), aangeroepen via seedAllDefaults() in bin/init-db.php (elke
-- start) en "Maak nieuwe database aan". Eén bron van waarheid; limieten valt onder
-- ALL_DATA_TABLES en wordt door "wis alles" geleegd, dus een code-seeder is sowieso
-- nodig. Hier daarom géén INSERT meer.

-- Autorisatie loopt volledig via rollen (zie hieronder). De standaardaccounts
-- worden in code gezaaid — GebruikersRepository::seedDefaults(), aangeroepen door
-- bin/init-db.php (elke start) en "Maak nieuwe database aan" — niet meer hier, zodat
-- er één bron van waarheid is voor de default-gebruikers en hun rollen.
CREATE TABLE IF NOT EXISTS gebruikers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    voornaam VARCHAR(50) NOT NULL,
    achternaam VARCHAR(50) NOT NULL,
    inlognaam VARCHAR(50) NOT NULL UNIQUE,
    wachtwoord VARCHAR(255) NOT NULL);

-- ── Rollen & rechten (RBAC) ───────────────────────────────────────────────────
-- Een rol bundelt rechten per domein (beheer/waterbeheer/coordinator). Een gebruiker
-- kan meerdere rollen hebben; zijn effectieve recht per domein is het HOOGSTE niveau
-- over al zijn rollen, en mag_historie_bewerken geldt als minstens een rol het heeft.
CREATE TABLE IF NOT EXISTS rollen (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naam VARCHAR(50) NOT NULL UNIQUE,
    mag_historie_bewerken TINYINT(1) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS rol_rechten (
    rol_id INT NOT NULL,
    domein ENUM('beheer', 'waterbeheer', 'coordinator') NOT NULL,
    niveau ENUM('geen', 'lezen', 'schrijven') NOT NULL DEFAULT 'geen',
    PRIMARY KEY (rol_id, domein),
    FOREIGN KEY (rol_id) REFERENCES rollen(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS gebruiker_rollen (
    gebruiker_id INT NOT NULL,
    rol_id INT NOT NULL,
    PRIMARY KEY (gebruiker_id, rol_id),
    FOREIGN KEY (gebruiker_id) REFERENCES gebruikers(id) ON DELETE CASCADE,
    FOREIGN KEY (rol_id) REFERENCES rollen(id) ON DELETE CASCADE
);

-- Generieke configuratie (sleutel/waarde). Beheerbaar door Administrator.
CREATE TABLE IF NOT EXISTS configuratie (
    sleutel       VARCHAR(64)  NOT NULL PRIMARY KEY,
    waarde        VARCHAR(255) NOT NULL,
    omschrijving  VARCHAR(255) NULL,
    type          VARCHAR(20)  NOT NULL DEFAULT 'tekst',
    bijgewerkt_op TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Vrij-tekst logboek voor waterbeheerders
CREATE TABLE IF NOT EXISTS logboek (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datum DATE NOT NULL,
    tijdstip DATETIME NOT NULL,
    auteur VARCHAR(100) NULL,
    tekst TEXT NOT NULL,
    UNIQUE KEY uniek_logboek (datum, tijdstip),
    INDEX idx_logboek_datum (datum)
);

-- Vrij-tekst logboek voor coördinatoren
CREATE TABLE IF NOT EXISTS coordinatoren_logboek (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datum DATE NOT NULL,
    tijdstip DATETIME NOT NULL,
    auteur VARCHAR(100) NULL,
    tekst TEXT NOT NULL,
    UNIQUE KEY uniek_coord_logboek (datum, tijdstip),
    INDEX idx_coord_logboek_datum (datum)
);

-- Dagelijkse temperatuur en bezoekers voor coördinatoren. Het cumulatieve
-- bezoekersaantal sinds de laatste spoelbeurt wordt op aanvraag berekend
-- (ActiesRepository::berekenSpoelbeurt, som van bezoekers_vandaag) en niet
-- opgeslagen; er is dus géén kolom bezoekers_totaal_spoelbeurt.
CREATE TABLE IF NOT EXISTS coordinatoren_daggegevens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datum DATE NOT NULL UNIQUE,
    lucht_temperatuur DECIMAL(4,1) NULL,
    bezoekers_vandaag INT NULL,
    auteur VARCHAR(100) NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Wie was er op dienst bij waterbeheer (altijd 2 personen; één logt in, de ander
-- wordt handmatig ingevuld). Eén record per dag.
CREATE TABLE IF NOT EXISTS waterbeheer_dienst (
    datum DATE PRIMARY KEY,
    dienst_1 VARCHAR(100) NULL,
    dienst_2 VARCHAR(100) NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Dagelijkse checklijst voor coördinatoren
CREATE TABLE IF NOT EXISTS coordinatoren_checklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datum DATE NOT NULL UNIQUE,
    proef_waterspeel TINYINT(1) NOT NULL DEFAULT 0,
    proef_spraypark  TINYINT(1) NOT NULL DEFAULT 0,
    proef_douches    TINYINT(1) NOT NULL DEFAULT 0,
    proef_glijbaan   TINYINT(1) NOT NULL DEFAULT 0,
    auteur VARCHAR(100) NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel voor acties/alarmen
CREATE TABLE IF NOT EXISTS acties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bad_id INT NOT NULL,
    datum DATE NOT NULL,
    beschrijving VARCHAR(255) NOT NULL,
    actie_type VARCHAR(50) NOT NULL,
    opgelost BOOLEAN DEFAULT FALSE,
    opgelost_op DATETIME NULL,
    opgelost_door VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bad_id) REFERENCES baden(id),
    UNIQUE KEY unieke_actie (bad_id, datum, actie_type)
);

-- Tabel voor de tekst-sjablonen van acties. De waterbeheerder kan de
-- formulering van een actie aanpassen zonder code te wijzigen. Plaatshouders
-- tussen accolades worden bij het genereren ingevuld: {bad} = badnaam,
-- {drempel} = grenswaarde, {waarde} = gemeten waarde.
CREATE TABLE IF NOT EXISTS actie_teksten (
    actie_sleutel VARCHAR(60) PRIMARY KEY,
    sjabloon      VARCHAR(255) NOT NULL,
    omschrijving  VARCHAR(255) NULL
);

-- GEEN seed hier. De standaard actie-sjablonen staan in code
-- (ActieTekstenRepository::DEFAULT_ACTIE_TEKSTEN) en zijn de bron van waarheid.
-- Deze tabel bevat alléén door de beheerder gewijzigde overrides; leeg = alle
-- sjablonen op hun code-default. De tabel vooraf vullen met kopieën van de defaults
-- zou zinloze no-op-overrides maken die latere wijzigingen aan de code-defaults
-- zouden maskeren.

-- Tabel voor rondetaken (dagelijkse onderhoudstaken tijdens een ronde).
-- De takencatalogus zelf staat in code (RondetakenRepository); hier worden
-- alleen de afgevinkte taken per dag bewaard. Een nieuwe dag = geen rijen =
-- alles weer onafgevinkt.
CREATE TABLE IF NOT EXISTS rondetaken_voltooid (
    id INT AUTO_INCREMENT PRIMARY KEY,
    taak_sleutel VARCHAR(50) NOT NULL,
    datum DATE NOT NULL,
    voltooid_op DATETIME NULL,
    voltooid_door VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unieke_rondetaak (taak_sleutel, datum)
);

-- Verbruik diep/ondiep: water, elektriciteit, gas, chemicaliën (gehele getallen)
CREATE TABLE IF NOT EXISTS verbruik_diep_ondiep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datum DATE NOT NULL UNIQUE,
    Flocculant INT NULL,
    water_diep INT NULL,
    water_ondiep INT NULL,
    water_totaal INT NULL,
    elektriciteit_nacht INT NULL,
    elektriciteit_dag INT NULL,
    gas INT NULL,
    chemicalien_chloor INT NULL,
    chemicalien_zwavelzuur INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    versie INT NOT NULL DEFAULT 0,
    auteur VARCHAR(100) NULL,
    bijgewerkt_op TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Verwarmingssysteem: ketelstatus en inspecties
CREATE TABLE IF NOT EXISTS verwarmings_systeem_diep_ondiep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datum DATE NOT NULL UNIQUE,
    verwarming_status_1 BOOLEAN DEFAULT FALSE,
    verwarming_status_2 BOOLEAN DEFAULT FALSE,
    verwarming_status_3 BOOLEAN DEFAULT FALSE,
    verwarming_status_4 BOOLEAN DEFAULT FALSE,
    verwarming_druk_ok BOOLEAN DEFAULT FALSE,
    verwarming_visuele_controle BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    versie INT NOT NULL DEFAULT 0,
    auteur VARCHAR(100) NULL,
    bijgewerkt_op TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
