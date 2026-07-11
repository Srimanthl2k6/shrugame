const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const projectRoot = path.resolve(__dirname, "..", "..");
const outputPath = path.join(projectRoot, "electron", "godot-export", "web", "index.html");
const localWindowsGodot = path.join(projectRoot, "tools", "godot", "Godot_v4.7-stable_win64_console.exe");
const candidates = [process.env.GODOT_BIN, process.platform === "win32" && localWindowsGodot, "godot"].filter(Boolean);

function patchWebShell() {
  const marker = "shrugame-fixed-canvas";
  let html = fs.readFileSync(outputPath, "utf8");
  html = html.replace('<canvas id="canvas">', '<canvas id="canvas" width="640" height="360">');
  if (!html.includes(marker)) {
    html = html.replace(
      "</head>",
      `<style id="${marker}">\nhtml, body { width: 100%; height: 100%; overflow: hidden; background: #05080b; }\n#canvas { width: 100vw !important; height: 100vh !important; object-fit: contain; image-rendering: pixelated; background: #05080b; }\n</style>\n</head>`
    );
    fs.writeFileSync(outputPath, html, "utf8");
  }
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });

let lastError = null;
for (const executable of candidates) {
  const result = spawnSync(executable, ["--headless", "--quiet", "--path", projectRoot, "--export-release", "Web", outputPath], {
    cwd: projectRoot,
    encoding: "utf8",
    shell: false,
    stdio: "inherit"
  });
  if (!result.error && result.status === 0 && fs.existsSync(outputPath)) {
    patchWebShell();
    process.exit(0);
  }
  lastError = result.error || new Error(`Godot exited with status ${result.status}`);
}

console.error(`Godot Web export failed: ${lastError ? lastError.message : "no Godot executable found"}`);
process.exit(1);
