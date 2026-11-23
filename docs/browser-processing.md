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

The original chart definitions are in `tools/webr-probe/browser-charts.R`.
The probe exercises them with the bundled synthetic chat in webR. The study
app still uses the legacy server-side processing flow until browser processing
can be integrated while retaining its existing workflow and donation format.
