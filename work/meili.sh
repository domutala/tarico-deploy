#!/bin/bash

set -euo pipefail
cd "$(dirname "$0")"
source ./parse_args.sh
parse_args "$@"

envs="$1"
project_code=$(echo "$envs" | jq -r '.code')

build_meili() {
    meili="$1"

    MASTER_KEY=$(echo "$meili" | jq -r '.key')
    PORT=$(echo "$meili" | jq -r '.port')
    INDEX=$(echo "$meili" | jq -r '.index')

    VOLUME_NAME="${PROJECT_CODE}_meili_${project_code}_${INDEX}"
    CONTAINER_NAME="${PROJECT_CODE}_meili_${project_code}_${INDEX}"

    # Vérifier si le volume existe déjà
    if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
        echo "Le volume '$VOLUME_NAME' existe déjà."
    else
        echo "Création du volume Docker '$VOLUME_NAME'..."
        docker volume create "$VOLUME_NAME"
    fi

    # Vérifier si le conteneur existe
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Le conteneur '$CONTAINER_NAME' existe déjà."

        # Vérifier s'il est en cours d'exécution
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "Le conteneur est déjà en cours d'exécution."
        else
            echo "Relance du conteneur arrêté..."
            docker start "$CONTAINER_NAME"
        fi
    else
        echo "Création du conteneur Docker Meilisearch avec le volume '$VOLUME_NAME'..."
        echo "$PORT"

        docker run -d \
            --name "$CONTAINER_NAME" \
            -v "$VOLUME_NAME:/meili_data" \
            -p "${PORT}:7700" \
            -e MEILI_MASTER_KEY="$MASTER_KEY" \
            getmeili/meilisearch:v1.15

        echo "Conteneur Docker Meilisearch créé et démarré avec succès !"
    fi
}


meilis=$(echo "$envs" | jq -r '.meilis')
echo "$meilis" | jq -c '.[]' | while read -r meili; do
  build_meili "$meili"
done

