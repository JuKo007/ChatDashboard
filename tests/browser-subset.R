source("www/js/browser-parser.R")
chat <- data.frame(
  DateTime = as.POSIXct(c("2025-01-01", "2025-01-02"), tz = "UTC"),
  Sender = c("private-name", "excluded-name"),
  Sender_anon = c("Person_1", "Person_2"),
  Message = c("private-text", "excluded-text"),
  TokCount = c(2, 999)
)
rownames(chat) <- c("1000", "2000")
attr(chat, "private") <- "private attribute"
path <- tempfile()
pick <- list(rows = 1L, columns = c("Sender_anon", "TokCount"), alias = "Person_1", studyId = "test")
serialize_donation(chat, pick, path)
donation <- readRDS(path)
stopifnot(identical(names(donation), pick$columns), nrow(donation) == 1L,
          identical(rownames(donation), "1"), identical(donation$TokCount, 2),
          identical(attr(donation, "donor"), "Person_1"),
          is.null(attr(donation, "private")))
pick$columns <- "Message"
stopifnot(inherits(try(serialize_donation(chat, pick, path), silent = TRUE), "try-error"))
unlink(path)
