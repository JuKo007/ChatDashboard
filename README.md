# ChatDashboard

ChatDashboard is a GESIS Puls Shiny app for reviewing a WhatsApp export and
donating selected data. The study server authenticates participants and stores
encrypted donations. The existing WhatsR parser runs in webR on the participant's
device.

## Run locally

Install the server dependencies in R:

```r
install.packages(c("shiny", "shinymanager", "shinythemes", "htmltools", "jsonlite", "digest"))
```

Configure `credentials.rds` at the repository root as a shinymanager credential
data frame. For local testing of the UI, set `save_to_server <- FALSE` in
`R/setup.R`. Prepare the browser runtime as described below, then open `app.R`
or run `shiny::runApp(".")` from the repository root.

See [browser processing and deployment](docs/browser-processing.md) for building
the browser packages, configuring encryption, conducting the browser acceptance
check, and recovering a donation offline. See [architecture](docs/architecture.md)
for the repository layout.

## Citation

Kohne, J., & Montag, C. (2024). ChatDashboard: A framework to collect, link, and
process donated WhatsApp chat log data. *Behavior Research Methods*, 56,
3658–3684. https://doi.org/10.3758/s13428-023-02276-1
