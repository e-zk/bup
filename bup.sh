#!/bin/sh -e
# sign+encrypt a file w/ ssh keys + passphrase

DATE_BIN=/bin/date
TAR_BIN=/bin/tar
SIGNIFY_BIN=/usr/bin/signify
AGE_BIN=/usr/local/bin/age

seal_archive() {
		archive="$1"
		paths="$2"
		pubkey="$(date '+%F').pub"
		seckey="$(date '+%F').sec"
		
		# create archive
		$TAR_BIN cezf "${archive}.tgz" $paths
		
		# encyrpt archive
		$AGE_BIN -p -o "${archive}.tgz.age" < "${archive}.tgz" 

		# setup signify keys, sign 
		$SIGNIFY_BIN -G -n -c "verify with ${pubkey}; $(sha256 ${archive}.tgz.age)" -p "$pubkey" -s "$seckey"
		$SIGNIFY_BIN -S -m "$archive.tgz.age" -s "$seckey"

		rm -f "$seckey" "${archive}.tgz"

}

open_archive() {
	enc_archive="$1"
	pubkey="$2"
	output="$3"

	# verify signature first
	$SIGNIFY_BIN -V -p "$pubkey" -m "$enc_archive"

	$AGE_BIN -d -o "$output" < "$enc_archive"
}

extract_archive() {
	enc_archive="$1"
	pubkey="$2"

	# verify signature first
	$SIGNIFY_BIN -V -p "$pubkey" -m "$enc_archive"

	$AGE_BIN -d -o - < "$enc_archive" | tar xezf - -C /
}

case "$1" in
	"seal")
		shift
		archive="$1"

		# read paths to backup from stdin
		paths=''
		while read -r line; do
			paths="${paths} ${line}"
		done

		seal_archive "$1" $paths
		
		;;
	"open")
		shift
		# if a third argument is given, decrypt the archive to that
		if [ -n "$3" ]; then
			open_archive "$1" "$2" "$3"
		else
			extract_archive "$1" "$2"
		fi
		;;
	*)
		echo "invalid command." >&2
		exit 1
		;;
esac

