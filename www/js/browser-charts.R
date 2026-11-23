# Original ChatDashboard chart definitions, evaluated by webR only.
legacy_chart <- function(chart, chat, filters) {
  switch(chart,
    message1 = {
      WhatsR::plot_messages(
        chat,
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59")
      ) + ggplot2::labs(title = "Nachrichtenanzahl", x = "Absender", y = "Nachrichten") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 2, byrow = TRUE)
        )
    },
    tokensbwah1 = {
      WhatsR::plot_tokens(
        chat,
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        plot      = "cumsum"
      ) + ggplot2::labs(title = "Wortanzahl (kumuliert)", x = "Datum", y = "Wörter (kumuliert)") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 2, byrow = TRUE)
        )
    },
    tokensbwah2 = {
      WhatsR::plot_tokens_over_time(
        chat,
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        plot      = "heatmap"
      ) + ggplot2::labs(title = "Wörter – Aktivität nach Tageszeit", x = "Uhrzeit", y = "Wochentag", fill = "Wörter")
    },
    links1 = {
      WhatsR::plot_links(
        chat,
        plot      = "cumsum",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Geteilte Links (kumuliert)", x = "Datum", y = "Links (kumuliert)") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 3, byrow = TRUE)
        )
    },
    links2 = {
      WhatsR::plot_links(
        chat,
        plot      = "heatmap",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Links – Aktivität nach Tageszeit", x = "Uhrzeit", y = "Wochentag", fill = "Links")
    },
    links4 = {
      WhatsR::plot_links(
        chat,
        plot      = "splitbar",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Häufigste Domains", x = "Absender", y = "Häufigkeit") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 2, byrow = TRUE)
        )
    },
    smilies1 = {
      WhatsR::plot_smilies(
        chat,
        plot      = "cumsum",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Smilies (kumuliert)", x = "Datum", y = "Smilies (kumuliert)") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 3, byrow = TRUE)
        )
    },
    smilies2 = {
      WhatsR::plot_smilies(
        chat,
        plot      = "heatmap",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Smilies – Aktivität nach Tageszeit", x = "Uhrzeit", y = "Wochentag", fill = "Smilies")
    },
    smilies4 = {
      WhatsR::plot_smilies(
        chat,
        plot      = "splitbar",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Smilies nach Sender", x = "Absender", y = "Anzahl") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 3, byrow = TRUE)
        )
    },
    emoji1 = {
      WhatsR::plot_emoji(
        chat,
        plot      = "cumsum",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Emoji (kumuliert)", x = "Datum", y = "Emoji (kumuliert)") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 3, byrow = TRUE)
        )
    },
    emoji2 = {
      WhatsR::plot_emoji(
        chat,
        plot      = "heatmap",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Emoji – Aktivität nach Tageszeit", x = "Uhrzeit", y = "Wochentag", fill = "Emoji")
    },
    emoji4 = {
      WhatsR::plot_emoji(
        chat,
        plot      = "splitbar",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59"),
        min_occur = filters$minimum
      ) + ggplot2::labs(title = "Emoji nach Sender", x = "Absender", y = "Häufigkeit") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 2, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 2, byrow = TRUE)
        )
    },
    replytime1 = {
      WhatsR::plot_replytimes(
        chat,
        type      = "replytime",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59")
      ) + ggplot2::labs(title = "Antwortzeiten", x = "Minuten", y = "Log(Minuten) + 1") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 3, byrow = TRUE)
        )
    },
    replytime2 = {
      WhatsR::plot_replytimes(
        chat,
        type      = "reactiontime",
        names     = filters$senders,
        starttime = paste(filters$start, "00:00"),
        endtime   = paste(filters$end, "23:59")
      ) + ggplot2::labs(title = "Reaktionszeiten", x = "Minuten", y = "Log(Minuten) + 1") +
        ggplot2::theme(legend.position = "bottom", legend.box = "horizontal") +
        ggplot2::guides(
          color   = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          fill    = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          linetype = ggplot2::guide_legend(ncol = 3, byrow = TRUE),
          shape   = ggplot2::guide_legend(ncol = 3, byrow = TRUE)
        )
    },
    stop("Unknown chart.")
  )
}
