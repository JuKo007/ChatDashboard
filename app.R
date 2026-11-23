# Load application files into the same environment in dependency order.
source("R/setup.R", local = TRUE, encoding = "UTF-8")
source("R/ui.R", local = TRUE, encoding = "UTF-8")
source("R/server.R", local = TRUE, encoding = "UTF-8")

##################################### RUNNING APPLICATION ####
# Enable only when testing from another device on the same network.
mobile_testing <- FALSE

if (mobile_testing) {
  options(shiny.host = "0.0.0.0", shiny.port = 8080)
} else {
  options(shiny.host = "127.0.0.1", shiny.port = NULL)
}

shinyApp(ui = ui, server = server)