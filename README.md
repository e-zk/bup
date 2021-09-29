# bup
Encrypted, signed, backups (still WIP).

## About

The backup script archives and encrypts a list of paths using `age`, generates a checksum file, and finally signs that checksum file with `signify`.

The restore script verifies the signature and checksum of the archive, then decrypts and extracts it to the specified restore root.
