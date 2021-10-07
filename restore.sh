#!/bin/sh

set -e

AGE_KEY="$1"
SIGNIFY_PUB="$2"
ARCHIVE="$3"
RESTORE_ROOT="${4:-/}"

# uncomment for typical Linux binary paths
#AGE_BIN=/usr/local/bin/age
#SIGNIFY_BIN=/usr/bin/signify-openbsd
#TAR_BIN=/usr/bin/bsdtar
#SUM_CMD="${SUM_CMD:-/usr/bin/sha256sum --tag}"

# uncomment for OpenBSD binary paths
AGE_BIN=/usr/local/bin/age
SIGNIFY_BIN=/usr/bin/signify
TAR_BIN=/bin/tar
SUM_CMD="${SUM_CMD:-sha256}"

SUM_TYPE="${SUM_TYPE:-sha256}"
ARCHIVE_SUM="${ARCHIVE}.${SUM_TYPE}"

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
	usage
	exit 127
}

cat <<EOF
ARCHIVE FILENAME   : ${ARCHIVE}
CHECKSUM TYPE      : ${SUM_TYPE}
ARCHIVE CHECKSUM   : ${ARCHIVE_SUM}
CHECKSUM SIGNATURE : ${ARCHIVE_SUM}.sig
AGE KEY FILE       : ${AGE_KEY}
SIGNIFY PUBKEY     : ${SIGNIFY_PUB}

EOF

test -f "$ARCHIVE"           || die "archive file not found."
test -f "$ARCHIVE_SUM"       || die "archive checksum file not found."
test -f "${ARCHIVE_SUM}.sig" || die "signed checksum file not found."
test -f "$AGE_KEY"           || die "age private key file not found."
test -f "SIGNIFY_PUB"        || die "signify public key file not found."

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
