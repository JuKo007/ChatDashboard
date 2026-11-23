const button = document.querySelector("#run");
const result = document.querySelector("#result");

const fixtures = {
  android: [
    "12.11.25, 15:10 - Alice: I consent",
    "12.11.25, 15:11 - Alice: Synthetic message",
    "A continued line",
    "12.11.25, 15:12 - Bob: Excluded marker",
  ],
  ios: [
    "[12.11.25, 15:10:00] Alice: I consent",
    "[12.11.25, 15:11:00] Alice: Synthetic message",
    "A continued line",
    "[12.11.25, 15:12:00] Bob: Excluded marker",
  ],
};

button.addEventListener("click", async () => {
  button.disabled = true;
  result.textContent = "Loading webR and the patched WhatsR package…";
  let webR;

  try {
    const { WebR } = await import("./runtime/webr.mjs");
    webR = new WebR({
      baseUrl: new URL("./runtime/", location.href).href,
      repoUrl: new URL("./packages/", location.href).href,
      interactive: false,
    });
    await webR.init();
    await webR.installPackages(["WhatsR"]);
    await webR.evalRVoid(`
      loadNamespace("WhatsR")
      stopifnot(!"rJava" %in% loadedNamespaces())
    `);

    for (const file of ["browser-parser.R", "browser-charts.R"]) {
      const response = await fetch(new URL(file, import.meta.url));
      if (!response.ok) throw new Error("Browser R script unavailable.");
      await webR.evalRVoid(await response.text());
    }
    result.textContent = "";
    for (const [os, lines] of Object.entries(fixtures)) {
      const path = "/" + os + ".txt";
      await webR.FS.writeFile(path, new TextEncoder().encode(lines.join("\n") + "\n"));
      try {
        await webR.evalRVoid(`
          probe_chat <- local({
            parsed <- parse_export("${path}", list(platform = "${os}", language = "english", consent = "I consent"))
            stopifnot(
              any(grepl("Synthetic message", parsed$Message, fixed = TRUE)),
              any(grepl("A continued line", parsed$Message, fixed = TRUE)),
              !any(grepl("Excluded marker", parsed$Message, fixed = TRUE))
            )
            parsed
          })
        `);
      } finally {
        await webR.FS.unlink(path);
      }
      result.textContent += os + ": parser and consent filtering passed.\n";
    }

    const shelter = await new webR.Shelter();
    try {
      const captures = await shelter.captureR(`
        local({
          result <- legacy_chart("message1", probe_chat, list(senders = "Alice",
                                 start = "2025-11-12", end = "2025-11-12"))
          print(result)
        })
      `);
      if (!captures.images.length) throw new Error("No plot was captured.");
      for (const image of captures.images) image.close();
      result.textContent += "Legacy message chart rendered in webR.\n";
    } finally {
      await shelter.purge();
    }
  } catch (error) {
    result.textContent += "\nCheck failed: " + error.message;
  } finally {
    webR?.close();
    button.disabled = false;
  }
});
