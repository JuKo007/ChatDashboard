###################################################################################### CHATDASHBOARD SETUP #####

################################### LOADING LIBRARIES ####
library(anytime)
library(crosstalk)
library(cyphr)
library(digest)
library(DT)
library(fontawesome)
library(ggplot2)
library(ggwordcloud)
library(keyring)
library(rsconnect)
library(shiny)
library(shinymanager)
library(shinythemes)
library(shinyjs)
library(shinyalert)
library(shinyTime)
library(shinyWidgets)
library(utils)
library(waiter)
library(WhatsR)
library(shinybrowser)




###################################  LANGUAGE SETTINGS ####

# language setting for shinymanager authentication page
# see: https://datastorm-open.github.io/shinymanager/reference/use_language.html
landing_page_language <- "de"

# Check: https://cdn.datatables.net/plug-ins/1.10.11/i18n/ for a 
# list of different languages. Insert them by pasting the respective
# link according to the format below
datatable_language <- c('//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json')

# import display text from csv file
ChatDashboard_DisplayText <- read.csv("./www/ChatDashboard_DisplayText.csv")

# Selecting column containing the text you want to display. English and German are preset options 
display_text <- ChatDashboard_DisplayText$German

# For changing the display of individual text variables, you can simply edit the file
# ./www/ChatDashboard_DisplayText.csv, add an additional column, and select it above.





###################################  SHINY SETTINGS ####

# Variable passed to WhatsR::parse_chat(). Automatically removes all chat messages from participants that did not post the EXACT consent_message into
# the chat. Setting this variable to NA will not remove any messages.
consent_message <- NA

# variable to control whether to use forwarding per url parameter or rely on pre-defined credentials for authentication
# TODO: If you are using url parameter forwarding, you need to adapt line 879 to extract the participant ID from your referral link.
# Default structure is: www.example-website.com/ChatDashboard?id=TestParticipant | Extracts: TestParticipant
use_forwarding <- TRUE 

# Password to use for forwarding via url-parameter (only used if use_forwarding == TRUE)
# TODO: Set this as a character string in line 880

# saving donated files to server if TRUE, will not save any data if not TRUE
save_to_server <- TRUE

# setting upload file size limit
options(shiny.maxRequestSize = 50*1024^2)

# Set column names to be displayed to participants. This needs to be exactly 19 strings
# and does not determine whether these variables are displayed or not, but just how they are named
# in the display to participants
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




# Shiny Debugging Options (uncomment these to debug the app)
options(shiny.session.inactivityTimeout = 2*60*60*1000) # Session Inactivity Timeout
# options(shiny.error = browser)
# options(shiny.trace = TRUE)

# --- per-user CSV logger (append-only, no IP/path) ---
log_event <- function(event, session) {
  user <- parseQueryString(session$clientData$url_search)[["id"]]
  if (is.null(user) || user == "") user <- "unknown_user"
  log_path <- file.path("ClosingReasons", paste0("usage_log_", user, ".csv"))
  dir.create(dirname(log_path), showWarnings = FALSE, recursive = TRUE)
  
  row <- data.frame(
    timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    event   = event,
    username = user,
    device  = shinybrowser::get_device(),
    browser = shinybrowser::get_browser(),
    stringsAsFactors = FALSE
  )
  
  write.table(row, file = log_path, sep = ",", row.names = FALSE,
              col.names = !file.exists(log_path), append = TRUE)
}


################################### HANDLING SHINY MANAGER CREDENTILAS ####

# Switch for running local (FALSE) vs online (TRUE)
running_online = FALSE

if (running_online == TRUE) {.libPaths("YOUR-LIB-PATH-HERE")}
# TODO: Add library path of server here if running online

# loading credentials from external file
credentials <- readRDS("credentials.rds")


################################### MAKING FONT FOR EMOJI PLOTTING AVAILABLE ####
if (file.exists("~/.fonts/NotoColorEmoji.ttf")) {
  
  system('fc-cache -f ~/.fonts')
  
} else {
  
  dir.create('~/.fonts')
  file.copy("www/NotoColorEmoji.ttf", "~/.fonts")
  system('fc-cache -f ~/.fonts')
  
}




################################### DEFINING WAITING SCREENS ####
waiting_screen1 <- tagList(
  spin_flower(),
  h4(style = "color:#fff;margin-top:12px;",
     HTML(gsub("\\\\n", "<br/>", display_text[1])))
)

waiting_screen2 <- tagList(
  spin_flower(),
  h4(style = "color:#fff;margin-top:12px;",
     HTML(gsub("\\\\n", "<br/>", display_text[2])))
)



