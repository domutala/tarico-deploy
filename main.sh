#!/bin/bash

set -e
cd "$(dirname "$0")"
source ./work/parse_args.sh

parse_args "$@"
ENV_FILE_PATH="$PROJECT_PATH/envs.jsonc"

# Vérifie si jq est installé
if ! command -v jq &>/dev/null; then
    echo "'jq' is required but not installed. Install it with: sudo apt install jq"
    exit 1
fi

# Vérifie que le fichier JSON existe
if [ ! -f "$ENV_FILE_PATH" ]; then
    echo "JSON file '$ENV_FILE_PATH' not found."
    exit 1
fi

# Get number of elements in the array
array_length=$(jq 'length' "$ENV_FILE_PATH")

# Loop through each element
for ((index = 0; index < array_length; index++)); do
    element=$(jq -c ".[$index]" "$ENV_FILE_PATH") # -c = compact JSON for command-line use
    element_branch=$(echo "$element" | jq -r '.branch')

    if [ -z "$BRANCH" ]; then
        bash ./work/start.sh "$element" "$@"
    else
        if [ "$element_branch" == "$BRANCH" ]; then
            bash ./work/start.sh "$element" "$@" 
        fi
    fi
done

# bash main.sh \
#     --project-path=/var/prod/papers \
#     --project-code=paper_extrait \
#     --branch=dev \
#     --repo-url=git@github.com:advensya/papers.git