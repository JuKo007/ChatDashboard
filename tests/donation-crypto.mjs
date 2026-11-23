
import assert from "node:assert/strict";
import { generateKeyPairSync } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { readFile, writeFile, mkdtemp, rm } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { encryptDonation } from "../www/js/donation-crypto.mjs";
const cli = fileURLToPath(new URL("../tools/decrypt-donation.mjs", import.meta.url));
const dir = await mkdtemp(join(tmpdir(), "chatdashboard-crypto-"));
try {
  const a = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const key = join(dir, "private.pem"), input = join(dir, "envelope.json"), out = join(dir, "subset.bin");
  await writeFile(key, a.privateKey.export({ type: "pkcs8", format: "pem" }));
  const bytes = Buffer.from("approved data only ".repeat(5000));
  const envelope = await encryptDonation(bytes, a.publicKey.export({ type: "spki", format: "der" }));
  await writeFile(input, JSON.stringify(envelope));
  execFileSync(process.execPath, [cli, key, input, out]);
  assert.deepEqual(await readFile(out), bytes);
  const ciphertext = Buffer.from(envelope.ciphertext, "base64");
  ciphertext[0] ^= 1;
  envelope.ciphertext = ciphertext.toString("base64");
  await writeFile(input, JSON.stringify(envelope));
  const badOutput = join(dir, "bad.bin");
  const tampered = spawnSync(process.execPath, [cli, key, input, badOutput]);
  assert.equal(tampered.status, 1);
  await assert.rejects(readFile(badOutput), { code: "ENOENT" });
  console.log("Round-trip and modified-ciphertext rejection passed");
} finally {
  await rm(dir, { recursive: true, force: true });
}