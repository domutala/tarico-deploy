#!/bin/bash

set -e
cd "$(dirname "$0")"
source ./parse_args.sh
parse_args "$@"

bash ./git.sh "$@"
bash ./env.sh "$@"
bash ./meili.sh  "$@"
bash ./service.sh "$@"
# bash ./register.sh "$@"
