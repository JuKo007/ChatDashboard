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

serialize_donation <- function(chat, pick, path) {
  allowed <- c("DateTime", "Sender_anon", "Emoji", "EmojiDescriptions", "Smilies", "TokCount")
  stopifnot(length(pick$columns) > 0L, all(pick$columns %in% allowed),
            length(pick$rows) > 0L, all(pick$rows %in% seq_len(nrow(chat))),
            grepl("^Person_[0-9]+$", pick$alias),
            pick$alias %in% as.character(chat$Sender_anon))

  # Construct a new data frame to avoid carrying parser attributes or original row IDs.
  columns <- lapply(pick$columns, function(name) {
    values <- chat[[name]][pick$rows]
    if (name == "DateTime") return(as.POSIXct(as.numeric(values), origin = "1970-01-01", tz = "UTC"))
    if (name == "TokCount") return(as.numeric(values))
    if (name == "Sender_anon") {
      aliases <- as.character(values)
      aliases[!is.na(aliases) & !grepl("^Person_[0-9]+$", aliases)] <- NA_character_
      return(aliases)
    }
    I(lapply(values, as.character))
  })
  names(columns) <- pick$columns
  subset <- as.data.frame(columns, stringsAsFactors = FALSE)
  attr(subset, "donor") <- pick$alias
  attr(subset, "study_id") <- pick$studyId
  saveRDS(subset, path)
}
