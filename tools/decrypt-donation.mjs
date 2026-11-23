import { readFile, writeFile } from "node:fs/promises";
import { constants, createDecipheriv, privateDecrypt } from "node:crypto";

const [keyPath, envelopePath, outputPath] = process.argv.slice(2);

if (!keyPath || !envelopePath || !outputPath) {
  console.error("Usage: node tools/decrypt-donation.mjs PRIVATE_KEY.pem ENVELOPE.json OUTPUT");
  process.exitCode = 2;
} else {
  try {
    const privateKey = await readFile(keyPath);
    const envelope = JSON.parse(await readFile(envelopePath, "utf8"));
    const plaintext = decryptDonation(envelope, privateKey);
    await writeFile(outputPath, plaintext, { flag: "wx", mode: 0o600 });
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

function decryptDonation(envelope, privateKey) {
  if (envelope?.version !== 1) throw new Error("Unsupported donation envelope version.");
  const nonce = Buffer.from(envelope.nonce, "base64");
  const wrappedKey = Buffer.from(envelope.wrappedKey, "base64");
  const ciphertext = Buffer.from(envelope.ciphertext, "base64");
  if (nonce.length !== 12 || ciphertext.length < 16) throw new Error("Invalid donation envelope.");

  const label = Buffer.from("ChatDashboard donation v1");
  const fileKey = privateDecrypt({
    key: privateKey,
    padding: constants.RSA_PKCS1_OAEP_PADDING,
    oaepHash: "sha256",
    oaepLabel: label,
  }, wrappedKey);

  const decipher = createDecipheriv("aes-256-gcm", fileKey, nonce);
  decipher.setAAD(label);
  decipher.setAuthTag(ciphertext.subarray(-16));
  return Buffer.concat([decipher.update(ciphertext.subarray(0, -16)), decipher.final()]);
}
