# PEM & Certificates

Inspect an X.509 certificate's subject, validity period, and SHA-256 fingerprint.

CLI: `pem-certificate`

## Usage

Paste a PEM certificate or import a PEM / DER file. Run to inspect the subject, validity period, and SHA-256 fingerprint. Supply a certificate, not a private key.

## CLI

```sh
devkit describe pem-certificate
```

Read from a file:

```sh
devkit run pem-certificate --file ./certificate.pem
```

## Notes

Reads the first PEM / DER certificate. Does not verify the trust chain or parse private keys.
