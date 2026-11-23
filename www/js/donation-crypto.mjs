// Encrypt only the bytes the participant has approved for donation.
export async function encryptDonation(subset, publicKeySpki) {
  const { subtle } = globalThis.crypto;
  const studyKey = await subtle.importKey(
    "spki", publicKeySpki, { name: "RSA-OAEP", hash: "SHA-256" }, false, ["wrapKey"]
  );
  const fileKey = await subtle.generateKey({ name: "AES-GCM", length: 256 }, true, ["encrypt"]);
  const nonce = globalThis.crypto.getRandomValues(new Uint8Array(12));
  const label = new TextEncoder().encode("ChatDashboard donation v1");
  const wrappedKey = await subtle.wrapKey("raw", fileKey, studyKey, { name: "RSA-OAEP", label });
  const ciphertext = await subtle.encrypt(
    { name: "AES-GCM", iv: nonce, additionalData: label }, fileKey, subset
  );

  return {
    version: 1,
    nonce: base64(nonce),
    wrappedKey: base64(new Uint8Array(wrappedKey)),
    ciphertext: base64(new Uint8Array(ciphertext)),
  };
}

function base64(bytes) {
  const chunks = [];
  // Keep each spread within browser argument limits.
  for (let start = 0; start < bytes.length; start += 0x4000) {
    chunks.push(String.fromCharCode(...bytes.subarray(start, start + 0x4000)));
  }
  return btoa(chunks.join(""));
}
