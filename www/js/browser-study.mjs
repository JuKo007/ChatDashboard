import { encryptDonation } from "./donation-crypto.mjs";
import { donatableFields, selection } from "./donation-selection.mjs";

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
    for (const script of ["browser-parser.R", "browser-charts.R"]) {
      const response = await fetch(new URL("./" + script, import.meta.url));
      if (!response.ok) throw new Error("Browser script unavailable.");
      await runtime.evalRVoid(await response.text());
    }
    return runtime;
  } catch (error) {
    runtime.close();
    throw error;
  }
}

function settings() {
  const data = document.getElementById("study-browser-config")?.dataset;
  if (!data) return undefined;
  return { ...data,
    fields: JSON.parse(data.fields),
    excluded: JSON.parse(data.excluded),
    clientOS: JSON.parse(data.clientOs),
    clientDevice: JSON.parse(data.clientDevice),
  };
}
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
      platform: el("platform").value, language: el("language").value, consent: config.consent, fields: config.fields,
    });
    await webR.FS.writeFile(path, new Uint8Array(await file.arrayBuffer()));
    rows = JSON.parse(await webR.evalRString(`
      config <- jsonlite::fromJSON("/study-settings.json")
      chat <- parse_export("${path}", config)
      if (!nrow(chat)) stop("Empty chat.")
      preview_json(chat, config$fields)
    `));
    await webR.FS.unlink(path);
    await webR.FS.unlink("/study-settings.json");
    await webR.evalRVoid('unlink(file.path(tempdir(), "whatsr_zip"), recursive = TRUE); rm(config)');
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
  const [, displayName, displayAlias] = settings().fields;
  const people = new Map(rows.filter(row => /^Person_[0-9]+$/.test(row[displayAlias]))
    .map(row => [row[displayAlias], row[displayName]]));
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
  const config = settings();
  if (!config) return;
  const count = donatableFields(selectedFields(), config.fields, config.excluded).length;
  el("count").textContent = included.size + " Zeilen · " + count + " spendbare Merkmale";
}

function renderTable() {
  const columns = selectedFields();
  const config = settings();
  if (!config) return;
  const header = element("thead");
  const heading = element("tr");
  for (const name of ["Spenden", ...columns]) {
    const cell = element("th", name);
    cell.scope = "col";
    if (config.excluded.includes(name)) cell.classList.add("study-preview-only");
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
    tr.append(td);
    for (const key of columns) {
      const cell = element("td");
      if (config.excluded.includes(key)) cell.classList.add("study-preview-only");
      const value = Array.isArray(row[key]) ? row[key].filter(item => item != null).join(", ") : row[key];
      const display = value == null ? "" : String(value);
      if (Array.from(display).length > 100) {
        const details = element("details");
        details.append(element("summary", Array.from(display).slice(0, 90).join("") + "…"), element("p", display));
        cell.append(details);
      } else cell.textContent = display;
      tr.append(cell);
    }
    body.append(tr);
  });
  el("table").replaceChildren(header, body);
  el("prev-page").disabled = page === 0;
  el("next-page").disabled = start + pageSize >= rows.length;
  el("page").textContent = "Seite " + (page + 1) + " von " + Math.ceil(rows.length / pageSize);
  updateCount();
}

el("next").addEventListener("click", () => {
  const config = settings();
  if (!alias || !config) return;
  el("columns").replaceChildren();
  for (const key of config.fields) {
    const label = element("label"), input = element("input");
    input.type = "checkbox";
    input.value = key;
    const excluded = config.excluded.includes(key);
    input.checked = !excluded;
    if (excluded) label.classList.add("study-preview-only");
    input.addEventListener("change", renderTable);
    label.append(input, document.createTextNode(key));
    el("columns").append(label);
  }
  page = 0;
  renderTable();
  show("review");
});
el("prev-page").addEventListener("click", () => { page--; renderTable(); });
el("next-page").addEventListener("click", () => { page++; renderTable(); });
el("donate").addEventListener("click", () => {
  const config = settings();
  if (!config) return status("Ihre Sitzung ist abgelaufen.");
  const count = donatableFields(selectedFields(), config.fields, config.excluded).length;
  if (!included.size || !count) return status("Wählen Sie Zeilen und spendbare Merkmale aus.");
  el("confirm-text").textContent = included.size + " Zeilen und " + count +
    " spendbare Merkmale. Grau markierte Merkmale bleiben in der Vorschau.";
  el("send").textContent = settings()?.save === "no" ? "Zur Auswertung" : "Daten spenden";
  el("confirm").showModal();
});
el("cancel").addEventListener("click", () => el("confirm").close());

function finish() {
  clearTimeout(receiptTimer);
  if (el("confirm").open) el("confirm").close();
  const donated = settings()?.save === "yes";
  pendingEnvelope = undefined;
  initCharts();
  show("results");
  status(donated ? "Die verschlüsselte Auswahl wurde gespeichert." : "Ihre Auswahl wurde nicht gespeichert.");
  void drawCharts();
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
      const pick = selection(rows, included, selectedFields(), alias, config);
      try {
        await rJsonFile("/study-selection.json", pick);
        await rJsonFile("/study-schema.json", {
          fields: config.fields, excluded: config.excluded,
          clientOS: config.clientOS, clientDevice: config.clientDevice,
        });
        await webR.evalRVoid('serialize_donation(chat, jsonlite::fromJSON("/study-selection.json"), jsonlite::fromJSON("/study-schema.json"), "/subset.rds")');
        const subset = await webR.FS.readFile("/subset.rds");
        if (subset.byteLength > 17 * 1024 ** 2) throw new Error("Selection too large.");
        const key = Uint8Array.from(atob(config.publicKey), character => character.charCodeAt(0));
        pendingEnvelope = await encryptDonation(subset, key);
        el("columns").inert = true;
        el("table").inert = true;
        el("prev-page").disabled = true;
        el("next-page").disabled = true;
      } finally {
        await webR.evalRVoid('unlink(c("/study-selection.json", "/study-schema.json", "/subset.rds"))');
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
el("clear").addEventListener("click", () => { destroyChat(); el("charts").replaceChildren(); el("chart-senders").replaceChildren(); show("open"); status(""); });
window.addEventListener("pagehide", event => { if (!event.persisted) destroyChat(); });

const charts = {
  messages: ["message1", "tokensbwah1", "tokensbwah2"],
  links: ["links4", "links2", "links1"],
  smilies: ["smilies4", "smilies2", "smilies1"],
  emoji: ["emoji4", "emoji2", "emoji1"],
  replies: ["replytime1", "replytime2"],
};
const minimums = { links: 5, smilies: 5, emoji: 50 };
const chartFilters = new Map();
let drawing = false;
let redraw = false;

function initCharts() {
  const [timestamp, sender] = settings().fields;
  const dates = rows.map(row => String(row[timestamp] ?? "").slice(0, 10))
    .filter(date => /^\d{4}-\d{2}-\d{2}$/.test(date)).sort();
  const senders = [...new Set(rows.map(row => row[sender]))]
    .filter(name => name && name !== "WhatsApp System Message");
  chartFilters.clear();
  el("chart-senders").replaceChildren();
  for (const name of senders) {
    const checkbox = element("input");
    checkbox.type = "checkbox";
    checkbox.checked = true;
    // Assign the real name as text. It never becomes a Shiny input ID or value.
    const label = element("label");
    label.append(checkbox, document.createTextNode(name));
    el("chart-senders").append(label);
  }
  for (const group of Object.keys(charts)) {
    chartFilters.set(group, {
      start: dates[0] ?? "", end: dates.at(-1) ?? "",
      senders: senders.map(() => true), minimum: minimums[group] ?? 1,
    });
  }
  el("chart-group").value = "messages";
  activeChartGroup = "messages";
  showChartFilters();
}

let activeChartGroup = "messages";
function readChartFilters() {
  return {
    start: el("chart-start").value,
    end: el("chart-end").value,
    senders: [...el("chart-senders").querySelectorAll("input")].map(input => input.checked),
    minimum: Number(el("chart-minimum").value) || 1,
  };
}

function showChartFilters() {
  const filter = chartFilters.get(activeChartGroup);
  el("chart-start").value = filter.start;
  el("chart-end").value = filter.end;
  el("chart-minimum").value = filter.minimum;
  el("minimum-label").hidden = !Object.hasOwn(minimums, activeChartGroup);
  el("chart-senders").querySelectorAll("input").forEach((input, i) => {
    input.checked = filter.senders[i];
  });
}

el("chart-group").addEventListener("change", () => {
  chartFilters.set(activeChartGroup, readChartFilters());
  activeChartGroup = el("chart-group").value;
  showChartFilters();
  void drawCharts();
});
for (const id of ["chart-start", "chart-end", "chart-minimum", "chart-senders"]) {
  el(id).addEventListener("change", () => void drawCharts());
}

async function drawCharts() {
  if (!webR || el("results").hidden) return;
  if (drawing) { redraw = true; return; }
  drawing = true;
  const runtime = webR;
  const group = activeChartGroup;
  const filter = readChartFilters();
  filter.senders = [...el("chart-senders").querySelectorAll("label")]
    .filter((_, i) => filter.senders[i]).map(label => label.textContent);
  const output = el("charts");
  output.replaceChildren();
  const setStatus = text => { el("chart-status").textContent = text; };
  let shelter;
  try {
    if (!filter.senders.length || !filter.start || !filter.end || filter.start > filter.end) {
      setStatus("Wählen Sie mindestens einen Absender und einen gültigen Zeitraum aus.");
      return;
    }
    setStatus("Diagramme werden in Ihrem Browser berechnet …");
    shelter = await new runtime.Shelter();
    const width = Math.round(Math.min(1050, Math.max(420, output.clientWidth)));
    for (const chart of charts[group]) {
      if (runtime !== webR || redraw) break;
      await rJsonFile("/chart-filters.json", { ...filter, chart, width });
      try {
        const capture = await shelter.captureR(`
          local({
            filters <- jsonlite::fromJSON("/chart-filters.json")
            webr::canvas(width = filters$width, height = 480, capture = TRUE)
            tryCatch(print(legacy_chart(filters$chart, chat, filters)),
                     finally = grDevices::dev.off())
          })
        `);
        for (const image of capture.images) {
          if (runtime === webR && !redraw) {
            const canvas = element("canvas");
            canvas.width = image.width;
            canvas.height = image.height;
            canvas.style.maxWidth = "100%";
            canvas.style.height = "auto";
            canvas.setAttribute("role", "img");
            canvas.setAttribute("aria-label", el("chart-group").selectedOptions[0].textContent);
            canvas.getContext("2d").drawImage(image, 0, 0);
            output.append(canvas);
          }
          image.close();
        }
      } catch {
        if (runtime === webR && !redraw) output.append(element("p", "Für dieses Diagramm konnten keine Daten dargestellt werden."));
      } finally {
        await shelter.purge();
      }
    }
    if (runtime === webR && !redraw) setStatus("");
  } catch {
    if (runtime === webR) setStatus("Die Diagramme konnten nicht berechnet werden.");
  } finally {
    if (runtime === webR) {
      await runtime.evalRVoid('unlink("/chart-filters.json")').catch(() => {});
    }
    drawing = false;
    if (redraw) { redraw = false; void drawCharts(); }
  }
}
