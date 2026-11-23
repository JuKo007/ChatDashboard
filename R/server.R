server <- function(input, output, session) {
  check_local_credentials <- shinymanager::check_credentials(credentials)
  check_study_credentials <- function(user, password) {
    id <- if (use_forwarding && nzchar(forwarding_password)) {
      isolate(parseQueryString(session$clientData$url_search)[["id"]])
    }
    if (length(id) == 1L && nzchar(id) && identical(user, id) &&
        identical(password, forwarding_password)) {
      return(list(result = TRUE, expired = FALSE, user_info = list(user = id, admin = FALSE)))
    }
    check_local_credentials(user, password)
  }

  auth <- shinymanager::secure_server(check_credentials = check_study_credentials)

  output$browser_study_config <- renderUI({
    req(auth$user)
    public_key <- ""
    if (save_to_server && file.exists(study_public_key_path)) {
      bytes <- readBin(study_public_key_path, "raw", n = 4096L)
      public_key <- jsonlite::base64_enc(bytes)
    }
    tags$div(
      id = "study-browser-config", hidden = NA,
      `data-study-id` = auth$user,
      `data-consent` = if (is.na(consent_message)) "" else consent_message,
      `data-save` = if (save_to_server) "yes" else "no",
      `data-public-key` = public_key
    )
  })

  observeEvent(input$encrypted_donation, {
    req(auth$user, isTRUE(save_to_server))
    envelope <- input$encrypted_donation
    reply <- function(ok) session$sendCustomMessage("study-donation-receipt", list(ok = ok))

    if (!is.list(envelope) || !identical(sort(names(envelope)),
        c("ciphertext", "nonce", "version", "wrappedKey")) ||
        length(envelope$version) != 1L || !is.numeric(envelope$version) ||
        !isTRUE(envelope$version == 1) ||
        !valid_base64(envelope$nonce, 16L, 16L) ||
        !valid_base64(envelope$wrappedKey, 344L, 684L) ||
        !valid_base64(envelope$ciphertext, 24L, 24L * 1024^2)) {
      reply(FALSE)
      return()
    }

    tryCatch({
      # Rebuild the envelope so only the expected fields can be persisted.
      envelope <- list(version = 1L, nonce = envelope$nonce,
                       wrappedKey = envelope$wrappedKey, ciphertext = envelope$ciphertext)
      persist_envelope(envelope)
      reply(TRUE)
    }, error = function(error) {
      warning("Could not persist encrypted donation.", call. = FALSE)
      reply(FALSE)
    })
  })
}

valid_base64 <- function(value, min_length, max_length) {
  is.character(value) && length(value) == 1L && !is.na(value) &&
    nchar(value, type = "bytes") >= min_length &&
    nchar(value, type = "bytes") <= max_length &&
    nchar(value, type = "bytes") %% 4L == 0L &&
    grepl("^[A-Za-z0-9+/]+={0,2}$", value, perl = TRUE)
}

persist_envelope <- function(envelope) {
  dir.create("UserData", showWarnings = FALSE, mode = "0700")
  text <- jsonlite::toJSON(envelope, auto_unbox = TRUE)
  target <- file.path("UserData", paste0(digest::digest(as.character(text), algo = "sha256"), ".json"))
  if (file.exists(target)) return(invisible(NULL))

  temp <- tempfile(".donation-", tmpdir = "UserData")
  on.exit(unlink(temp), add = TRUE)
  file.create(temp, showWarnings = FALSE)
  Sys.chmod(temp, "0600")
  writeLines(text, temp, useBytes = TRUE)
  if (!file.rename(temp, target) && !file.exists(target)) stop("Cannot store donation.")
  invisible(NULL)
}
