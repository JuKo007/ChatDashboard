# WhatsR in webR

This compatibility check runs separately from the Shiny application. It accepts
no participant files and has no donation endpoint.

1. Place the browser assets from a pinned [webR release](https://github.com/r-wasm/webr/releases)
   in `tools/webr-probe/runtime/`.
2. Apply the [WhatsR patch](whatsr.md) and build a WebAssembly binary repository
   for the same R version and webR release. Publish the repository under
   `tools/webr-probe/packages/`, including the required imports. See the
   [webR package documentation](https://docs.r-wasm.org/webr/latest/packages.html).
3. Serve `tools/webr-probe/` from a localhost development server and open
   `index.html`. Run the check and inspect the output and browser network log.

The check uses browser-local synthetic Android and iOS exports and verifies
that the package loads without Java, retains multiline messages, and excludes
messages from a sender whose consent is missing. It does not establish full
desktop/browser parity or verify donation behavior.

Before switching the study to browser processing, verify desktop/browser
parity, including ZIP exports, timestamp handling, and the study's German
message formats. Move row and field selection and results that use excluded
data into the browser. Replace the Shiny upload path with a ciphertext-only
endpoint. The research private key belongs outside the serving environment.

## Encrypted subset format

`www/js/donation-crypto.mjs` accepts serialized subset bytes and the study
public key as SPKI DER. It returns a versioned JSON envelope. Each donation
uses a fresh AES-256-GCM key and nonce. RSA-OAEP with SHA-256 wraps the AES key
for the researcher. Run the interoperability check with Node.js 22 or later:

```sh
node tests/donation-crypto.mjs
```

Decrypt on a separate research machine with the matching RSA private key
in PEM form. The decryptor refuses to overwrite an existing output.

```sh
node tools/decrypt-donation.mjs private-key.pem donation.json subset.bin
```

These components are not called by the active study application yet.
