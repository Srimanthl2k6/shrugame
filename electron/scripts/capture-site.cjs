const { app, BrowserWindow } = require("electron");
const fs = require("node:fs");
const path = require("node:path");

const url = process.env.SHRUGAME_SITE_URL || "http://127.0.0.1:5173/shrugame/";
const output = path.resolve(__dirname, "..", "..", "builds", "qa", "site");
const viewports = [
  { name: "desktop", width: 1440, height: 1000 },
  { name: "mobile", width: 390, height: 844 },
];

app.commandLine.appendSwitch("force-device-scale-factor", "1");

app.whenReady().then(async () => {
  fs.mkdirSync(output, { recursive: true });
  const report = [];

  for (const viewport of viewports) {
    const window = new BrowserWindow({
      width: viewport.width,
      height: viewport.height,
      show: false,
      webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true },
    });
    const errors = [];
    window.webContents.on("console-message", (_event, details) => {
      if (details.level === "error") errors.push(details.message);
    });
    await window.loadURL(url);
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const metrics = await window.webContents.executeJavaScript(`(() => {
      const all = [...document.querySelectorAll('*')];
      const overflow = all.filter((node) => node.scrollWidth > node.clientWidth + 1)
        .map((node) => ({ tag: node.tagName, className: node.className, clientWidth: node.clientWidth, scrollWidth: node.scrollWidth }))
        .slice(0, 20);
      const missingImages = [...document.images].filter((image) => !image.complete || image.naturalWidth === 0).map((image) => image.src);
      return {
        documentHeight: document.documentElement.scrollHeight,
        documentWidth: document.documentElement.scrollWidth,
        h1: document.querySelector('h1')?.textContent || '',
        missingImages,
        overflow,
        viewportHeight: innerHeight,
        viewportWidth: innerWidth,
      };
    })()`);
    const screenshot = await window.capturePage();
    fs.writeFileSync(path.join(output, `${viewport.name}.png`), screenshot.toPNG());
    report.push({ ...viewport, ...metrics, consoleErrors: errors });
    window.destroy();
  }

  fs.writeFileSync(path.join(output, "site-visual-report.json"), `${JSON.stringify(report, null, 2)}\n`);
  const passed = report.every((entry) => entry.h1 === "Shrugame" && entry.missingImages.length === 0 && entry.consoleErrors.length === 0 && entry.documentWidth <= entry.viewportWidth + 1);
  process.exitCode = passed ? 0 : 1;
  app.quit();
});
