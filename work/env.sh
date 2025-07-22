#!/bin/bash

set -e
cd "$(dirname "$0")"
source ./parse_args.sh
parse_args "$@"

envs="$1"
code=$(echo "$envs" | jq -r '.code')
TARGET_DIR="$PROJECT_PATH/$code"

build_env() {
  envs="$1"
  path=$(echo "$envs" | jq -r '.path')

  mkdir -p "$TARGET_DIR/$path"

  ENV_FILE_PATH="$TARGET_DIR/$path/.env"
  env_file_content="ENV=production\nNODE_ENV=production\n"
  env_vars=$(echo "$envs" | jq -r '.envs | to_entries[] | "\(.key)=\(.value)"')

  while IFS= read -r line; do
      key=$(echo "$line" | cut -d= -f1)
      value=$(echo "$line" | cut -d= -f2-)

      # Si la valeur commence par $, on la remplace par la variable d'environnement système
      if [[ "$value" == \$* ]]; then
        var_name="${value:1}"  # enlever le $
        value_from_env="${!var_name}"
        value="$value_from_env"
      fi

      # Vérifie si c’est une chaîne de caractères
      if [[ "$value" =~ ^[0-9]+$ ]]; then
          env_file_content+="$key=$value\n"
      else
          env_file_content+="$key=\"$value\"\n"
      fi
  done <<<"$env_vars"

  echo -e "$env_file_content" >"$ENV_FILE_PATH"
  echo "✅ .env files generated in: $ENV_FILE_PATH"
}

apps=$(echo "$envs" | jq -r '.apps')
echo "$apps" | jq -c '.[]' | while read -r app; do
  build_env "$app"
done
