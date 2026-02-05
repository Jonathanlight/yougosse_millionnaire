# Configuration Firebase pour Yougosse Millionnaire

## 1. Prerequisites

- Flutter SDK installe
- Compte Firebase
- FlutterFire CLI installe: `dart pub global activate flutterfire_cli`

## 2. Configuration Firebase Console

### 2.1 Creer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Creer un nouveau projet "yougosse-millionnaire"
3. Activer Google Analytics (optionnel)

### 2.2 Activer Authentication

1. Dans le menu Firebase, aller a Authentication > Sign-in method
2. Activer les providers:
   - **Email/Password**: Activer
   - **Google**: Activer et configurer
   - **Apple**: Activer (necessite Apple Developer Account)

### 2.3 Configurer Firestore

1. Aller a Firestore Database
2. Creer une base de donnees en mode production
3. Copier les regles de securite depuis `firestore.rules`

### 2.4 Activer Google Sign-In

1. Dans Firebase Console > Authentication > Sign-in method > Google
2. Activer et copier le **Web client ID**
3. Configurer les SHA-1/SHA-256 pour Android (voir section Android)

## 3. Configuration FlutterFire

```bash
# Dans le dossier du projet
flutterfire configure --project=yougosse-millionnaire
```

Cela genere automatiquement:
- `lib/firebase_options.dart`
- Configuration native pour iOS/Android

## 4. Configuration Android

### 4.1 SHA-1/SHA-256 pour Google Sign-In

```bash
# Debug key
cd android
./gradlew signingReport
```

Copier les fingerprints dans Firebase Console > Project Settings > Your apps > Android

### 4.2 Fichier google-services.json

Telecharger depuis Firebase Console et placer dans `android/app/`

### 4.3 Modifier android/build.gradle

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 4.4 Modifier android/app/build.gradle

```gradle
plugins {
    id 'com.google.gms.google-services'
}

android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## 5. Configuration iOS

### 5.1 GoogleService-Info.plist

Telecharger depuis Firebase Console et ajouter dans Xcode:
`ios/Runner/GoogleService-Info.plist`

### 5.2 Modifier ios/Runner/Info.plist

Ajouter pour Google Sign-In:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.VOTRE_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 5.3 Configuration Apple Sign-In

1. Dans Apple Developer Portal, activer "Sign In with Apple" pour l'App ID
2. Creer un Service ID pour le web
3. Configurer les URLs de callback dans Firebase

### 5.4 Entitlements

Dans Xcode, ajouter la capability "Sign In with Apple"

## 6. Configuration google_sign_in

### 6.1 iOS

Dans `ios/Runner/Info.plist`, ajouter:

```xml
<key>GIDClientID</key>
<string>VOTRE_IOS_CLIENT_ID</string>
```

### 6.2 Android

Le client ID est automatiquement lu depuis `google-services.json`

## 7. Deployer les regles Firestore

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Connexion
firebase login

# Initialiser le projet
firebase init firestore

# Deployer les regles
firebase deploy --only firestore:rules
```

## 8. Modifier main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

## 9. Test de la configuration

```bash
# Lancer l'app
flutter run

# Verifier les logs pour:
# - [FirebaseInit] Initialisation complete
# - [AuthService] Initialise
# - [ConnectivityService] Initialise
```

## 10. Structure Firestore

```
users/
  {userId}/
    - email: string
    - displayName: string
    - photoUrl: string
    - createdAt: timestamp
    - lastLoginAt: timestamp
    - totalGamesCreated: number
    - authProvider: string
    - isAnonymous: boolean

    games/
      {gameId}/
        - name: string
        - createdAt: timestamp
        - updatedAt: timestamp
        - lastPlayedAt: timestamp
        - version: string
        - syncTimestamp: number
        - player: {
            money: number
            xp: number
            gems: number
            ...
          }
        - city: {
            buildings: []
            roads: []
            ...
          }
        - cityName: string
```

## 11. Troubleshooting

### Erreur Google Sign-In sur Android

- Verifier SHA-1 dans Firebase Console
- Regenerer google-services.json
- Clean build: `flutter clean && flutter pub get`

### Erreur Apple Sign-In

- Verifier les entitlements dans Xcode
- Verifier Service ID dans Apple Developer Portal
- Verifier configuration dans Firebase Console

### Erreur Firestore Permission Denied

- Verifier que les regles sont deployees
- Verifier que l'utilisateur est authentifie
- Verifier les chemins des documents

### Mode hors-ligne

Le jeu fonctionne en mode hors-ligne grace a:
- Cache Hive pour les donnees locales
- Queue de synchronisation pour les operations en attente
- Retry automatique lors de la reconnexion
