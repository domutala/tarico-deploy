#!/bin/bash

set -e
cd "$(dirname "$0")"
source ./parse_args.sh
parse_args "$@"

envs="$1"
CLIENT_CODE=$(echo "$envs" | jq -r '.code')
TARGET_DIR="$PROJECT_PATH/$CLIENT_CODE"
wNode="$(which node)"

nestService="[Unit]
Description=_code_.$CLIENT_CODE.$PROJECT_CODE.tarico.service
After=network.target

[Service]
WorkingDirectory=$TARGET_DIR/_code_
ExecStart=$wNode dist/main.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
"

nuxtService="[Unit]
Description=_code_.$CLIENT_CODE.$PROJECT_CODE.tarico.service
After=network.target

[Service]
WorkingDirectory=$TARGET_DIR/_code_
ExecStart=$wNode server.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
"

build_service() {
    app="$1"
    framework=$(echo "$app" | jq -r '.framework')
    code=$(echo "$app" | jq -r '.code')
    service=""

    if [[ "$framework" == "nest" ]]; then
        service="$nestService"
    elif [[ "$framework" == "nuxt" ]]; then
        service="$nuxtService"
    else
        echo "❌ Framework inconnu : $framework"
    fi

    service="${service//_code_/$code}"
    service_name=$code.$CLIENT_CODE.$PROJECT_CODE.tarico.service
    echo "$service" >"/etc/systemd/system/${service_name}"
    
    cd "${TARGET_DIR}/$code"
    yarn config set registry https://registry.npmjs.org/
    sudo rm -rf node_modules
    sudo rm -f yarn.lock
    yarn install
    yarn run build

    # Recharger et reconfigurer les services systemd
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    sudo systemctl enable "${service_name}"
    sudo systemctl restart "${service_name}"

    echo "✅ Service ${service_name} démarré et activé."
    # echo "sudo journalctl -u $service_name -n 20" 
}


apps=$(echo "$envs" | jq -r '.apps')
echo "$apps" | jq -c '.[]' | while read -r app; do
  build_service "$app"
done

# sudo journalctl -u client.dsm.papers.extrait.tarico.service -n 20

