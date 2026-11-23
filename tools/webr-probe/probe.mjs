const button = document.querySelector("#run");
const result = document.querySelector("#result");

const fixtures = {
  android: [
    "12.11.2025, 15:10 - Alice: I consent",
    "12.11.2025, 15:11 - Alice: Synthetic message",
    "A continued line",
    "12.11.2025, 15:12 - Bob: Excluded marker",
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

    result.textContent = "";
    for (const [os, lines] of Object.entries(fixtures)) {
      const path = "/" + os + ".txt";
      await webR.FS.writeFile(path, new TextEncoder().encode(lines.join("\n") + "\n"));
      try {
        await webR.evalRVoid(`
          local({
            parsed <- WhatsR::parse_chat(
              path = "${path}", os = "${os}", language = "english",
              anonymize = "add", consent = "I consent"
            )
            stopifnot(
              any(grepl("Synthetic message", parsed$Message, fixed = TRUE)),
              any(grepl("A continued line", parsed$Message, fixed = TRUE)),
              !any(grepl("Excluded marker", parsed$Message, fixed = TRUE))
            )
          })
        `);
      } finally {
        await webR.FS.unlink(path);
      }
      result.textContent += os + ": parser and consent filtering passed.\n";
    }
  } catch (error) {
    result.textContent += "\nCheck failed: " + error.message;
  } finally {
    webR?.close();
    button.disabled = false;
  }
});
