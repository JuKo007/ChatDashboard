gesis_page_styles <- tagList(
  tags$link(rel = "stylesheet", href = "package/dist/gesis-web.css"),
  tags$link(rel = "stylesheet", href = "css/study.css")
)
gesis_footer <- includeHTML("www/gesis-footer.html")

app_ui <- fluidPage(
  theme = shinytheme("flatly"),
  tags$head(
    gesis_page_styles,
    tags$link(rel = "stylesheet", href = "css/browser-study.css"),
    tags$script(type = "module", src = "js/browser-study.mjs")
  ),
  tags$div(
    class = "study-shell",
    tags$header(
      tags$div(id = "gesis-micro-header", includeHTML("www/gesis-micro-header.html")),
      includeHTML("www/gesis-microsite-banner.html")
    ),
    tags$main(
      class = "browser-study",
      uiOutput("browser_study_config"),
      tags$section(
        class = "study-main", id = "browser-open",
        tags$h1("WhatsApp-Datenspende"),
        tags$p("Sie öffnen und bearbeiten Ihren Chatverlauf hier im Browser. Erst wenn Sie Ihre Auswahl bestätigen, wird die verschlüsselte Spende übermittelt."),
        tags$details(
          tags$summary("Chat ohne Medien exportieren"),
          tags$ol(
            tags$li("Android: Chat öffnen und ⋮ → Mehr → Chat exportieren wählen."),
            tags$li("iPhone: Chat öffnen, auf den Chatnamen tippen und Chat exportieren wählen."),
            tags$li("Ohne Medien wählen und die TXT- oder ZIP-Datei auf diesem Gerät speichern.")
          )
        ),
        tags$div(
          class = "browser-study-fields",
          tags$label("Gerät", tags$select(id = "browser-platform",
            tags$option(value = "android", "Android"), tags$option(value = "ios", "iPhone"))),
          tags$label("Sprache des Exports", tags$select(id = "browser-language",
            tags$option(value = "german", "Deutsch"), tags$option(value = "english", "English")))
        ),
        tags$button(id = "browser-choose", type = "button", class = "btn btn-default",
                    "Chatdatei auswählen"),
        tags$p(id = "browser-filename", role = "status", "Keine Datei ausgewählt"),
        tags$button(id = "browser-parse", type = "button", class = "btn study-primary", "Chat öffnen"),
        tags$noscript("Diese Seite benötigt JavaScript, um den Chat im Browser zu verarbeiten.")
      ),
      tags$p(id = "browser-status", role = "status", `aria-live` = "polite"),
      tags$section(
        class = "study-main", id = "browser-person", hidden = NA,
        tags$h2("Wer sind Sie im Chat?"),
        tags$p("Wählen Sie die Karte über Ihrem Namen. Die Spende verwendet Ihre Kennung."),
        tags$fieldset(
          tags$legend(class = "sr-only", "Person im Chat"),
          tags$div(id = "browser-people")
        ),
        tags$button(id = "browser-next", type = "button", class = "btn study-primary",
                    disabled = NA, "Weiter")
      ),
      tags$section(
        class = "study-main", id = "browser-review", hidden = NA,
        tags$h2("Datenspende prüfen"),
        tags$p("Markieren Sie die Zeilen und Merkmale, die Sie spenden möchten. Die Nachrichtenvorschau dient nur der Orientierung."),
        tags$fieldset(tags$legend("Merkmale"), tags$div(id = "browser-columns")),
        tags$p(id = "browser-count", role = "status"),
        tags$div(class = "browser-table-scroll", tabindex = "0",
                 role = "region", `aria-label` = "Vorschau des Chatverlaufs",
                 tags$table(id = "browser-table")),
        tags$div(class = "browser-study-actions",
                 tags$button(id = "browser-prev-page", type = "button", class = "btn btn-default", "Zurück"),
                 tags$span(id = "browser-page"),
                 tags$button(id = "browser-next-page", type = "button", class = "btn btn-default", "Nächste Seite")),
        tags$button(id = "browser-donate", type = "button", class = "btn study-primary", "Auswahl bestätigen"),
        tags$dialog(id = "browser-confirm",
          tags$h2("Auswahl bestätigen"),
          tags$p(id = "browser-confirm-text"),
          tags$button(id = "browser-cancel", type = "button", class = "btn btn-default", "Zurück"),
          tags$button(id = "browser-send", type = "button", class = "btn study-primary", "Daten spenden"))
      ),
      tags$section(
        class = "study-main", id = "browser-results", hidden = NA,
        tags$h2("Ihre Chatstatistik"),
        tags$p("Diese Übersicht wird aus Ihrer Auswahl berechnet."),
        tags$dl(id = "browser-totals"),
        tags$button(id = "browser-clear", type = "button", class = "btn btn-default", "Chat schließen")
      ),
      tags$p(class = "browser-study-contact",
        tags$a(href = "mailto:puls@gesis.org", "Kontakt zur Studie"))
    ),
    gesis_footer
  )
)
# Let shinymanager build the login form, then add branding around its card.
secure_ui <- shinymanager::secure_app(
  app_ui,
  language = landing_page_language,
  head_auth = gesis_page_styles
)

gesis_login_header <- tags$header(
  class = "gesis-login-header",
  tags$div(id = "gesis-micro-header", includeHTML("www/gesis-micro-header.html")),
  includeHTML("www/gesis-microsite-banner.html")
)

ui <- function(request) {
  page <- secure_ui(request)
  login <- htmltools::tagQuery(page)$find("#auth-auth-mod.panel-auth")
  if (login$length() == 0) return(page)

  login$
    addClass("gesis-login")$
    prepend(gesis_login_header)$
    append(gesis_footer)$
    allTags()
}
