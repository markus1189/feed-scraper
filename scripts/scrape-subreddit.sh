#!/usr/bin/env bash

set -o pipefail
set -ex

USER_AGENT='User-Agent: Mozilla/5.0 (Linux; Android 8.0.0; SM-G960F Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.84 Mobile Safari/537.36'

SUBREDDIT="${1:?no-subreddit-given}"
TEMP_DIR="$(mktemp -d -p . tmp.XXXXXXXXXX)"

TARGET_FILE="feeds/reddit/${SUBREDDIT}.xml"
OLD_FILE="${TEMP_DIR}/${SUBREDDIT}-old.json"
NEW_FILE="${TEMP_DIR}/${SUBREDDIT}-new.xml"

if [[ -f "${TARGET_FILE}" ]]; then
    xq . "${TARGET_FILE}" > "${OLD_FILE}"
fi

curl --fail \
     -H "${USER_AGENT}" \
     -s "https://www.reddit.com/r/${SUBREDDIT}.rss" |
    xq -x . > "${NEW_FILE}"

if [[ -f feeds/reddit/"${SUBREDDIT}".xml ]]; then
    xq -x --slurpfile old "${OLD_FILE}" \
       '.feed.entry |= ($old[0].feed.entry + . | unique)' \
       "${NEW_FILE}" > "${TARGET_FILE}"
else
    cp -v "${NEW_FILE}" "${TARGET_FILE}"
fi
