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
