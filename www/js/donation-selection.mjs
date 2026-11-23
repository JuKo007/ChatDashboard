export function donatableFields(requested, fields, excluded) {
  return [...new Set(requested)].filter(name => fields.includes(name) && !excluded.includes(name));
}

export function selection(rows, included, requested, alias, settings) {
  const columns = donatableFields(requested, settings.fields, settings.excluded);
  const indexes = [...new Set(included)].filter(index => Number.isInteger(index) &&
    index >= 0 && index < rows.length).sort((a, b) => a - b);
  if (!columns.length || !indexes.length || !/^Person_[0-9]+$/.test(alias)) {
    throw new Error("Wählen Sie eine Person, mindestens eine Zeile und ein spendbares Merkmal aus.");
  }
  return { rows: indexes.map(index => index + 1), columns, alias };
}
