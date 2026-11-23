import { encryptDonation } from "./donation-crypto.mjs";
import { fields, selection } from "./donation-selection.mjs";

const el = id => document.getElementById("browser-" + id);
const pageSize = 25;
// Shiny binds every file input attached to the document. Keep this one detached.
const picker = document.createElement("input");
picker.type = "file";
picker.accept = ".txt,.zip";
let chosenFile;
el("choose").addEventListener("click", () => picker.click());
picker.addEventListener("change", () => {
  chosenFile = picker.files[0];
  el("filename").textContent = chosenFile?.name ?? "Keine Datei ausgewählt";
});
let webR, rows = [], alias = "", page = 0, included = new Set(), pendingEnvelope, awaitingReceipt, receiptTimer;

const status = message => { el("status").textContent = message; };
const show = (section, focus = true) => {
  for (const id of ["open", "person", "review", "results"]) el(id).hidden = id !== section;
  if (focus) {
    const heading = el(section).querySelector("h1, h2");
    heading.tabIndex = -1;
    heading.focus();
  }
};

async function boot() {
  const baseUrl = new URL("../webr/runtime/", import.meta.url);
  const repoUrl = new URL("../webr/packages/", import.meta.url);
  const { WebR, ChannelType } = await import(new URL("webr.mjs", baseUrl));
  const runtime = new WebR({ baseUrl: baseUrl.href, repoUrl: repoUrl.href,
    channelType: ChannelType.PostMessage, interactive: false, downloadTimeout: 30000 });
  try {
    await runtime.init();
    await runtime.installPackages(["WhatsR", "jsonlite"]);
    const response = await fetch(new URL("./browser-parser.R", import.meta.url));
    if (!response.ok) throw new Error("Parser script unavailable.");
    await runtime.evalRVoid(await response.text());
    return runtime;
  } catch (error) {
    runtime.close();
    throw error;
  }
}

const settings = () => document.getElementById("study-browser-config")?.dataset;
const rJsonFile = async (path, value) => {
  await webR.FS.writeFile(path, new TextEncoder().encode(JSON.stringify(value)));
};

el("parse").addEventListener("click", async () => {
  const file = chosenFile;
  const extension = file?.name.match(/\.(txt|zip)$/i)?.[1].toLowerCase();
  const config = settings();
  if (!config) return status("Ihre Sitzung ist noch nicht bereit. Versuchen Sie es erneut.");
  if (!extension || file.size === 0 || file.size > 25 * 1024 ** 2) {
    return status("Wählen Sie eine TXT- oder ZIP-Datei mit höchstens 25 MB.");
  }
  el("parse").disabled = true;
  el("choose").disabled = true;
  status("Der Chat wird in Ihrem Browser geöffnet …");
  const path = "/study-export." + extension;
  try {
    try {
      webR = await boot();
    } catch {
      status("Die lokale Verarbeitung ist gerade nicht verfügbar. Kontaktieren Sie das Studienteam.");
      return;
    }
    await rJsonFile("/study-settings.json", {
      platform: el("platform").value, language: el("language").value, consent: config.consent,
    });
    await webR.FS.writeFile(path, new Uint8Array(await file.arrayBuffer()));
    rows = JSON.parse(await webR.evalRString(`
      chat <- parse_export("${path}", jsonlite::fromJSON("/study-settings.json"))
      if (!nrow(chat)) stop("Empty chat.")
      preview <- chat[, c("DateTime", "Sender", "Sender_anon", "Emoji", "EmojiDescriptions",
                          "Smilies", "TokCount", "Message"), drop = FALSE]
      jsonlite::toJSON(preview, dataframe = "rows", na = "null", POSIXt = "ISO8601")
    `));
    await webR.FS.unlink(path);
    await webR.FS.unlink("/study-settings.json");
    await webR.evalRVoid('unlink(file.path(tempdir(), "whatsr_zip"), recursive = TRUE); rm(preview)');
    renderPeople();
    included = new Set(rows.map((_, index) => index));
    picker.value = "";
    chosenFile = undefined;
    el("filename").textContent = "Keine Datei ausgewählt";
    show("person");
    status("");
  } catch {
    webR?.close();
    webR = undefined;
    rows = [];
    status("Der Chat konnte nicht geöffnet werden. Prüfen Sie Datei, Gerät und Sprache. Wenn der Fehler bleibt, wenden Sie sich an das Studienteam.");
  } finally {
    el("parse").disabled = false;
    el("choose").disabled = false;
  }
});

function element(tag, text) {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  return node;
}

function renderPeople() {
  const people = new Map(rows.filter(row => /^Person_[0-9]+$/.test(row.Sender_anon))
    .map(row => [row.Sender_anon, row.Sender]));
  if (!people.size) throw new Error("No participants.");
  alias = "";
  el("next").disabled = true;
  el("people").replaceChildren();
  for (const [id, name] of people) {
    const label = element("label"), radio = element("input"), card = element("span");
    radio.type = "radio";
    radio.name = "browser-person-choice";
    radio.addEventListener("change", () => { alias = id; el("next").disabled = false; });
    const avatar = element("span");
    avatar.className = "study-person-avatar";
    avatar.setAttribute("aria-hidden", "true");
    const silhouette = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    silhouette.setAttribute("viewBox", "0 0 24 24");
    silhouette.setAttribute("width", "24");
    silhouette.setAttribute("height", "24");
    const shape = document.createElementNS(silhouette.namespaceURI, "path");
    shape.setAttribute("fill", "currentColor");
    shape.setAttribute("d", "M12 3a4 4 0 1 1 0 8 4 4 0 0 1 0-8Zm0 10c4 0 7 2 7 6v2H5v-2c0-4 3-6 7-6Z");
    silhouette.append(shape);
    avatar.append(silhouette);
    card.className = "study-person-card";
    card.append(avatar, element("strong", id));
    label.append(radio, card, element("span", name));
    el("people").append(label);
  }
}

function selectedFields() {
  return [...el("columns").querySelectorAll("input:checked")].map(input => input.value);
}

function updateCount() {
  el("count").textContent = included.size + " Zeilen · " + selectedFields().length + " Merkmale";
}

function renderTable() {
  const columns = selectedFields();
  const header = element("thead");
  const heading = element("tr");
  for (const name of ["Spenden", ...columns.map(key => fields[key]), "Nachricht (nur Vorschau)"]) {
    const cell = element("th", name);
    cell.scope = "col";
    heading.append(cell);
  }
  header.append(heading);
  const body = element("tbody");
  const start = page * pageSize;
  rows.slice(start, start + pageSize).forEach((row, offset) => {
    const index = start + offset;
    const tr = element("tr"), td = element("td"), checkbox = element("input");
    checkbox.type = "checkbox";
    checkbox.checked = included.has(index);
    checkbox.setAttribute("aria-label", "Zeile " + (index + 1) + " spenden");
    checkbox.addEventListener("change", () => {
      if (checkbox.checked) included.add(index);
      else included.delete(index);
      updateCount();
    });
    td.append(checkbox);
    tr.append(td, ...columns.map(key => element("td", (Array.isArray(row[key]) ?
      row[key].filter(value => value != null).join(", ") : row[key]) ?? "")));
    const message = row.Message ?? "";
    const preview = element("td");
    if (message.length > 100) {
      const details = element("details");
      details.append(element("summary", message.slice(0, 90) + "…"), element("p", message));
      preview.append(details);
    } else preview.textContent = message;
    tr.append(preview);
    body.append(tr);
  });
  el("table").replaceChildren(header, body);
  el("prev-page").disabled = page === 0;
  el("next-page").disabled = start + pageSize >= rows.length;
  el("page").textContent = "Seite " + (page + 1) + " von " + Math.ceil(rows.length / pageSize);
  updateCount();
}

el("next").addEventListener("click", () => {
  if (!alias) return;
  el("columns").replaceChildren();
  for (const [key, title] of Object.entries(fields)) {
    const label = element("label"), input = element("input");
    input.type = "checkbox";
    input.value = key;
    input.checked = true;
    input.addEventListener("change", renderTable);
    label.append(input, document.createTextNode(title));
    el("columns").append(label);
  }
  page = 0;
  renderTable();
  show("review");
});
el("prev-page").addEventListener("click", () => { page--; renderTable(); });
el("next-page").addEventListener("click", () => { page++; renderTable(); });
el("donate").addEventListener("click", () => {
  if (!included.size || !selectedFields().length) return status("Wählen Sie Zeilen und Merkmale aus.");
  el("confirm-text").textContent = included.size + " Zeilen und " + selectedFields().length + " Merkmale.";
  el("send").textContent = settings()?.save === "no" ? "Zur Auswertung" : "Daten spenden";
  el("confirm").showModal();
});
el("cancel").addEventListener("click", () => el("confirm").close());

function finish() {
  const count = included.size;
  const total = [...included].reduce((sum, i) => sum + (Number(rows[i].TokCount) || 0), 0);
  const donated = settings()?.save === "yes";
  destroyChat();
  el("totals").replaceChildren(element("dt", "Ausgewählte Zeilen"), element("dd", count),
    element("dt", "Wörter in diesen Zeilen"), element("dd", total));
  show("results");
  status(donated ? "Die verschlüsselte Auswahl wurde gespeichert." : "Ihre Auswahl wurde nicht gespeichert.");
}

el("send").addEventListener("click", async () => {
  const config = settings();
  el("confirm").close();
  if (!config) return status("Ihre Sitzung ist abgelaufen.");
  if (config.save === "no") return finish();
  if (!globalThis.crypto?.subtle || !config.publicKey || !window.Shiny) {
    return status("Eine verschlüsselte Übermittlung ist derzeit nicht verfügbar.");
  }

  el("donate").disabled = true;
  try {
    if (!pendingEnvelope) {
      const pick = selection(rows, included, selectedFields(), alias, config.studyId);
      await rJsonFile("/study-selection.json", pick);
      try {
        await webR.evalRVoid('serialize_donation(chat, jsonlite::fromJSON("/study-selection.json"), "/subset.rds")');
        const subset = await webR.FS.readFile("/subset.rds");
        if (subset.byteLength > 17 * 1024 ** 2) throw new Error("Selection too large.");
        const key = Uint8Array.from(atob(config.publicKey), character => character.charCodeAt(0));
        pendingEnvelope = await encryptDonation(subset, key);
        el("columns").inert = true;
        el("table").inert = true;
        el("prev-page").disabled = true;
        el("next-page").disabled = true;
      } finally {
        await webR.evalRVoid('unlink(c("/study-selection.json", "/subset.rds"))');
      }
    }
    if (!awaitingReceipt) {
      window.Shiny.addCustomMessageHandler("study-donation-receipt", receipt => {
        clearTimeout(receiptTimer);
        if (!pendingEnvelope) return;
        if (receipt.ok) finish();
        else {
          status("Die verschlüsselte Auswahl konnte nicht gespeichert werden. Versuchen Sie es erneut.");
          el("donate").disabled = false;
        }
      });
      awaitingReceipt = true;
    }
    status("Die verschlüsselte Auswahl wird übermittelt …");
    receiptTimer = setTimeout(() => {
      status("Die Bestätigung fehlt. Sie können dieselbe verschlüsselte Auswahl erneut senden.");
      el("donate").disabled = false;
    }, 20000);
    window.Shiny.setInputValue("encrypted_donation", pendingEnvelope, { priority: "event" });
  } catch {
    clearTimeout(receiptTimer);
    status("Die verschlüsselte Übermittlung konnte nicht abgeschlossen werden.");
    el("donate").disabled = false;
  }
});

function destroyChat() {
  webR?.close();
  webR = undefined;
  rows = [];
  alias = "";
  included.clear();
  pendingEnvelope = undefined;
  for (const id of ["table", "people", "columns"]) el(id).replaceChildren();
  el("table").inert = false;
  el("columns").inert = false;
  el("donate").disabled = false;
}
el("clear").addEventListener("click", () => { destroyChat(); el("totals").replaceChildren(); show("open"); status(""); });
window.addEventListener("pagehide", event => { if (!event.persisted) destroyChat(); });
