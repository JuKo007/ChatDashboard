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
