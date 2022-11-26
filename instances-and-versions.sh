#!/usr/bin/env bash

if [[ $(uname -s) == Darwin ]]; then
    if ! command -v grep >/dev/null; then
        printf 'Please, install "grep"!\n$ brew install grep\n' >&2
        exit 1
    fi

    grep="ggrep"
else
    grep="grep"
fi

if ! command -v jq >/dev/null; then
    printf 'Please, install "jq"!\n' >&2
    exit 1
fi

if [[ $# -ne 1 ]] || [[ -z $1 ]]; then
    printf 'You need to pass one input file, e.g.:\n$ bash %s instances.txt\n' "${0##*/}" >&2
    exit 1
fi

while read -r domain; do 
    if ! json="$(curl -H "Accept: application/json" --proto '=https' --tlsv1.2 --ciphers 'ECDHE+AESGCM+AES256:ECDHE+CHACHA20:ECDHE+AESGCM+AES128' -fsL "https://${domain}/api/v2/instance")" && \
       ! json="$(curl -H "Accept: application/json" --proto '=https' --tlsv1.2 --ciphers 'ECDHE+AESGCM+AES256:ECDHE+CHACHA20:ECDHE+AESGCM+AES128' -fsL "https://${domain}/api/v1/instance")"
    then
        status="error while querying API"
    else
        status="$(jq --exit-status -r '.version' <<< "${json}")" || status="error while parsing json"
    fi

    jq --null-input --arg domain "${domain}" --arg status "${status}" '{"key":$domain,"value":$status}'
done < <(${grep} -Po 'font-700">\K[^<]+' "$1") | jq -s '. | sort_by(.value) | from_entries'
