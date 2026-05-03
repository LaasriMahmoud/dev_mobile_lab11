# 📍 TP 11 — Localisation d'un smartphone et envoi des coordonnées vers un serveur distant

## 🎯 Objectifs Pédagogiques
- Récupérer dynamiquement la **latitude** et la **longitude** d'un smartphone Android.
- Comprendre et manipuler les **permissions Android** liées à la localisation et au réseau (Internet & État du téléphone).
- Envoyer des données depuis une application Android vers un service web distant (Backend PHP).
- Enregistrer ces coordonnées dans une **base de données MySQL**.
- Structurer de manière claire et orientée objet un mini-projet connecté (Mobile + Serveur).

---

## 🏗️ Architecture du Projet

L'architecture est découpée en deux grandes entités indépendantes qui communiquent via des requêtes HTTP (`POST`).

### 1. 🖥️ Partie Serveur (Backend)
- Une **base de données MySQL** (`localisation`) pour stocker les enregistrements GPS.
- Des **scripts PHP orientés objet** (Classes métier, Gestionnaire DAO, Service PDO) pour insérer les données en toute sécurité.
- Un point d'entrée HTTP (`createPosition.php`) pour recevoir les `POST` du smartphone.

### 2. 📱 Partie Mobile (Android)
- Déclaration des **Permissions** (GPS, Internet, IMEI).
- Utilisation de `LocationManager` pour capter les variations GPS.
- Utilisation de la bibliothèque `Volley` pour acheminer les requêtes asynchrones en arrière-plan.

---

## 💻 1. Partie Serveur — Base de Données et Développement PHP

### Étape 1 : Création de la structure et de la Base de données

Nous avons créé une base de données `localisation` et généré la table `position` avec la requête SQL suivante (`backend/localisation.sql`) :

```sql
CREATE DATABASE IF NOT EXISTS localisation
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE localisation;

CREATE TABLE position (
    id INT AUTO_INCREMENT PRIMARY KEY,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    date_position DATETIME NOT NULL,
    imei VARCHAR(50) NOT NULL
);
```

Cette table contiendra les coordonnées précises récupérées, avec un identifiant unique d'appareil (l'IMEI) et la date d'envoi.

### Étape 2 : Architecture du Backend PHP

Pour un code professionnel et réutilisable, les fichiers sont divisés par responsabilité dans le dossier `backend/` :
- `classe/Position.php` : Objet métier représentant notre table.
- `connexion/Connexion.php` : Pilote PDO assurant la sécurité de l'accès à la BDD.
- `dao/IDao.php` : L'interface définissant les méthodes CRUD.
- `service/PositionService.php` : L'implémentation qui insère l'objet `Position` dans la table `position`.
- `createPosition.php` : Le script principal qui réceptionne la requête `POST` émise par Volley (Android).

**Exemple d'insertion sécurisée via requête préparée (`PositionService.php`) :**
```php
public function create($position) {
    $sql = "INSERT INTO position(latitude, longitude, date_position, imei)
            VALUES(:latitude, :longitude, :date_position, :imei)";
    $stmt = $this->connexion->getConnexion()->prepare($sql);
    $stmt->execute([
        ':latitude' => $position->getLatitude(),
        ':longitude' => $position->getLongitude(),
        ':date_position' => $position->getDatePosition(),
        ':imei' => $position->getImei()
    ]);
}
```

---

## 📱 2. Partie Mobile — Développement Android

L'application Android sert de capteur physique pour alimenter le serveur. Le projet est disponible dans le dossier `android/`.

### Étape 1 : Autorisations Requises

Dans le fichier `AndroidManifest.xml`, 4 permissions clés sont ajoutées pour autoriser le matériel à agir :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" /> <!-- Précision GPS -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" /> <!-- Précision Réseau -->
<uses-permission android:name="android.permission.INTERNET" /> <!-- Envoi HTTP -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" /> <!-- Récupération de l'IMEI -->
```

### Étape 2 : L'Écoute de Position (LocationManager)

Dans `MainActivity.java`, on initialise l'écoute GPS avec les paramètres suivants :
- Un appel exclusif au fournisseur matériel `LocationManager.GPS_PROVIDER`.
- Un rafraîchissement au minimum toutes les `60000` ms (1 minute).
- Ou un déclenchement forcé si l'utilisateur se déplace de plus de `150` mètres.

```java
locationManager.requestLocationUpdates(
    LocationManager.GPS_PROVIDER,
    60000,
    150,
    new LocationListener() {
        @Override
        public void onLocationChanged(Location location) {
            // Traitement de la nouvelle position et appel au serveur
            latitude = location.getLatitude();
            longitude = location.getLongitude();
            addPosition(latitude, longitude);
        }
    }
);
```

### Étape 3 : L'Envoi des Données au Serveur avec Volley

À chaque mouvement capté, la méthode `addPosition(lat, lon)` est appelée. Elle construit une `StringRequest` de type `POST`. 
On y injecte les variables dynamiquement :

```java
@Override
protected Map<String, String> getParams() throws AuthFailureError {
    HashMap<String, String> params = new HashMap<>();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    params.put("latitude", String.valueOf(lat));
    params.put("longitude", String.valueOf(lon));
    params.put("date_position", sdf.format(new Date()));
    params.put("imei", telephonyManager.getDeviceId());

    return params;
}
```
*(Remarque : N'oubliez pas de modifier la variable `insertUrl` dans MainActivity avec l'adresse IP locale de votre serveur)*

---

## ⚙️ Bonnes Pratiques de Test

1. **Réseau commun :** Le téléphone/émulateur et le PC faisant tourner WAMP/XAMPP doivent être sur la même passerelle locale. L'IP doit correspondre à votre machine `192.168.x.x` (pas `localhost` !).
2. **Droits Android :** Toujours vérifier les consentements utilisateurs (Permissions Dialog) au démarrage de l'appli depuis Android 6.0.
3. **Tester Postman :** Assurez-vous d'abord que votre fichier PHP serveur accepte l'enregistrement d'une requête factice via Postman avant de débugger Android.
4. **Mock de position :** Sur un émulateur de type Android Studio AVD, l'insertion de position doit être simulée en utilisant les `Extended Controls` (Trois petits points sur le côté) -> onglet `Location` pour altérer virtuellement la position GPS !
