#!/bin/sh

ARCHIVE="$(date '+%F').tar.gz.age"
FILE_LIST="${1:-./file_list}"

AGE_BIN=/usr/local/bin/age
SIGNIFY_BIN=/usr/bin/signify-openbsd
TAR_BIN=/usr/bin/bsdtar
SUM_CMD="${SUM_CMD:-/usr/bin/sha256sum --tag}"

SUM_TYPE="${SUM_TYPE:-sha256}"
AGE_RECIPIENT="${AGE_RECIPIENT}"
SIGNIFY_KEY="${SIGNIFY_KEY:-./backups.sec}"
ARCHIVE_SUM="${ARCHIVE}.${SUM_TYPE}"

usage() {
	cat<<EOF
usage: backup.sh <file_list_file>
where:
  file_list_file  contains a list of newline separated paths to backup
EOF
}

log() {
	printf "[bup] %s\n" "$1" >&2
}

log "adding files from file_list..."
files=''
while read -r line; do
	log "  adding ${line}"
	files="${files} ${line}"
done < "$FILE_LIST"

log "archiving + encrypting..."
# we need it to split here since the files are arguments:
# shellcheck disable=SC2086
$TAR_BIN -cvzf - $files | $AGE_BIN -a -r "$AGE_RECIPIENT" -o "$ARCHIVE"

log "generating hash sum..."
$SUM_CMD "$ARCHIVE" > "$ARCHIVE_SUM"

log "signing hash sum file..."
$SIGNIFY_BIN -S -e -x "${ARCHIVE_SUM}.sig" -s "$SIGNIFY_KEY" -m "$ARCHIVE_SUM"
