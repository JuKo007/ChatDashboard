# ChatDashboard architecture

Run the application from the repository root with `shiny::runApp(".")`.

| Path | Responsibility |
| --- | --- |
| `app.R` | Loads the application files, configures local or mobile testing, and creates the Shiny app. |
| `R/setup.R` | Package loading, study and language settings, credentials, and shared helpers. |
| `R/ui.R` | GESIS page layout, participant screens, and the login layout. |
| `R/server.R` | Session handling, donation workflow, and results. |
| `www/` | Static assets and participant-facing text. |

The entry point sources the three R files in order into the app environment. The
`R/_disable_autoload.R` marker prevents Shiny from sourcing them a second time.
Edit the study configuration in `R/setup.R`. Edit `mobile_testing` in `app.R` to
enable testing from a second device on the same network.
