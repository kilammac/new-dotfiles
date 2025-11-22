# Cheatsheet Neovim - Raccourcis Clavier

## Configuration Leader

- **Leader** : `Espace`

## Navigation de Base

| Raccourci | Description                                       | Mode   |
| --------- | ------------------------------------------------- | ------ |
| `j`       | Déplacer le curseur vers le bas (ligne visuelle)  | Normal |
| `k`       | Déplacer le curseur vers le haut (ligne visuelle) | Normal |
| `0`       | Aller au début de la ligne visuelle               | Normal |
| `$`       | Aller à la fin de la ligne visuelle               | Normal |
| `+`       | Déplacer le curseur vers le bas (ligne physique)  | Normal |
| `-`       | Déplacer le curseur vers le haut (ligne physique) | Normal |

## Édition

| Raccourci | Description                                         | Mode   |
| --------- | --------------------------------------------------- | ------ |
| `U`       | Refaire (Redo)                                      | Normal |
| `p`       | Coller (garde le contenu original dans le registre) | Visuel |

## Fenêtres et Navigation

| Raccourci     | Description                            | Mode   |
| ------------- | -------------------------------------- | ------ |
| `Ctrl+g`      | Naviguer entre les fenêtres            | Normal |
| `Ctrl+Haut`   | Redimensionner fenêtre (+2 en hauteur) | Normal |
| `Ctrl+Bas`    | Redimensionner fenêtre (-2 en hauteur) | Normal |
| `Ctrl+Gauche` | Redimensionner fenêtre (+2 en largeur) | Normal |
| `Ctrl+Droite` | Redimensionner fenêtre (-2 en largeur) | Normal |

## Gestion des Buffers

| Raccourci | Description             | Mode   |
| --------- | ----------------------- | ------ |
| `Ctrl+i`  | Buffer suivant          | Normal |
| `Ctrl+l`  | Buffer précédent        | Normal |
| `Maj+q`   | Fermer le buffer actuel | Normal |

## Utilitaires

| Raccourci   | Description                                  | Mode   |
| ----------- | -------------------------------------------- | ------ |
| `Leader+h`  | Effacer les surbrillances de recherche       | Normal |
| `Leader+cd` | Changer de répertoire vers le fichier actuel | Normal |
| `Leader+i`  | Activer/désactiver les indices LSP           | Normal |

## Mode Visuel

| Raccourci | Description                                    | Mode   |
| --------- | ---------------------------------------------- | ------ |
| `<`       | Indenter vers la gauche (reste en mode visuel) | Visuel |
| `>`       | Indenter vers la droite (reste en mode visuel) | Visuel |
| `Maj+r`   | Déplacer la sélection vers le haut             | Visuel |
| `Maj+t`   | Déplacer la sélection vers le bas              | Visuel |

## Mode Visuel Bloc

| Raccourci | Description                                 | Mode        |
| --------- | ------------------------------------------- | ----------- |
| `Maj+r`   | Déplacer le bloc vers le haut               | Visuel Bloc |
| `Maj+t`   | Déplacer le bloc vers le bas                | Visuel Bloc |
| `J`       | Déplacer le bloc vers le bas (alternative)  | Visuel Bloc |
| `K`       | Déplacer le bloc vers le haut (alternative) | Visuel Bloc |

## Explorateur de Fichiers (NvimTree)

| Raccourci  | Description                             | Mode   |
| ---------- | --------------------------------------- | ------ |
| `Leader+e` | Ouvrir/fermer l'explorateur de fichiers | Normal |

### Navigation dans NvimTree

| Raccourci   | Description                              |
| ----------- | ---------------------------------------- |
| `Ctrl+]`    | Changer la racine vers le nœud           |
| `Ctrl+e`    | Ouvrir en place                          |
| `Ctrl+k`    | Afficher les informations                |
| `Ctrl+t`    | Ouvrir dans un nouvel onglet             |
| `Ctrl+v`    | Ouvrir en split vertical                 |
| `Ctrl+x`    | Ouvrir en split horizontal               |
| `Backspace` | Fermer le répertoire                     |
| `Entrée`    | Ouvrir le fichier/répertoire             |
| `Tab`       | Aperçu                                   |
| `>`         | Frère suivant                            |
| `<`         | Frère précédent                          |
| `.`         | Exécuter une commande                    |
| `a`         | Créer un fichier/répertoire              |
| `c`         | Copier                                   |
| `d`         | Supprimer                                |
| `D`         | Mettre à la corbeille                    |
| `e`         | Renommer (nom de base)                   |
| `r`         | Renommer                                 |
| `x`         | Couper                                   |
| `y`         | Copier le nom                            |
| `Y`         | Copier le chemin relatif                 |
| `gy`        | Copier le chemin absolu                  |
| `p`         | Coller                                   |
| `q`         | Fermer                                   |
| `R`         | Actualiser                               |
| `S`         | Rechercher                               |
| `f`         | Filtrer                                  |
| `F`         | Nettoyer le filtre                       |
| `H`         | Basculer l'affichage des fichiers cachés |
| `I`         | Basculer le filtre gitignore             |
| `m`         | Basculer le marque-page                  |
| `P`         | Répertoire parent                        |

## Recherche avec Telescope

| Raccourci   | Description                         | Mode   |
| ----------- | ----------------------------------- | ------ |
| `Leader+ff` | Rechercher des fichiers             | Normal |
| `Leader+fg` | Rechercher du texte dans le projet  | Normal |
| `Leader+fb` | Rechercher dans les noms de buffers | Normal |
| `Leader+fx` | Rechercher le mot sous le curseur   | Normal |
| `Leader+ft` | Rechercher les TODOs                | Normal |

## LSP (Language Server Protocol)

| Raccourci   | Description                                     | Mode          |
| ----------- | ----------------------------------------------- | ------------- |
| `gR`        | Afficher les références avec Telescope          | Normal        |
| `gD`        | Aller à la déclaration                          | Normal        |
| `gd`        | Afficher les définitions avec Telescope         | Normal        |
| `gi`        | Afficher les implémentations avec Telescope     | Normal        |
| `gt`        | Afficher les définitions de type avec Telescope | Normal        |
| `Leader+ca` | Actions de code                                 | Normal/Visuel |
| `Leader+rn` | Renommer intelligemment                         | Normal        |
| `Leader+D`  | Diagnostics du fichier avec Telescope           | Normal        |
| `Leader+d`  | Diagnostics de la ligne                         | Normal        |
| `[d`        | Diagnostic précédent                            | Normal        |
| `]d`        | Diagnostic suivant                              | Normal        |
| `K`         | Afficher la documentation                       | Normal        |
| `Leader+rs` | Redémarrer LSP                                  | Normal        |

## Autocomplétion (nvim-cmp)

| Raccourci     | Description                            | Mode      |
| ------------- | -------------------------------------- | --------- |
| `Ctrl+s`      | Élément précédent                      | Insertion |
| `Ctrl+t`      | Élément suivant                        | Insertion |
| `Ctrl+b`      | Défiler la documentation vers le haut  | Insertion |
| `Ctrl+f`      | Défiler la documentation vers le bas   | Insertion |
| `Ctrl+Espace` | Compléter                              | Insertion |
| `Ctrl+e`      | Annuler/fermer                         | Insertion |
| `Entrée`      | Confirmer la sélection                 | Insertion |
| `Tab`         | Confirmer ou passer au snippet suivant | Insertion |
| `Maj+Tab`     | Snippet précédent                      | Insertion |

## TreeSitter (Sélection Incrémentale)

| Raccourci     | Description                      | Mode   |
| ------------- | -------------------------------- | ------ |
| `Ctrl+Espace` | Initialiser/étendre la sélection | Normal |
| `Backspace`   | Réduire la sélection             | Normal |

## Trouble (Diagnostics)

| Raccourci   | Description                | Mode   |
| ----------- | -------------------------- | ------ |
| `Leader+xx` | Basculer les diagnostics   | Normal |
| `Leader+xX` | Diagnostics du buffer      | Normal |
| `Leader+cs` | Symboles                   | Normal |
| `Leader+cl` | Définitions/références LSP | Normal |
| `Leader+xL` | Liste de localisation      | Normal |
| `Leader+xQ` | Liste quickfix             | Normal |

## Which-Key (Aide)

| Raccourci  | Description                              | Mode   |
| ---------- | ---------------------------------------- | ------ |
| `Leader+?` | Afficher tous les raccourcis globaux     | Normal |
| `Leader+!` | Afficher les raccourcis locaux du buffer | Normal |

## Git

| Raccourci   | Description    | Mode   |
| ----------- | -------------- | ------ |
| `Leader+lg` | Ouvrir LazyGit | Normal |

### GitSigns

| Raccourci   | Description                           | Mode             |
| ----------- | ------------------------------------- | ---------------- |
| `]h`        | Hunk suivant                          | Normal           |
| `[h`        | Hunk précédent                        | Normal           |
| `Leader+hs` | Indexer le hunk                       | Normal/Visuel    |
| `Leader+hr` | Réinitialiser le hunk                 | Normal/Visuel    |
| `Leader+hS` | Indexer le buffer                     | Normal           |
| `Leader+hu` | Annuler l'indexation du hunk          | Normal           |
| `Leader+hR` | Réinitialiser le buffer               | Normal           |
| `Leader+hp` | Aperçu du hunk                        | Normal           |
| `Leader+hb` | Blâme de ligne                        | Normal           |
| `Leader+tb` | Basculer le blâme de ligne            | Normal           |
| `Leader+hd` | Diff du fichier                       | Normal           |
| `Leader+hD` | Diff avec HEAD                        | Normal           |
| `Leader+td` | Basculer l'affichage des suppressions | Normal           |
| `ih`        | Sélectionner le hunk                  | Opérateur/Visuel |

## Commentaires

| Raccourci | Description                      | Mode      |
| --------- | -------------------------------- | --------- |
| `gcc`     | Basculer le commentaire de ligne | Normal    |
| `gbc`     | Basculer le commentaire de bloc  | Normal    |
| `gc`      | Commentaire de ligne             | Opérateur |
| `gb`      | Commentaire de bloc              | Opérateur |

## Outils de Développement

| Raccourci   | Description                      | Mode          |
| ----------- | -------------------------------- | ------------- |
| `Leader+o`  | Basculer l'outline               | Normal        |
| `Leader+l`  | Déclencher le linting            | Normal        |
| `Leader+mp` | Formater le fichier/la sélection | Normal/Visuel |

## Notes

- Les raccourcis avec `Ctrl` utilisent la touche Contrôle
- Les raccourcis avec `Maj` utilisent la touche Majuscule (Shift)
- `Leader` est configuré sur la barre d'espace
- La configuration utilise le mapping Ergol/Bépo pour certains raccourcis
- En mode visuel, plusieurs raccourcis maintiennent la sélection active

