# Tesztjegyzőkönyv – NomNom

Ez a dokumentum a NomNom receptmegosztó alkalmazás legfontosabb funkcióinak
– regisztráció / bejelentkezés, recept létrehozás, like és komment, csoportkezelés –
tesztelését foglalja össze.

Felelős: Kiss Tamás Ferenc és Mester Dániel

---

## 1. Teszteljárások (TP)

### TP-01 – Felhasználói regisztráció és bejelentkezés

**Cél:**  
Ellenőrizni, hogy az új felhasználó létrehozása és bejelentkezése helyesen működik.

**Lépések (összefoglalva):**
1. NomNom app indítása, **Register** képernyő megnyitása.
2. Regisztráció érvényes adatokkal.
3. Ugyanazon adatokkal bejelentkezés a **Login** képernyőn.
4. Ellenőrizni, hogy a felhasználó a feed főképernyőre kerül.

---

### TP-02 – Recept létrehozása és megjelenítése

**Cél:**  
Új recept létrehozása, megjelenítése a feedben és a profiloldalon.

**Lépések (összefoglalva):**
1. Bejelentkezett felhasználóval az **Recept összeállító** képernyő megnyitása.
2. Cím, leírás, elkészítési idő és hozzávalók megadása.
3. Kép csatolása (opcionális).
4. Recept mentése.
5. Ellenőrizni, hogy:
   - a recept megjelenik a **What’s New és Discover** feedben,
   - a recept látszik a felhasználó **profilján** is.

---

### TP-03 – Like és komment funkció

**Cél:**  
Poszt kedvelése, komment írása a feedből, azonnali frissítéssel.

**Lépések (összefoglalva):**
1. Feed megnyitása, tetszőleges poszt kiválasztása.
2. Like ikon megnyomása (kedvelés).
3. Komment ikon megnyomása, komment küldése az alsó komment panelről.
4. Ellenőrizni, hogy:
   - a like és komment szám **azonnal frissül**,
   - a komment megjelenik a listában.

---

### TP-04 – Csoporthoz csatlakozás és elhagyás

**Cél:**  
Nyilvános csoporthoz csatlakozás, a tagszám és státusz helyes frissülésével.

**Lépések (összefoglalva):**
1. **Groups / Csoportok** képernyő megnyitása.
2. Egy nyilvános csoport kiválasztása, **Join** gomb megnyomása.
3. Ellenőrizni, hogy a gomb **Joined** állapotra vált, a taglétszám nő.
4. Ellenőrizni, hogy a gomb visszavált **Join**-ra, a taglétszám csökken.

---

## 2. Tesztesetek (TC)

### TC-01 – Sikeres regisztráció és bejelentkezés
- **TP:** TP-01  
- **Bemenet:**  
  - Email: `gordon@ramsay.com`  
  - Felhasználónév: `Gordnon Ramsay`  
  - Jelszó: `test123`  
- **Lépések:**  
  1. Regisztráció a fenti adatokkal.  
  2. Bejelentkezés ugyanilyen adatokkal.  
- **Elvárt eredmény:**  
  - Nincs hibaüzenet.  
  - A felhasználó a feed főképernyőre kerül.  

---

### TC-02 – Regisztráció meglévő email címmel
- **TP:** TP-01  
- **Bemenet:**  
  - Email: `gordon@ramsay.com` (már regisztrálva)  
  - Felhasználónév: `Ramsay Bolton`  
  - Jelszó: `test123`  
- **Lépések:**  
  1. Regisztráció indítása ugyanazzal az email címmel.  
- **Elvárt eredmény:**  
  - Hibaüzenet: az email már használatban van.  
  - Nincs új felhasználói fiók létrehozva.  

---

### TC-03 – Recept létrehozása képpel

- **TP:** TP-02  
- **Bemenet:**  
  - Cím: `Bread and fish`  
  - Leírás: rövid leírás  
  - Előkészítési idő: `20 perc`  
  - Hozzávalók: legalább 3 sor  
  - Kép: egy fotó kiválasztva a galériából  
- **Lépések:**  
  1. Új recept kitöltése a fenti adatokkal.  
  2. **Create / Publish** gomb megnyomása.  
- **Elvárt eredmény:**  
  - Sikeres mentés (nincs hiba).  
  - A recept megjelenik a feedben.  
  - A recept látszik a profil „My recipes” részében is.  

---

### TC-04 – Like és komment egy poszton

- **TP:** TP-03  
- **Bemenet:**  
  - Egy meglévő poszt a feedben.  
  - Komment: `I'm already hungry`  
- **Lépések:**  
  1. Like ikon megnyomása.  
  2. Komment ikon megnyomása.  
  3. Komment beírása és elküldése.  
- **Elvárt eredmény:**  
  - Az első likenál a like szám +1, ikon teli.   
  - A komment **azonnal** megjelenik a listában.  
  - A komment számláló 1-gyel nő.  

---

### TC-05 – Csoporthoz csatlakozás

- **TP:** TP-04  
- **Bemenet:**  
  - Egy nyilvános csoport a listában (pl. „Midnight Snack Society”).  
- **Lépések:**  
  1. Csoport megnyitása, **Join** megnyomása.  
  2. Visszalépés „My Groups” listára, ellenőrzés.  
  3. Ugyanazon csoport megnyitása, **Leave** megnyomása.  
- **Elvárt eredmény:**  
  - Join után a gomb **Joined** lesz, taglétszám +1.  
  - A csoport megjelenik a „My Groups” listában.  
  - Leave után a gomb visszaáll **Join**-ra, taglétszám -1, a csoport eltűnik a „My Groups”-ból.  

---

## 3. Rövid tesztriport (összefoglaló)

- **TR-01 (TC-01):**  
  - Eredmény: Sikeres.  
  - Megjegyzés: Új felhasználó gond nélkül regisztrálható és bejelentkezik, a feed megjelenik.  

- **TR-02 (TC-02):**  
  - Eredmény: Sikeres (elvárt hiba).  
  - Megjegyzés: A rendszer megakadályozza az azonos email cím többszöri regisztrációját.  

- **TR-03 (TC-03):**  
  - Eredmény: Sikeres.  
  - Megjegyzés: A létrehozott recept mind a feedben, mind a profil oldalon megjelenik.  

- **TR-04 (TC-04):**  
  - Eredmény: Sikeres.  
  - Megjegyzés: A like és komment funkció azonnali UI frissítéssel működik, nincs app crash.  

- **TR-05 (TC-05):**  
  - Eredmény: Sikeres.  
  - Megjegyzés: A csoport tagság állapota (Join, taglétszám) helyesen frissül, a „My Groups” nézet konzisztens.  

---
