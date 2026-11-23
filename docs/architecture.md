# ChatDashboard architecture

| Path | Responsibility |
| --- | --- |
| `app.R` | Shiny entry point and local launch settings |
| `R/setup.R` | Study, authentication, and storage configuration |
| `R/ui.R` | GESIS layout, login wrapper, and browser workflow markup |
| `R/server.R` | Login, public study configuration, encrypted-envelope validation and storage |
| `www/js/browser-study.mjs` | Browser file picker, participant selection, local table, and encrypted submission |
| `www/js/browser-parser.R` | Calls WhatsR in webR and serializes the approved subset |
| `www/js/donation-crypto.mjs` | Browser encryption |
| `tools/decrypt-donation.mjs` | Offline researcher decryption |

The server app has no file-upload control. The browser's file picker is detached
from the DOM so Shiny cannot bind it. The file and parsed chat live in browser
memory. Only the confirmation handler sends the encrypted envelope to Shiny.
