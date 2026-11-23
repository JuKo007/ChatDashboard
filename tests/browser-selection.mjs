import assert from "node:assert/strict";
import { selection } from "../www/js/donation-selection.mjs";

const rows = [
  { Message: "local-only", Sender: "local name", TokCount: 3 },
  { Message: "excluded row", Sender: "another local name", TokCount: 9 },
];
const pick = selection(rows, new Set([0]), ["TokCount", "Message", "Sender", "constructor"], "Person_1", "study");
assert.deepEqual(pick, { rows: [1], columns: ["TokCount"], alias: "Person_1", studyId: "study" });
assert.throws(() => selection(rows, [], ["TokCount"], "Person_1", "study"));
assert.throws(() => selection(rows, [0], ["Message"], "Person_1", "study"));
assert.throws(() => selection(rows, [0], ["TokCount"], "local name", "study"));
console.log("Only selected rows and allowed fields can be serialized.");
