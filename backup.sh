#!/bin/sh

set -e

AGE_RECIPIENT="${1}"
SIGNIFY_KEY="${2}"
FILE_LIST="${3}"

AGE_BIN=/usr/local/bin/age
SIGNIFY_BIN=/usr/bin/signify-openbsd
TAR_BIN=/usr/bin/bsdtar
SUM_CMD="${SUM_CMD:-/usr/bin/sha256sum --tag}"
SUM_TYPE="${SUM_TYPE:-sha256}"
ARCHIVE="$(date '+%F').tar.gz.age"
ARCHIVE_SUM="${ARCHIVE}.${SUM_TYPE}"

usage() {
	cat<<EOF
usage: backup.sh age_recipient signify_key file_list_file
where:
  age_recipient   age recipient / public key
  signify_key     path to signify private key
  file_list_file  contains a list of newline separated paths to backup
EOF
}

log() {
	printf "[bup] %s\n" "$1" >&2
}

die() {
	printf '[bup] error: %s\n' "$1" >&2
	exit 127
}

cat <<EOF
CHECKSUM TYPE    : ${SUM_TYPE}
AGE RECIPIENT    : ${AGE_RECIPIENT}
SIGNIFY KEY      : ${SIGNIFY_KEY}
ARCHIVE FILENAME : ${ARCHIVE}
FILE_LIST        : {
EOF

#log "adding files from file_list..."
files=''
while read -r line; do
	printf '                      %s,\n' "$line"
	files="${files} ${line}"
done < "$FILE_LIST"
printf '                   }\n\n'

test -f "$FILE_LIST"     || die "file list not found."
test -f "$SIGNIFY_KEY"   || die "signify key could not be found."
test -z "$AGE_RECIPIENT" && die "age recipient not specified."

printf 'enter to continue (ctrl-c to cancel)...'
read -r _
printf '\n'

log "archiving + encrypting..."
# we need it to split here since the files are arguments:
# shellcheck disable=SC2086
$TAR_BIN -cvzf - $files | $AGE_BIN -a -r "$AGE_RECIPIENT" -o "$ARCHIVE"

log "generating checksum..."
$SUM_CMD "$ARCHIVE" > "$ARCHIVE_SUM"

log "signing checksum file."
log "you will now be prompted for the signing key passphrase..."
$SIGNIFY_BIN -S -e -x "${ARCHIVE_SUM}.sig" -s "$SIGNIFY_KEY" -m "$ARCHIVE_SUM"
