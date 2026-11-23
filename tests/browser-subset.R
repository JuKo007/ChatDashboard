source("www/js/browser-parser.R")
chat <- data.frame(
  DateTime = as.POSIXct(c("2025-01-01", "2025-01-02"), tz = "UTC"),
  Sender = c("private-name", "excluded-name"),
  Sender_anon = c("Person_1", "Person_2"),
  Message = c("private-text", "excluded-text"),
  TokCount = c(2, 999)
)
rownames(chat) <- c("1000", "2000")
attr(chat, "parsedAt") <- as.POSIXct("2025-01-03", tz = "UTC")
attr(chat, "language") <- "german"
attr(chat, "detectedOS") <- "android"
settings <- list(fields = c("Zeit", "Absender", "Absender_anonym", "Nachricht", "Wortanzahl"),
                 excluded = c("Absender", "Nachricht"), clientOS = "Windows", clientDevice = "Desktop")
pick <- list(rows = 1L, columns = settings$fields, alias = "Person_1")
path <- tempfile()
serialize_donation(chat, pick, settings, path)
donation <- readRDS(path)
stopifnot(identical(names(donation), c("Zeit", "Absender_anonym", "Wortanzahl")),
          identical(rownames(donation), "1000"), identical(donation$Wortanzahl, 2),
          identical(attr(donation, "donor"), "Person_1"),
          identical(attr(donation, "parsedAt"), attributes(chat)["parsedAt"]),
          identical(attr(donation, "language"), attributes(chat)["language"]),
          identical(attr(donation, "detectedOS"), attributes(chat)["detectedOS"]),
          identical(attr(donation, "clientOS"), "Windows"),
          identical(attr(donation, "clientDevice"), "Desktop"),
          is.null(attr(donation, "study_id")))
settings$excluded <- "Absender"
serialize_donation(chat, pick, settings, path)
stopifnot(identical(readRDS(path)$Nachricht, "private-text"))
unlink(path)
