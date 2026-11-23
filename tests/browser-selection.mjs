import assert from "node:assert/strict";
import { selection } from "../www/js/donation-selection.mjs";

const rows = [{ Worte: ["private"], Links_anonym: "https://example.org" }, {}, {}];
const config = {
  fields: ["Worte", "Links_anonym", "Wortanzahl"],
  excluded: ["Worte"],
};
const requested = ["Links_anonym", "Worte", "Wortanzahl", "unknown"];
assert.deepEqual(selection(rows, [2, 0, 2], requested, "Person_1", config), {
  rows: [1, 3], columns: ["Links_anonym", "Wortanzahl"], alias: "Person_1",
});
assert.deepEqual(selection(rows, [0], ["Worte"], "Person_1", { ...config, excluded: [] }).columns, ["Worte"]);
assert.throws(() => selection(rows, [0], ["Worte"], "Person_1", config));
assert.throws(() => selection(rows, [], requested, "Person_1", config));
assert.throws(() => selection(rows, [0], requested, "local name", config));
console.log("Researcher-configured exclusions, eligible fields, and row order verified.");
