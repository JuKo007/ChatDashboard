library(shiny)
library(shinythemes)

landing_page_language <- "de"
consent_message <- NA_character_
use_forwarding <- TRUE
save_to_server <- TRUE

# The server receives a Base64-encoded encrypted envelope, with no file upload.
options(shiny.maxRequestSize = 32 * 1024^2)
credentials <- readRDS("credentials.rds")
forwarding_password <- Sys.getenv("CHATDASHBOARD_FORWARDING_PASSWORD")
study_public_key_path <- Sys.getenv("CHATDASHBOARD_PUBLIC_KEY", "ServerFolder/study-public.der")

# Display names and fields excluded from the donation, in WhatsR parser order.
Colnames_ppt_display <- c("Zeit",
                          "Absender",
                          "Absender_anonym",
                          "Nachricht",
                          "Nachricht_vereinfacht",
                          "Worte",
                          "Links",
                          "Links_anonym",
                          "Medien",
                          "Medien_anonym",
                          "Standorte",
                          "Standorte_anonym",
                          "Emoji",
                          "Emoji_beschreibung",
                          "Smilies",
                          "System_info",
                          "Wortanzahl",
                          "Nummerierung_zeit",
                          "Nummerierung_anzeige")

# Set column names to be automatically excluded because they can contain PII (must occur in Colnames_ppt_display)
Colnames_exclude_pii <- c("Absender",
                          "Nachricht",
                          "Nachricht_vereinfacht",
                          "Worte",
                          "Links",
                          "Medien",
                          "Standorte",
                          "System_info")
