// These are the only fields eligible for the donation. Everything else stays local.
export const fields = {
  DateTime: "Zeit",
  Sender_anon: "Absenderkennung",
  Emoji: "Emoji",
  EmojiDescriptions: "Emoji-Beschreibung",
  Smilies: "Smileys",
  TokCount: "Wortanzahl",
};

export function selection(rows, included, requested, alias, studyId) {
  const columns = [...new Set(requested)].filter(name => Object.hasOwn(fields, name));
  const indexes = [...new Set(included)].filter(index => Number.isInteger(index) &&
    index >= 0 && index < rows.length);
  if (!columns.length || !indexes.length || !/^Person_[0-9]+$/.test(alias)) {
    throw new Error("Wählen Sie eine Person, mindestens eine Zeile und ein Merkmal aus.");
  }
  return { rows: indexes.map(index => index + 1), columns, alias, studyId };
}
