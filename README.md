# MediMind

**Therapietrouw simpel gemaakt voor iedereen.** MediMind is een persoonlijke medicatie-assistent die verder gaat dan een simpele herinnering. Door de inzet van OCR-technologie en AI helpen we gebruikers hun medicatie veilig, tijdig en met meer zelfvertrouwen te beheren.

[![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Het Probleem
Wist je dat wereldwijd **30% tot 50%** van de patiënten hun medicatie niet correct inneemt? 
Of het nu gaat om een student met een onregelmatig schema of een oudere die meerdere medicijnen moet combineren: de gevolgen van gebrekkige therapietrouw zijn groot—van vermijdbare ziekenhuisopnames tot miljarden aan extra zorgkosten.

**MediMind lost dit op door organisatie, educatie en motivatie te combineren in één toegankelijke app.**

---

## Key Features (MVP)

* **Scan & Go (OCR):** Geen gedoe met typen. Maak een foto van je medicatiedoosje en de app vult automatisch de details in.
* **Educatieve AI-Chatbot:** Stel vragen zoals *"Mag ik dit innemen op een lege maag?"* en krijg direct een begrijpelijk antwoord (zonder medisch advies te vervangen).
* **Dynamisch Dagoverzicht:** Een heldere tijdlijn die de cognitieve belasting verlaagt. Je ziet in één oogopslag wat je al hebt ingenomen en wat er nog komt.
* **Toegankelijkheid Eerst:** Ontworpen met grote klikoppervlakken, hoog contrast en Text-to-Speech ondersteuning voor minder digivaardige gebruikers.
* **Het Vangnet:** Als een cruciale dosis wordt gemist, krijgt een vooraf ingestelde contactpersoon een seintje.

---

## 🛠 Tech Stack

| Component | Technologie |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Backend/Auth** | Firebase (Firestore, Cloud Functions) |
| **OCR Engine** | EMI API |
| **AI Engine** | LM Studio |
| **Design** | Visily |

---

## Project Structuur

Een kort overzicht van hoe de applicatie is opgebouwd:

* `/lib/models`: De data-modellen voor medicatie en gebruikers.
* `/lib/screens`: Alle UI schermen (Home, Scan, Chat, etc.).
* `/lib/services`: API calls en Firebase integratie.
* `/functions`: De backend logica (Node.js) voor AI en mail-notifications.

---

## Installatie

Wil je MediMind lokaal draaien? Volg deze stappen:

1.  **Clone de repo**
    ```bash
    git clone
