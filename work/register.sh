#!/bin/bash

set -e
cd "$(dirname "$0")"
source ./parse_args.sh
parse_args "$@"

envs="$1"
CLIENT_CODE=$(echo "$envs" | jq -r '.code')
TARGET_DIR="$PROJECT_PATH/$CLIENT_CODE"

setup_nginx() {
    domain="$1"
    port="$2"

    EMAIL="contact@tarico.io"
    TEMPLATE_FILE="../nginx.template.conf"
    CONF_PATH="/etc/nginx/sites-available/${domain}.conf"
    ENABLED_PATH="/etc/nginx/sites-enabled/${domain}.conf"

    # Vérifier que le template existe
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "❌ Fichier nginx.template.conf introuvable dans $(pwd)"
        exit 1
    fi

    # Générer le fichier de configuration Nginx
    conf=$(sed "s/\$URL/${domain}/g; s/\$PORT/${port}/g" "$TEMPLATE_FILE")
    echo "$conf" | sudo tee "$CONF_PATH" >/dev/null

    # Créer le lien symbolique s'il n'existe pas
    if [ ! -f "$ENABLED_PATH" ]; then
        sudo ln -s "$CONF_PATH" "$ENABLED_PATH"
    fi

    # Générer SSL avec Certbot
    echo "🔐 Obtention du certificat SSL pour $domain ..."
    sudo certbot certonly --standalone -d "$domain" -d "www.$domain" --email "$EMAIL" --non-interactive --agree-tos

    echo "✅ nginx configuré pour $domain"
}

sudo systemctl stop nginx

apps=$(echo "$envs" | jq -r '.apps')
echo "$apps" | jq -c '.[]' | while read -r app; do
    port=$(echo "$app" | jq -r '.port')
    domain=$(echo "$app" | jq -r '.domain')

    setup_nginx "$domain" "$port"
done

sudo systemctl restart nginx

sudo certbot certonly --nginx -d api.extrait.tarico.space --email contact@tarico.io --non-interactive --agree-tos
