# Browser processing and deployment

## Prepare webR

1. Place a pinned [webR browser release](https://github.com/r-wasm/webr/releases)
   in `www/webr/runtime/`, including `webr.mjs`, the worker, and runtime assets.
2. Check out and patch the pinned WhatsR source as described in [the WhatsR
   build instructions](whatsr.md). Use the matching webR release's Wasm build
   environment to prepare the local repository:

   ```r
   rwasm::add_pkg(
     c(paste0("local::", normalizePath("WhatsR-build")), "jsonlite"),
     repo_dir = "www/webr/packages", dependencies = NA
   )
   ```

   See the [rwasm build guide](https://r-wasm.github.io/rwasm/articles/rwasm.html).
   Serve both directories on the app's origin. Serve WebAssembly with
   `application/wasm` and JavaScript modules with a JavaScript MIME type.
3. Test on `localhost` or deploy behind HTTPS. A phone connecting to a plain
   HTTP LAN address cannot use browser encryption. If the runtime or packages
   are missing, chat processing stops in the browser.

## Configure storage and authentication

Generate a dedicated RSA study key on the separate analysis machine:

```sh
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out study-private.pem
openssl pkey -in study-private.pem -pubout -outform DER -out study-public.der
```

Copy only `study-public.der` to `ServerFolder/` on the app server, or set
`CHATDASHBOARD_PUBLIC_KEY` to its path. Keep the private key on the analysis
machine. Configure preset logins in `credentials.rds`. For survey-link login,
set `CHATDASHBOARD_FORWARDING_PASSWORD` in the server process environment.
Forwarding requires a matching `?id=...` and password. Without the environment
variable, preset logins remain available.

The app writes versioned JSON envelopes in `UserData/`. It atomically renames
a temporary file and uses the participant ID, timestamp, and an encrypted
envelope fingerprint in the filename. The participant ID stays in the filename,
as in the original app. After offline decryption, the RDS data frame uses the
same display column names and attributes as before, including `donor`,
`parsedAt`, `language`, `detectedOS`, `clientOS`, and `clientDevice`.
With `save_to_server <- FALSE` the local review and charts still run and
the app never sends a donation.

## Configure fields and review

Researchers control the available fields and donation exclusions in `R/setup.R`.
`Colnames_ppt_display` maps the parser's columns in their original order.
`Colnames_exclude_pii` identifies columns that may appear in the participant
preview but must be removed before donation. The browser applies that exclusion
again when writing the selected rows and columns to RDS.

All 14 original charts run locally in webR from the full parsed chat with the
original WhatsR chart functions. Sender, date range, and applicable frequency
filters operate in the browser. The chart data and images are never submitted.

The server validates the envelope shape and stores ciphertext without a private
key. This protects against disclosure from the donation store and from the
normal app workflow. It assumes participants receive the intended frontend code
and public key. Shiny itself is a general-purpose server. If deployed behind a
proxy, reject incoming multipart bodies and avoid logging request bodies. The
public web app cannot prove to an independent client that its serving operator
has not changed the code.

## Verify before participant use

- Run `node tests/donation-crypto.mjs` and `node tests/browser-selection.mjs`.
- Run `Rscript tests/browser-subset.R` with the patched WhatsR installed.
- Use the synthetic [webR probe](../tools/webr-probe/) to confirm Android and iOS
  parsing against the same runtime and package repository.
- In the real app, use synthetic Android and iOS TXT and ZIP exports with distinct
  markers in display names, messages, and rows to exclude. Capture network requests
  and WebSocket frames, including immediately after choosing a file and when
  retrying a failed save. Verify no file, filename, names, or excluded content
  leaves the browser. Verify there is no upload request, including in no-save mode.
- Decrypt the resulting donation and check that it contains exactly the approved
  rows and fields with the original field names, row names, and metadata. Check that the server has only
  the encrypted envelope and public key. Test an unavailable runtime and key,
  no-save mode, and mobile browsers over HTTPS.

## Decrypt and import offline

With Node.js 22 or later and the corresponding private key:

```sh
node tools/decrypt-donation.mjs /secure/study-private.pem donation.json subset.rds
```

Load `subset.rds` with `readRDS()` on the separate analysis machine.
