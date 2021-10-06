# bup
Encrypted, signed, backup script(s).

## About

The backup script archives and encrypts a list of paths using `age`, generates a checksum file, and finally signs that checksum file with `signify`.

The restore script verifies the signature and checksum of the archive, then decrypts and extracts it to the specified restore root.

The script requires four keys total. Two for encryption, and two for signing:

- [signify_key] - signify private key file
   - used during backup for signing the checksum file
- [signify_pub] - signify public key file
   - used during restore for signature verification
- [age_key] - age private key file 
   - used during restore archive decryption
- [age_recipient] - age public key 
   - used during backup for encryption
   - passed in command-line arguments

The backup script generates three files as as so:

	(tar) --> (age) --> archive.tar.gz.age
	                |-> (sha256) --> archive.tar.gz.sha256
	                               |-> (signify) --> archive.tar.gz.sha256.sig
- archive.tar.gz.age            - age encrypted tar archive
- archive.tar.gz.age.sha256     - sha256 checksum of the archive
- archive.tar.gz.age.sha256.sig - sha256 checksum file signed with signify

## Usage

### Setup keys

First the age key pair, used for encryption:

	$ age-keygen -o backups_key.txt
	Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
This public key is what you will need to pass to the backup script for it to encrypt the tar archive. The `backups_key.txt` private key will be needed for decryption.

age does not do any signing or authentication, so I opted to use OpenBSD's signify tool for that. To generate they signify keys use `signify` on OpenBSD, or install `signify-openbsd` on Linux:

	$ signify -G -p backups_sign.pub -s backups_sign.sec
	passphrase:
	confirm passphrase:

You will need to remember this passphrase for when the backup script runs `signify` to sign the checksum file.

### Backing up

Create a list of directories and files separated by newline you wish to back up. For example a list file could look like this:

	/home/username/work/
	/home/username/code/
	/etc/httpd.conf
	/etc/relayd.conf

Next run the backup script, passing the age public key, signify private key, and the file containing your list of files to add to the archive:

	backup.sh age1[...] backups_sign.sec backup_list

By default the script will create `YYYY-MM-DD.tar.gz.age` in the current directory.  
The script will prompt for the signify private key's passphrase.

### Restoring from backup

To restore from backup point the restore script to the backup archive `YYYY-MM-DD.tar.gz.age` and the root to which you wish to extract the archive to, making sure the associated checksum and signed checksum files are in the current directory.

	restore.sh YYYY-MM-DD.tar.gz.age /

