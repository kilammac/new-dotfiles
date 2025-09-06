# Guide Git complet - Comprendre et résoudre tous les problèmes

## 📚 Comprendre Git d'abord

### Qu'est-ce qui se passe quand vous utilisez Git ?

```
Votre ordinateur (local)     ←→     GitHub (remote)
~/.config/ (dossier)         ←→     dotfiles (repository)
```

**3 zones importantes :**
1. **Working Directory** : Vos fichiers normaux (`~/.config/`)
2. **Staging Area** : Fichiers préparés pour le commit (`git add`)
3. **Repository** : Historique des commits (`git commit`)

### Schéma du workflow Git
```
[Fichiers modifiés] → git add → [Staging] → git commit → [Local Repo] → git push → [GitHub]
                                     ↑                                           ↓
                                git reset                                   git pull
```

## 🔍 Diagnostiquer avant d'agir

### Commande #1 : `git status` - Votre boussole

```bash
cd ~/.config
git status
```

**Exemples de sorties et leur signification :**

#### Cas 1 : Tout va bien
```
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```
**Signification :** Aucune modification, vous pouvez travailler tranquillement.

#### Cas 2 : Fichiers modifiés
```
On branch main
Your branch is up to date with 'origin/main'.
Changes not staged for commit:
  modified:   home-files/.bashrc
  modified:   nvim/init.vim
```
**Signification :** Vous avez modifié des fichiers, mais pas encore fait `git add`.

#### Cas 3 : Fichiers en staging
```
On branch main
Your branch is up to date with 'origin/main'.
Changes to be committed:
  modified:   home-files/.bashrc
```
**Signification :** Fichiers prêts à être commitéss avec `git commit`.

#### Cas 4 : Vous êtes en avance
```
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
```
**Signification :** Vous avez fait des commits pas encore pushés.

#### Cas 5 : Vous êtes en retard
```
On branch main
Your branch is behind 'origin/main' by 2 commits.
```
**Signification :** GitHub a des nouveautés que vous n'avez pas récupérées.

#### Cas 6 : Conflit !
```
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
Unmerged paths:
  both modified:   home-files/.bashrc
```
**Signification :** Conflit de merge à résoudre manuellement.

## 🚨 Situations problématiques et solutions détaillées

### Problème 1 : "Je ne peux pas push"

#### Erreur typique :
```bash
git push
# error: failed to push some refs to 'github.com:username/dotfiles.git'
# hint: Updates were rejected because the remote contains work that you do not have locally.
```

#### Pourquoi ça arrive ?
Quelqu'un (ou vous sur une autre machine) a pushé des modifications sur GitHub après votre dernier `git pull`.

#### Solution étape par étape :

```bash
# 1. Vérifier l'état
git status

# 2. Si vous avez des modifications non commitées, les sauvegarder
git stash push -m "sauvegarde avant pull"

# 3. Récupérer les nouveautés de GitHub
git pull

# 4. Récupérer vos modifications sauvegardées
git stash pop

# 5. Résoudre conflits si nécessaire (voir plus bas)

# 6. Maintenant vous pouvez push
git push
```

#### Exemple concret :
```bash
# Vous sur votre PC portable
echo "alias l='ls -la'" >> ~/.bashrc
cp ~/.bashrc ~/.config/home-files/.bashrc
git add . && git commit -m "Ajout alias l" && git push

# Vous sur votre PC fixe (oublié de pull)
echo "alias h='history'" >> ~/.bashrc
cp ~/.bashrc ~/.config/home-files/.bashrc
git add . && git commit -m "Ajout alias h"
git push  # ❌ ERREUR !

# Solution sur PC fixe :
git pull  # Va créer un conflit sur home-files/.bashrc
# Résoudre le conflit (voir section conflits)
git push  # ✅ Maintenant ça marche
```

### Problème 2 : "Je ne peux pas pull"

#### Erreur typique :
```bash
git pull
# error: Your local changes to the following files would be overwritten by merge:
#     home-files/.bashrc
# Please commit your changes or stash them before you merge.
```

#### Pourquoi ça arrive ?
Vous avez modifié des fichiers que GitHub veut aussi modifier.

#### Solution 1 : Sauvegarder temporairement
```bash
# 1. Sauvegarder vos modifications
git stash push -m "mes modifs en cours"

# 2. Pull tranquillement
git pull

# 3. Récupérer vos modifications
git stash pop

# 4. Si conflit après stash pop, résoudre (voir section conflits)
```

#### Solution 2 : Commiter d'abord
```bash
# 1. Commiter vos modifications
git add .
git commit -m "WIP: sauvegarde avant pull"

# 2. Pull (peut créer un merge commit)
git pull

# 3. Push le tout
git push
```

#### Exemple concret :
```bash
# Vous modifiez .bashrc
echo "export EDITOR=vim" >> ~/.bashrc
cp ~/.bashrc ~/.config/home-files/.bashrc

# Vous voulez pull mais quelqu'un a modifié le même fichier
git pull  # ❌ ERREUR !

# Solution :
git stash  # Sauvegarde vos modifs
git pull   # Récupère les nouveautés
git stash pop  # Récupère vos modifs → peut créer un conflit à résoudre
```

### Problème 3 : Résoudre les conflits de merge

#### Comment reconnaître un conflit ?
```bash
git status
# Unmerged paths:
#   both modified:   home-files/.bashrc
```

#### À quoi ressemble un fichier en conflit ?
```bash
cat ~/.config/home-files/.bashrc
```
```bash
# Contenu normal...
export PATH=$PATH:/usr/local/bin

<<<<<<< HEAD
# Vos modifications (sur votre machine)
alias l='ls -la'
export EDITOR=vim
=======
# Modifications du remote (GitHub)
alias ll='ls -alh'
export EDITOR=nano
>>>>>>> origin/main

# Reste du fichier...
```

#### Résolution étape par étape :

```bash
# 1. Ouvrir le fichier en conflit
nano ~/.config/home-files/.bashrc

# 2. Décider quoi garder :
# Option A : Garder seulement vos modifications
# Option B : Garder seulement celles de GitHub  
# Option C : Garder les deux (recommandé)
# Option D : Mélanger selon vos besoins

# 3. Éditer manuellement pour obtenir :
export PATH=$PATH:/usr/local/bin

# Je garde les deux alias avec des noms différents
alias l='ls -la'      # Mon alias
alias ll='ls -alh'    # Alias de GitHub

# Je choisis vim comme éditeur
export EDITOR=vim

# 4. Supprimer TOUS les marqueurs de conflit
# (plus de <<<<<<<, =======, ou >>>>>>>)

# 5. Sauvegarder le fichier

# 6. Marquer le conflit comme résolu
git add home-files/.bashrc

# 7. Finaliser le merge
git commit -m "Résolution conflit .bashrc - fusion des alias"

# 8. Push
git push
```

#### Exemple complet de résolution :
```bash
# État initial après git pull avec conflit
git status
# both modified:   home-files/.bashrc

# Voir le conflit
cat home-files/.bashrc
# <<<<<<< HEAD
# alias myalias='ls -la'
# =======  
# alias otheralias='ls -alh'
# >>>>>>> origin/main

# Éditer pour résoudre
nano home-files/.bashrc
# Contenu final :
# alias myalias='ls -la'
# alias otheralias='ls -alh'

# Marquer comme résolu
git add home-files/.bashrc

# Commit de résolution
git commit -m "Merge: gardé les deux alias"

# Push
git push
```

## 🛠️ Outils de diagnostic

### Voir les différences

#### Voir ce qui a changé (pas encore en staging)
```bash
git diff
```
**Exemple de sortie :**
```diff
diff --git a/home-files/.bashrc b/home-files/.bashrc
index 1234567..abcdefg 100644
--- a/home-files/.bashrc
+++ b/home-files/.bashrc
@@ -10,3 +10,4 @@
 export PATH=$PATH:/usr/local/bin
 
 # Mes alias
+alias newone='ls -la'
```

#### Voir ce qui va être commité
```bash
git diff --staged
```

#### Voir les différences avec GitHub
```bash
git diff HEAD origin/main
```

### Voir l'historique

#### Historique simple
```bash
git log --oneline -10
```
**Exemple de sortie :**
```
a1b2c3d (HEAD -> main) Ajout alias newone
e4f5g6h Mise à jour nvim config
i7j8k9l Initial commit
```

#### Historique détaillé
```bash
git log --stat -5
```

#### Voir qui a modifié quoi
```bash
git blame home-files/.bashrc
```

## 🔄 Workflows sécurisés

### Workflow quotidien SAFE

```bash
# 1. TOUJOURS commencer par vérifier l'état
cd ~/.config
git status

# 2. Si des modifications en cours, les sauvegarder
git stash push -m "sauvegarde $(date)"

# 3. Récupérer les nouveautés
git pull

# 4. Récupérer vos modifications
git stash pop

# 5. Résoudre conflits si nécessaire

# 6. Faire vos modifications
cp ~/.bashrc home-files/.bashrc

# 7. Vérifier ce qui va être commité
git status
git diff

# 8. Commiter et push
git add .
git commit -m "Description claire des changements"
git push
```

### Workflow pour modifications importantes

```bash
# 1. Créer une branche de test
git checkout -b test-modifications

# 2. Faire vos modifications
cp ~/.bashrc home-files/.bashrc
# ... autres modifications

# 3. Tester que tout marche
git add .
git commit -m "Test: nouvelles modifications"

# 4. Si tout va bien, revenir à main
git checkout main
git merge test-modifications

# 5. Push
git push

# 6. Supprimer la branche de test
git branch -d test-modifications
```

## 🆘 Commandes de récupération

### Annuler le dernier commit (mais garder les modifications)
```bash
git reset --soft HEAD~1
```
**Exemple :**
```bash
# Vous venez de commiter
git commit -m "Oops, mauvais message"

# Annuler le commit mais garder les modifs
git reset --soft HEAD~1

# Refaire le commit avec le bon message
git commit -m "Bon message cette fois"
```

### Annuler complètement le dernier commit
```bash
git reset --hard HEAD~1
```
**⚠️ ATTENTION : Supprime définitivement vos modifications !**

### Récupérer un fichier supprimé
```bash
git checkout HEAD -- chemin/vers/fichier
```
**Exemple :**
```bash
# Vous avez supprimé .bashrc par erreur
rm ~/.config/home-files/.bashrc

# Le récupérer du dernier commit
git checkout HEAD -- home-files/.bashrc
```

### Abandonner toutes les modifications locales
```bash
git checkout -- .
```

### Revenir à l'état exact de GitHub
```bash
git fetch origin
git reset --hard origin/main
```

## 📋 Situations courantes avec exemples

### Cas 1 : Modification simple
```bash
# Modifier un fichier
echo "alias new='command'" >> ~/.bashrc
cp ~/.bashrc ~/.config/home-files/.bashrc

# Workflow
cd ~/.config
git status  # Voir: modified: home-files/.bashrc
git add .
git commit -m "Ajout alias new"
git push
```

### Cas 2 : Modifications sur 2 machines
```bash
# Machine A
echo "alias a='cmd'" >> ~/.bashrc
cp ~/.bashrc ~/.config/home-files/.bashrc
git add . && git commit -m "alias a" && git push

# Machine B (sans pull avant)
echo "alias b='cmd'" >> ~/.bashrc
cp ~/.bashrc ~/.config/home-files/.bashrc
git add . && git commit -m "alias b"
git push  # ❌ ERREUR

# Solution sur Machine B
git pull  # Conflit !
# Éditer home-files/.bashrc pour garder les 2 alias
git add home-files/.bashrc
git commit -m "Merge alias a et b"
git push
```

### Cas 3 : Gros problème, tout reset
```bash
# Sauvegarder d'abord
cp -r ~/.config ~/.config.backup

# Reset total
cd ~/.config
git fetch origin
git reset --hard origin/main
git clean -fd

# Vérifier
git status  # Doit dire "clean"
```

## 🎯 Messages d'erreur et solutions

### "fatal: refusing to merge unrelated histories"
**Cause :** Deux repos complètement différents  
**Solution :**
```bash
git pull --allow-unrelated-histories
```

### "error: failed to push some refs"
**Cause :** GitHub plus récent que votre version locale  
**Solution :**
```bash
git pull
git push
```

### "You have unstaged changes"
**Cause :** Modifications pas encore ajoutées avec `git add`  
**Solution :**
```bash
git stash  # ou git add .
```

### "CONFLICT (content): Merge conflict"
**Cause :** Même fichier modifié des 2 côtés  
**Solution :** Voir section "Résoudre les conflits" ci-dessus

## ✅ Règles d'or

1. **Toujours `git status` avant tout**
2. **`git pull` avant de commencer à travailler**
3. **En cas de doute : `git stash`, `git pull`, `git stash pop`**
4. **Lisez les messages d'erreur, ils sont explicites**
5. **Testez sur une branche pour les gros changements**

## 🚀 Alias pratiques pour votre .bashrc

```bash
# Ajoutez ça à votre ~/.bashrc
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline -10'

# Fonction pour mettre à jour les dotfiles
dotfiles() {
    cd ~/.config
    git status
    cp ~/.bashrc home-files/.bashrc 2>/dev/null
    cp ~/.profile home-files/.profile 2>/dev/null
    git add .
    git commit -m "${1:-Update dotfiles $(date '+%Y-%m-%d %H:%M')}"
    git push
    echo "✅ Dotfiles mis à jour !"
}

# Usage : dotfiles "mon message"
```

Avec ce guide, vous devriez pouvoir résoudre 99% des problèmes Git ! 🎯