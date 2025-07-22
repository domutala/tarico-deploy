#!/bin/bash

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --*=*)
                KEY="${1%%=*}"
                VALUE="${1#*=}"
                KEY="${KEY/--/}"
                VAR_NAME=$(echo "$KEY" | tr '[:lower:]-' '[:upper:]_')
                eval "${VAR_NAME}=\"${VALUE}\""
                shift
                ;;
            --*)
                KEY="${1/--/}"
                VALUE="$2"
                VAR_NAME=$(echo "$KEY" | tr '[:lower:]-' '[:upper:]_')
                eval "${VAR_NAME}=\"${VALUE}\""
                shift 2
                ;;
            *)
                # echo "Argument inconnu : $1"
                shift
                ;;
        esac
    done
}
