loadNamespace("WhatsR")
stopifnot(!"rJava" %in% loadedNamespaces())

parse_export <- function(upload, settings) {
  if (grepl("[.]zip$", upload)) {
    entries <- utils::unzip(upload, list = TRUE)
    names <- gsub("\\\\", "/", entries$Name)
    if (!length(names) || any(grepl("(^/|^[A-Za-z]:|(^|/)[.][.](/|$))", names)) ||
        sum(entries$Length) > 50 * 1024^2) {
      stop("Unsupported archive.")
    }
  }
  WhatsR::parse_chat(
    path = upload, os = settings$platform, language = settings$language,
    anonymize = "add", consent = if (nzchar(settings$consent)) settings$consent else NA_character_
  )
}

preview_json <- function(chat, display_names) {
  stopifnot(length(display_names) == ncol(chat), !anyDuplicated(display_names))
  preview <- chat
  names(preview) <- display_names
  jsonlite::toJSON(preview, dataframe = "rows", na = "null", POSIXt = "ISO8601")
}

serialize_donation <- function(chat, pick, settings, path) {
  stopifnot(length(settings$fields) == ncol(chat), !anyDuplicated(settings$fields),
            length(pick$rows) > 0L, all(pick$rows %in% seq_len(nrow(chat))),
            grepl("^Person_[0-9]+$", pick$alias),
            pick$alias %in% as.character(chat$Sender_anon))

  parser_metadata <- attributes(chat)[c("parsedAt", "language", "detectedOS")]
  names(chat) <- settings$fields
  columns <- setdiff(intersect(pick$columns, names(chat)), settings$excluded)
  stopifnot(length(columns) > 0L)
  subset <- chat[pick$rows, columns, drop = FALSE]

  attr(subset, "donor") <- pick$alias
  for (name in names(parser_metadata)) {
    attr(subset, name) <- parser_metadata[name]
  }
  attr(subset, "clientOS") <- settings$clientOS
  attr(subset, "clientDevice") <- settings$clientDevice
  saveRDS(subset, path)
}
