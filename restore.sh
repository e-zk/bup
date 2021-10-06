#!/bin/sh

set -e

AGE_KEY="$1"
SIGNIFY_PUB="$2"
ARCHIVE="$3"
RESTORE_ROOT="${4:-/}"

ARCHIVE_SUM="${ARCHIVE}.${SUM_TYPE}"

AGE_BIN=/usr/local/bin/age
SIGNIFY_BIN=/usr/bin/signify-openbsd
TAR_BIN=/usr/bin/bsdtar
SUM_CMD="${SUM_CMD:-/usr/bin/sha256sum --tag}"
SUM_TYPE="${SUM_TYPE:-sha256}"

usage() {
	cat<<EOF
usage: restore.sh age_key signify_pub archive [root]
where:
  age_key     is the path to the age private key
  signify_pub path to the signify public key
  archive     is the archive to restore
  root        is the optional root to extract to (tar -C)
              (default is '/')
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
ARCHIVE FILENAME : ${ARCHIVE}
CHECKSUM TYPE    : ${SUM_TYPE}
AGE KEY FILE     : ${AGE_KEY}
SIGNIFY PUBKEY   : ${SIGNIFY_PUB}

EOF

test -f "$ARCHIVE"    || die "archive file not found."
test -f "$AGE_KEY"    || die "age private key file not found."
test -f "SIGNIFY_PUB" || die "signify public key file not found."

printf 'enter to continue (ctrl-c to cancel)...'
read -r _
printf '\n'

printf '[bup] verifying signature + checksum... '
if $SIGNIFY_BIN -C -q -p "$SIGNIFY_PUB" -x "${ARCHIVE_SUM}.sig"; then
	printf 'verified.\n'
else
	printf 'verification failed.\n'
	exit
fi

log "decrypting and untaring..."
$AGE_BIN --decrypt -i "$AGE_KEY" -o - "$ARCHIVE" | $TAR_BIN -xvz -C "$RESTORE_ROOT" -f -

log "extraction complete!"
