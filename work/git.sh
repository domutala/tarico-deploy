#!/bin/bash

set -e
cd "$(dirname "$0")"
source ./parse_args.sh
parse_args "$@"

envs="$1"
code=$(echo "$envs" | jq -r '.code')
branch=$(echo "$envs" | jq -r '.branch')
TARGET_DIR="$PROJECT_PATH/$code"

# Créer le répertoire parent si nécessaire
mkdir -p "$PROJECT_PATH"

# Cloner le dépôt
if [ -d "$TARGET_DIR" ]; then
    echo "Le dépôt existe déjà dans $TARGET_DIR. Mise à jour de la branche '$branch'..."
    cd "$TARGET_DIR"
    # git fetch origin
    git fetch --all
    git reset --hard origin/$branch
else
    echo "Clonage du dépôt '$REPO_URL' (branche $branch) dans $TARGET_DIR"
    git clone --branch "$branch" "$REPO_URL" "$TARGET_DIR"
fi
