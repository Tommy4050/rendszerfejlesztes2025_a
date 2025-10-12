# NOM NOM Projektterv 2025

## 1. Összefoglaló

Az egészséges étkezés napjainkban különösen fontosággla bír, honnan
származik egy adott élelmiszer, hány kalóriát tartalmaz milyen tápanyag
értékkel bír, illetve mi készíthető ezen termékekből. Ezen infromációk
megekeresése sok időt és energiát venne igénybe és egyáltalán nem
garantált, hogy a kívánt sikert hozza. Éppen ezért a projektünk célja,
egy olyan mobilos recept megosztó applikáció lefejlesztése, ami mindezen
információkat egy helyen tartalmazza, valamint lehetőséget ad ezen
élelmiszerkből recepteket összeállítani és ezeket megosztani más
felhasználókkal. A cél, hogy mindezen funkciókat a felhasználó egy
letisztult és könnyen használható applikációban tudja megtenni.

## 2. A projekt bemutatása

A projektterv a NOM NOM nevű projektet mutatja be, amely
**2025.09.22.-től 2025.11.24-ig** tart összesen **64 napon** keresztül
fog tartani. A projekten két fejlesztő fog dolgozni, a fejlesztés
állapotáról négy alakalommal fogjuk prezentálni a megrendelőnek a
projekt stabil előrehaladása érdekében.

### 2.1. Rendszerspecifikáció

Az applikációnak képensnek kell a felhasználók **regisztrálására** azaz
felhasználói fiók létrehozására illetve az ebbe való **belépésre**. A
felhsználó képes más felhasználókat **követni és csoportokhoz
csatlakozni** ilyenkor a **feed-en** jelennek meg a más felhasználók
által vagy csoportkoban megosztott posztok. A csoportok szabályozhatják,
hogy milyen tartalom jelenhet meg az adott oldalon, ezt a receptnél
megadott kategória/ketegóriák száblyozásával tehetik meg *pl:
laktózmentes, gluténmentes, vegán stb.*, de nem kötelező. Továbbá a
felhasználó képes saját **recepteket létrehozni**, itt lehetősége van
megadni a hozzávalókat és azok mennyiségét *pl.: - 500ml Mizo uht tej
1,5% laktózmentes*. A hozzávalók megadásánál a felhasználó egy
keresőmezőbe írhatja be annak nevét, majd egy legőrdülő listából ki tuja
választani, a pontos hozzávalót. A recept összeállítását követően a
teljes recept tápértéke megjelenítésre kerűl. A felhsználónak lehetősége
van ezeket a **recepteket megosztani** minden ismerősével, egy csoportba
posztolni vagy privátra állítani.

### 2.2. Funkcionális követelmények

- Felhasználói fiók létrehozása (regisztáció, belépés, ismerősök
  jelölése) (CRUD)
- Receptek létrehozása (hozzávalók keresése, tápértékek összegzése)
  (CRUD)
- Csoportok (CRUD)
- Feed összeállítása (receptek megosztása) (CRUD)

### 2.3. Nem funkcionális követelmények

- Platform független legyen
- Egyzerű letisztult megjelenés
- API hívások optimalizálása
- Érzékeny adatok biztonságos tárolása

## 3. Költség- és erőforrás-szükségletek

Az erőforrásigényünk összesen 38 személynap, átlagosan 19 személynap/fő.

A rendelkezésünkre áll összesen 2 \* 70 = 140 pont.

## 4. Szervezeti felépítés és felelősségmegosztás

A projekt megrendelője Héger Gábor György. A NOM NOM projektet a
projektcsapat fogja végrehajtani, amely jelenleg két fejlesztőből áll. A
csapatban található két kezdő, de lelkes mobil fejlesztő.
- Kiss Tamás Ferenc (lelkes fejlesztő, az Alternatív Gyakornoki program tagja,level 150-es - Super Private ⬆️➡️⬇️⬇️⬇️🛰️💥)
- Mester Dániel (nem csak a nevében)

### 4.1 Projektcsapat

A projekt a következő emberekből áll:

| Név               | Pozíció          | E-mail cím (stud-os)     |
|-------------------|------------------|--------------------------|
| Kiss Tamás Ferenc | Projektmenedzser | h049668@stud.u-szeged.hu |
| Mester Dániel     | Projekt tag      | igen                     |

## 5. A munka feltételei

### 5.1. Munkakörnyezet

A projekt a következő munkaállomásokat fogja használni a munka során:

- Munkaállomások: 2 db, MacBook Air M1 és Windows 11-es operációs
  rendszerrel
- MacBook Air (CPU: M1, RAM: 8 GB)
- Dani gépe

A projekt a következő technológiákat/szoftvereket fogja használni a
munka során:

- [Flutter](https://flutter.dev/)
- [Riverpods](https://riverpod.dev/)
- [Image Picker](https://pub.dev/packages/image_picker)
- [Express.js](https://expressjs.com/)
- [MongoDB](https://www.mongodb.com/)
- [JSON Web Tokens](https://www.jwt.io/)
- [Open Food Facts API](https://world.openfoodfacts.org/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Git verziókövető](https://git-scm.com/),
  [GitHub](https://github.com/)

### 5.2. Rizikómenedzsment

| Kockázat | Leírás | Valószínűség | Hatás |
|----|----|----|----|
| Betegség | Súlyosságtól függően hátráltatja vagy bizonyos esetekben teljes mértékben korlátozza a munkavégzőt, így az egész projektre kihatással van. Megoldás: a feladatok átcsoportosítása | közepes | közepes |
| Kommunikációs fennakadás a csapattagokkal | A csapattagok között nem elégséges az információ áramlás, nem pontosan, esetleg késve vagy nem egyértelműen tájékoztatjuk egymást. Megoldás: még gyakoribb megbeszélések és ellenőrzések | kis | erős |
| Egyéb tanúlmányok és gyakornoki program | Zárthelyi dolgozatok illetve, az alternatív gyakornoki programban való részvétel, hátráltathatja a feladatok időbeli elvégzését. Megoldás: A feladatokra szánt idő átszervezése szükség esetén a csapattárs feladatában való aktív segítség nyújtása. | közepes | erős |

## 6. Jelentések

### 6.1. Munka menedzsment

A munkát Kiss Tamás Ferenc koordinálja. Fő feladata, hogy folyamatosan
egyeztessen a csapatársával az előrehaladásról és a fellépő
problémákról, a megoldásban is segítséget nyújhat a projekt csúszásának
elkerülése végett. További feladata a heti szinten tartandó
csapatgyűlések időpontjának és helyszínének leszervezése, erről minden
lehetséges eszközzel tájékoztatja a projektcsapatot.

### 6.2. Csoportgyűlések

A projekt hetente ülésezik, hogy megvitassák az azt megelőző hét
problémáit pl.: *Merge conflict*, illetve hogy megbeszéljék a következő
hét feladatait. A megbeszélésről minden esetben memó készül.

1.  megbeszélés:

- Időpont: 2025.10.11.
- Hely: Discord
- Résztvevők: Kiss Tamás Ferenc, Mester Dániel
- Érintett témák: Projekttéma kiválasztása, Isemrkedés a használni
  kívánt technológiákkal, projektterv elkészítése.

### 6.3. Minőségbiztosítás

Az elkészült terveket a csapattársal együtt átnézzük, hogy megfelel-e a
specifikációbna leírtaknak, illetve az egyes digrammokkal összhangban
van-e. Az applikáció prototípusainak bemutatása előtt, meggyőződünk
annak helyes működéséről a tesztlési dokumentumban leírtak szerint.
További lehetőségek unit tesztek írása, valamint a kód közös átnézése a
csapattárssal. A végső leadás előtt az applikáció minőségét ellenőrizni
kell és, ha szükséges az esetleges hibák javítása. Az alábbi lehetőségek
vannak a szoftver megfelelő minőségének biztosítására: - Specifikáció és
tervek átnézése (kötelező) - Teszttervek végrehajtása (kötelező) - Unit
tesztek írása (választható) - Kód átnézése (választható)

### 6.4. Átadás, eredmények elfogadása

A projekt eredményeit a megrendelő, Héger Gábor György fogja elfogadni.
A projektterven változásokat csak a megrendelő engedélyével lehet tenni.
A projekt eredményesnek bizonyul, ha specifikáció helyes és határidőn
belül készül el. Az esetleges késések pontlevonást eredményeznek. Az
elfogadás feltételeire és beadás formájára vonatkozó részletes leírás a
következő honlapon olvasható: https://okt.inf.szte.hu/rf1/

### 6.5. Státuszjelentés

Minden mérföldkő leadásnál a projekten dolgozók jelentést tesznek a
mérföldkőben végzett munkájukról a a megadott sablon alapján. A
gyakorlatvezetővel folytatott csapatmegbeszéléseken a csapat áttekintik
és felmérik az eredményeket és teendőket. Továbbá gazdálkodnak az
erőforrásokkal és szükség esetén a megrendelővel egyeztetnek a
projektterv módosításáról.

## 7. A munka tartalma

### 7.1. Tervezett szoftverfolyamat modell és architektúra

A fejlesztés során az agilis modellt alkalmazzuk, az esetlegesen
felerülő problémák, illetve változások megfelelő és rugalmas kezelése
érdekében.

Az applikáció az MVC (modell-view-controller) felépítést követi, a
szerver és a kliens függetlenek, csupán API végpontok segítségével
kommunikálnak.

### 7.2. Átadandók és határidők

A főbb átadandók és határidők a projekt időtartama alatt a következők:

| Szállítandó | Neve | Határideje |
|:--:|:--:|:--:|
| D1 | Projektterv és Gantt chart, prezentáció, egyéni jelentés | 2025-10-13 |
| P1+D2 | UML, adatbázis- és képernyőtervek, prezentáció, egyéni jelentés | 2025-10-27 |
| P1+D3 | Prototípus I. és tesztelési dokumentáció, egyéni jelentés | 2025-11-10 |
| P2+D4 | Prototípus II. és frissített tesztelési dokumentáció, egyéni jelentés | 2025-11-24 |

    D - dokumentáció, P - prototípus

## 8. Feladatlista

A következőkben a tervezett feladatok részletes összefoglalása
található.

### 8.1. Projektterv (1. mérföldkő)

Ennek a feladatnak az a célja, hogy megvalósításhoz szükséges lépéseket,
az erőforrásigényeket, az ütemezést, a felelősöket és a feladatok
sorrendjét meghatározzuk, majd vizualizáljuk Gantt diagram segítségével.

Részfeladatai a következők:

#### 8.1.1. Projektterv kitöltése

Felelős: Kiss Tamás Ferenc, Mester Dániel

Tartam: 2 nap

Erőforrásigény: 1 személynap/fő

#### 8.1.2 Gantt diagram elkészítése

Felelős: Kiss Tamás Ferenc

Tartam: 2 nap

Erőforrásigény: 0.5 személynap

### 8.2. UML és adatbázis- és képernyőtervek (2. mérföldkő)

Ennek a feladatnak az a célja, hogy a rendszerarchitektúrát, az
adatbázist és mobilos alkalmazás kinézetét megtervezzük.

Részfeladatai a következők:

#### 8.2.1. Use Case diagram

Felelős: Kiss Tamás Ferenc

Tartam: 2 nap

Erőforrásigény: 1 személynap

#### 8.2.2. Class diagram

Felelős: Mester Dániel

Tartam: 4 nap

Erőforrásigény: 2 személynap

#### 8.2.3. Sequence diagram

Felelős: Mester Dániel

Tartam: 3 nap

Erőforrásigény: 2 személynap

#### 8.2.4. Egyed-kapcsolat diagram adatbázishoz

Felelős: Kiss Tamás Ferenc

Tartam: 2 nap

Erőforrásigény: 1 személynap

#### 8.2.5. Package diagram

Felelős: Mester Dániel

Tartam: 2 nap

Erőforrásigény: 0.5 személynap

#### 8.2.6. Képernyőtervek

Felelős: Kiss Tamás Ferenc

Tartam: 3 nap

Erőforrásigény: 1 személynap

#### 8.2.7. Bemutató elkészítése

Felelős: Kiss Tamás Ferenc

Tartam: 1 nap

Erőforrásigény: 0.5 személynap

### 8.3. Prototípus I. (3. mérföldkő)

Ennek a feladatnak az a célja, hogy egy működő prototípust hozzunk
létre, ahol a vállalt funkcionális követelmények nagy része már
prezentálható állapotban van.

Részfeladatai a következők:

#### 8.3.1. Projektmappa kialakítása(backend frontend) szükséges ezközök technológiák telepítése

Felelős: Kiss Tamás Ferenc

Tartam: 1 nap

Erőforrásigény: 1 személynap

#### 8.3.2 Mongodb-vel való összekapcsolás

Felelős: Mester Dániel

Tartam: 2 nap

Erőforrásigény: 1 személynap

#### 8.3.3 (API)-val való kapcsolat létesítés

Felelős: Kiss Tamás Ferenc

Tartam: 2 nap

Erőforrásigény: 1 személynap

#### 8.3.4. - Felhasználói fiók létrehozása (regisztáció, belépés, ismerősök jelölése) (Backend)

Felelős: Kiss Tamás Ferenc

Tartam: 3 nap

Erőforrásigény: 2 személynap

#### 8.3.5. - Felhasználói fiók létrehozása (regisztáció/belépés, ismerősök jelölése, felhasználói fiók oldal) (Frontend)

Felelős: Mester Dániel

Tartam: 2 nap

Erőforrásigény: 2 személynap

#### 8.3.6. Receptek létrehozása (hozzávalók keresése, tápértékek összegzése) (API) (Backend)

Felelős: Kiss Tamás Ferenc

Tartam: 3 nap

Erőforrásigény: 2 személynap

#### 8.3.7. Receptek létrehozása (Frontend)

Felelős: Mester Dániel

Tartam: 2 nap

Erőforrásigény: 2 személynap

#### 8.3.8. Csoportok (Backend)

Felelős: Kiss Tamás Ferenc

Tartam: 3 nap

Erőforrásigény: 2 személynap

#### 8.3.9. Csoportok (Frontend)

Felelős: Mester Dániel

Tartam: 2 nap

Erőforrásigény: 2 személynap

#### 8.3.10. Feed összeállítása (receptek megosztása) (Backend)

Felelős: Kiss Tamás Ferenc

Tartam: 3 nap

Erőforrásigény: 2 személynap

#### 8.3.10. Feed összeállítása (Frontend)

Felelős: Mester Dániel

Tartam: 2 nap

Erőforrásigény: 2 személynap

### 8.4. Prototípus II. (4. mérföldkő)

Ennek a feladatnak az a célja, hogy az előző mérföldkő hiányzó funkcióit
pótoljuk, illetve a hibásan működő funkciókat és az esetlegesen
felmerülő új funkciókat megvalósítsuk. Továbbá az alkalmazás alapos
tesztelése is a mérföldkőben történik az előző mérföldkőben
összeállított tesztesetek alapján.

Részfeladatai a következők:

#### 8.4.1. Javított minőségű prototípus új funkciókkal

Felelős: Mester Dániel

Tartam: 5 nap

Erőforrásigény: 2.5 személynap

#### 8.4.2. Javított minőségű prototípus javított funkciókkal

Felelős: Kiss Tamás Ferenc

Tartam: 5 nap

Erőforrásigény: 2 személynap

#### 8.4.3. Javított minőségű prototípus a korábbi hiányzó funkciókkal

Felelős: Kiss Tamás Ferenc

Tartam: 3 nap

Erőforrásigény: 1.5 személynap

#### 8.4.4. Felhasználói funkciók tesztelése (Fiók létrehozás, bejelentkezés, fiók törlés)

Felelős: Mester Dániel

Tartam: 1 nap

Erőforrásigény: 0.5 személynap

#### 8.4.5. Receptek létrehozásának tesztelése (receptek összeálllítása, hozzávalók keresése)

Felelős: Kiss Tamás Ferenc

Tartam: 1 nap

Erőforrásigény: 0.5 személynap

#### 8.4.6. Csoport funkciók tesztelése (csoportok létrhozása, posztolási szabályok, csoporton belüli posztolás)

Felelős: Mester Dániel

Tartam: 0.5 nap

Erőforrásigény: 0.5 személynap

#### 8.4.7. Feed tesztelése (receptek megosztása, más felhasználók posztjainak megtekintése )

Felelős: Mester Dániel

Tartam: 1 nap

Erőforrásigény: 0.5 személynap

## 9. Részletes időbeosztás

<figure>
<img src="/Users/tommy4050/Downloads/NomNom_ganttChart.png"
alt="Gantt diagram" />
<figcaption aria-hidden="true">Gantt diagram</figcaption>
</figure>

## 10. Projekt költségvetés

### 10.1. Részletes erőforrásigény (személynap)

| Név               | M1  | M2  | M3  | M4  | Összesen |
|-------------------|-----|-----|-----|-----|----------|
| Kiss Tamás Ferenc | 1.5 | 3.5 | 10  | 4.5 | 19.5     |
| Mester Dániel     | 1   | 4.5 | 9   | 4   | 18.5     |

### 10.2. Részletes feladatszámok

| Név               | M1  | M2  | M3  | M4  | Összesen |
|-------------------|-----|-----|-----|-----|----------|
| Kiss Tamás Ferenc | 2   | 4   | 5   | 3   | 14       |
| Mester Dániel     | 1   | 3   | 5   | 4   | 13       |

### 10.3. Részletes költségvetés

| Név                                | M1    | M2     | M3     | M4     | Összesen  |
|------------------------------------|-------|--------|--------|--------|-----------|
| Maximálisan megszerezhető pontszám | \(7\) | \(20\) | \(25\) | \(18\) | 100% (70) |
| Kiss Tamás Ferenc                  | 7     | 10     | 15     | 13     | 45        |
| Mester Dániel                      | 6     | 10     | 10     | 9      | 35        |

Szeged, 2025.10.11.
