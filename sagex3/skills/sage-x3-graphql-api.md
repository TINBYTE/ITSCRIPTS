# Formation API GraphQL dans Sage X3

## 1. Introduction au Sage X3 Builder

- Présentation de l'API GraphQL dans Sage X3
- Terminologie : Node, Property, Collection, Package, Operation, Enum

---

## 2. Exploration des fonctions API dans X3

- Modules API : GESAPACK, GESAWM, GESANODEB, GESAPIOPE, GESAENUMB
- Définition des modèles de données, nœuds et dictionnaires de liaison

---

## 3. Installation et configuration du Dev Pack

- Téléchargement via Sage Community Hub
- Préparation du répertoire Dev (`_X3DEV`)
- Fichier `.nvmrc` et gestion des versions Node.js
- Configuration du fichier `xtrem-config.yml` : connexion SQL, dossier X3, clé secrète
- Installation

---

## 4. Création d'un package personnalisé

- Création d'un code activité et du package associé
- Ajout de champs personnalisés sur une entité standard (ex. : Produits)
- Conventions de nommage
- Manipulation des enums et gestion des exceptions
- Mise à jour des écrans et validation
- Liaison avec les nœuds via Node Bindings et validation des métadonnées
- Génération (`npm run generate`), compilation (`npm run build`) et démarrage (`npm run start`)

---

## 5. Développement d'opérations personnalisées

- Création d'un modèle d'import JSON pour l'entité personnalisée
- Paramétrage de l'opération API dans GESAPIOPE (mutation de type import)
- Gestion des collections de tâches

---

## 6. Utilisation de scripts 4GL dans les mutations

- Structure d'un script de type API : `$ACTION`, `PROCESS`, `START`, `END`
- Création de sous-programmes : création, mise à jour, suppression
- Appel des mutations à partir de GraphQL avec les bons paramètres

---

## 7. Test et validation des développements

- Test via GraphQL Sandbox
- Utilisation d'un client API (Bruno ou Postman) pour les mutations
- Téléchargement et introspection automatique du schéma GraphQL

---

## 8. Établir une connexion entre Shopify et X3 via GraphQL

- Concepts d'intégration entre un e-commerce et un ERP via API
- Exemples de requêtes et mutations entre Shopify et Sage X3
- Bonnes pratiques d'authentification et de sécurité dans l'échange de données
