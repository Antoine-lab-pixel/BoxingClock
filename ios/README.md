# BoxingClock — iOS

Version iOS de BoxingClock pour usage personnel. Portage SwiftUI de l'app Android
(Kotlin + Jetpack Compose), sans compte Apple Developer payant.

## Prérequis

- macOS avec Xcode 16 ou plus récent
- Un Apple ID gratuit (la vôtre suffit)
- L'iPhone cible, avec le Mode développeur activé
  (Réglages → Confidentialité et sécurité → Mode développeur — iOS 16+)

## Build

1. Ouvrir `BoxingClock.xcodeproj` dans Xcode.
2. Xcode → Settings → Accounts : ajouter votre Apple ID si ce n'est pas déjà fait.
3. Sélectionner le projet BoxingClock → cible *BoxingClock* → onglet
   *Signing & Capabilities* : cocher *Automatically manage signing* et choisir
   votre *Personal Team*.
4. Brancher l'iPhone, le sélectionner comme destination, puis `Cmd+R`.
5. Au premier lancement, si iOS refuse d'ouvrir l'app :
   Réglages → Général → VPN et gestion d'appareil → approuver votre profil
   développeur.

## Notes importantes

- **Validité 7 jours** : l'app est signée avec un profil gratuit. Au bout de 7
  jours elle refuse de s'ouvrir — rebrancher l'iPhone et `Cmd+R` la renouvelle
  en place (les réglages et presets sont conservés). Compter ~2 minutes par
  semaine.
- **Ne jamais changer le bundle ID** (`com.antoinelabpixel.boxingclock`) : le
  quota gratuit est limité à 10 App IDs / 7 jours.
- **Build plus fluide** : Product → Scheme → Edit Scheme → Run → Info →
  Build Configuration → *Release* (le timer et les animations restent légers).
- Le débogage WiFi est possible après le premier branchement câblé
  (Window → Devices and Simulators → *Connect via network*).

## Comportement audio

Les sons jouent en `AVAudioSession` `.playback` + `.duckOthers` : ils sont
audibles même si l'iPhone est en mode silencieux, et la musique en cours
s'atténue pendant la cloche puis reprend — l'équivalent le plus proche du flux
alarme Android.

## Impact Android / F-Droid

Aucun. F-Droid ne construit que depuis les tags ; ce dossier est inerte pour
Gradle (recette F-Droid : `subdir: app`). La version Android n'est republiée
que lorsqu'un tag `v<version>` est poussé sur `main`.

## Si le projet ne s'ouvre pas dans votre version de Xcode

Le `project.pbxproj` cible Xcode 16+ (groupes synchronisés par dossier). En cas
de problème : File → New → Project → iOS App (nom `BoxingClock`, interface
SwiftUI, langage Swift), puis remplacer le dossier `BoxingClock/` généré par
celui de ce repo et régler la cible : iOS 17+, bundle ID
`com.antoinelabpixel.boxingclock`, orientations portrait + paysage.