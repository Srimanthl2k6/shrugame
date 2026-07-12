const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const source = JSON.parse(fs.readFileSync(path.join(root, "version.json"), "utf8"));
const version = String(source.version || "").trim();

if (!/^\d+\.\d+\.\d+$/.test(version)) {
  throw new Error(`Invalid release version: ${version}`);
}

function writeJson(relativePath, mutate) {
  const filePath = path.join(root, relativePath);
  const value = JSON.parse(fs.readFileSync(filePath, "utf8"));
  mutate(value);
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function replace(relativePath, pattern, replacement) {
  const filePath = path.join(root, relativePath);
  const original = fs.readFileSync(filePath, "utf8");
  const updated = original.replace(pattern, replacement);
  if (updated === original && !original.includes(replacement)) {
    throw new Error(`Version marker not found in ${relativePath}`);
  }
  fs.writeFileSync(filePath, updated);
}

writeJson("electron/package.json", (data) => { data.version = version; });
writeJson("site/package.json", (data) => { data.version = version; });
writeJson("electron/package-lock.json", (data) => {
  data.version = version;
  if (data.packages?.[""]) data.packages[""].version = version;
});
writeJson("site/package-lock.json", (data) => {
  data.version = version;
  if (data.packages?.[""]) data.packages[""].version = version;
});
replace("project.godot", /config\/version="[^"]+"/, `config/version="${version}"`);
replace("export_presets.cfg", /application\/file_version="[^"]+"/, `application/file_version="${version}.0"`);
replace("export_presets.cfg", /application\/product_version="[^"]+"/, `application/product_version="${version}"`);
replace("electron/electron-builder.yml", /  version: [^\r\n]+/, `  version: ${version}`);
replace("site/index.html", /Download \d+\.\d+\.\d+/, `Download ${version}`);
replace("site/index.html", /DESKTOP \d+\.\d+\.\d+/, `DESKTOP ${version}`);
replace("site/index.html", /<span id="version">[^<]+<\/span>/, `<span id="version">${version}</span>`);
fs.writeFileSync(path.join(root, "site", "public", "version.json"), `${JSON.stringify({ version }, null, 2)}\n`);
console.log(`Synchronized Shrugame ${version}`);
