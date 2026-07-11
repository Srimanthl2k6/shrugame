const { app, BrowserWindow, ipcMain, session, shell } = require("electron");
const crypto = require("node:crypto");
const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");

const APP_ORIGIN = "http://127.0.0.1:47111";
const APP_PORT = 47111;
const ROOT = __dirname;
const RENDERER_ROOT = path.join(ROOT, "renderer");
const GAME_ROOT = path.join(ROOT, "godot-export", "web");
const IS_SMOKE = process.env.SHRUGAME_SMOKE === "1";
const SMOKE_ROUTE = process.env.SHRUGAME_SMOKE_ROUTE || "1";
const WINDOW_WIDTH = Math.max(960, Number.parseInt(process.env.SHRUGAME_WINDOW_WIDTH || "1280", 10));
const WINDOW_HEIGHT = Math.max(540, Number.parseInt(process.env.SHRUGAME_WINDOW_HEIGHT || "720", 10));
const MIME_TYPES = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".wasm": "application/wasm",
  ".webp": "image/webp"
};

let mainWindow = null;
let localServer = null;
const consoleErrors = [];

app.commandLine.appendSwitch("autoplay-policy", "no-user-gesture-required");
app.commandLine.appendSwitch("disable-features", "HardwareMediaKeyHandling");

if (!app.requestSingleInstanceLock()) {
  app.quit();
}

function safeFile(root, requestPath) {
  const resolved = path.resolve(root, `.${requestPath}`);
  return resolved === root || resolved.startsWith(`${root}${path.sep}`) ? resolved : null;
}

function sendFile(response, filePath) {
  fs.stat(filePath, (statError, stat) => {
    if (statError || !stat.isFile()) {
      response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      response.end("Not found");
      return;
    }
    response.writeHead(200, {
      "Cache-Control": IS_SMOKE ? "no-store" : "public, max-age=3600",
      "Content-Length": stat.size,
      "Content-Type": MIME_TYPES[path.extname(filePath).toLowerCase()] || "application/octet-stream",
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Resource-Policy": "same-origin"
    });
    fs.createReadStream(filePath).pipe(response);
  });
}

function createLocalServer() {
  return new Promise((resolve, reject) => {
    localServer = http.createServer((request, response) => {
      const url = new URL(request.url || "/", APP_ORIGIN);
      let root = RENDERER_ROOT;
      let requestPath = url.pathname;
      if (requestPath === "/") {
        requestPath = "/index.html";
      } else if (requestPath.startsWith("/renderer/")) {
        requestPath = requestPath.slice("/renderer".length);
      } else if (requestPath.startsWith("/game/")) {
        root = GAME_ROOT;
        requestPath = requestPath.slice("/game".length);
      }
      const filePath = safeFile(root, decodeURIComponent(requestPath));
      if (!filePath) {
        response.writeHead(403, { "Content-Type": "text/plain; charset=utf-8" });
        response.end("Forbidden");
        return;
      }
      sendFile(response, filePath);
    });
    localServer.once("error", reject);
    localServer.listen(APP_PORT, "127.0.0.1", resolve);
  });
}

function installSecurityGuards() {
  session.defaultSession.setPermissionRequestHandler((_webContents, _permission, callback) => callback(false));
  session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
    const allowed = details.url.startsWith(APP_ORIGIN) || details.url.startsWith("devtools:");
    callback({ cancel: !allowed });
  });
  session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
    callback({
      responseHeaders: {
        ...details.responseHeaders,
        "Cross-Origin-Embedder-Policy": ["require-corp"],
        "Cross-Origin-Opener-Policy": ["same-origin"],
        "Cross-Origin-Resource-Policy": ["same-origin"]
      }
    });
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: WINDOW_WIDTH,
    height: WINDOW_HEIGHT,
    minWidth: 960,
    minHeight: 540,
    backgroundColor: "#05080b",
    autoHideMenuBar: true,
    fullscreenable: true,
    show: false,
    title: "Shrugame",
    webPreferences: {
      contextIsolation: true,
      devTools: !app.isPackaged,
      nodeIntegration: false,
      preload: path.join(ROOT, "preload.cjs"),
      sandbox: true
    }
  });

  mainWindow.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  mainWindow.webContents.on("will-navigate", (event, targetUrl) => {
    if (!targetUrl.startsWith(APP_ORIGIN)) {
      event.preventDefault();
    }
  });
  mainWindow.webContents.on("before-input-event", (event, input) => {
    if (input.type !== "keyDown") return;
    if (input.key === "F11" || (input.alt && input.key === "Enter")) {
      event.preventDefault();
      mainWindow.setFullScreen(!mainWindow.isFullScreen());
    } else if (input.key === "Escape" && mainWindow.isFullScreen()) {
      event.preventDefault();
      mainWindow.setFullScreen(false);
    }
  });
  mainWindow.webContents.on("console-message", (_event, details) => {
    if (details.level === "error") {
      consoleErrors.push(details.message);
    }
  });
  mainWindow.once("ready-to-show", () => mainWindow.show());
  mainWindow.loadURL(`${APP_ORIGIN}/renderer/index.html${IS_SMOKE ? `?smoke=${encodeURIComponent(SMOKE_ROUTE)}` : ""}`);
  if (IS_SMOKE) {
    mainWindow.webContents.once("did-finish-load", () => runSmokeProbe(mainWindow));
  }
}

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function collectRuntimeProbe(window) {
  return window.webContents.executeJavaScript(`(async () => {
    const frame = document.querySelector('#game-frame');
    const frameWindow = frame && frame.contentWindow;
    const frameDocument = frame && frame.contentDocument;
    const canvas = frameDocument && frameDocument.querySelector('canvas');
    if (canvas) {
      canvas.focus();
      canvas.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: canvas.width / 2, clientY: canvas.height / 2 }));
      canvas.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, clientX: canvas.width / 2, clientY: canvas.height / 2 }));
    }
    let audioState = 'unsupported';
    if (frameWindow && (frameWindow.AudioContext || frameWindow.webkitAudioContext)) {
      const AudioCtor = frameWindow.AudioContext || frameWindow.webkitAudioContext;
      const context = new AudioCtor();
      await context.resume();
      audioState = context.state;
      await context.close();
    }
    const storageResult = await new Promise((resolve) => {
      const request = indexedDB.open('shrugame-electron-smoke', 1);
      request.onupgradeneeded = () => request.result.createObjectStore('probe');
      request.onerror = () => resolve(false);
      request.onsuccess = () => {
        const database = request.result;
        const transaction = database.transaction('probe', 'readwrite');
        transaction.objectStore('probe').put('persistent', 'status');
        transaction.oncomplete = () => {
          const readTransaction = database.transaction('probe', 'readonly');
          const readRequest = readTransaction.objectStore('probe').get('status');
          readRequest.onsuccess = () => resolve(readRequest.result === 'persistent');
          readRequest.onerror = () => resolve(false);
        };
      };
    });
    return {
      audioState,
      canvasFound: Boolean(canvas),
      canvasHeight: canvas ? canvas.height : 0,
      canvasWidth: canvas ? canvas.width : 0,
      frameReadyState: frameDocument ? frameDocument.readyState : 'missing',
      indexedDbWritable: storageResult,
      keyboardTarget: frameDocument ? frameDocument.activeElement && frameDocument.activeElement.tagName : 'missing',
      godotDiagnostics: frameWindow ? frameWindow.__shrugameDiagnostics || null : null
    };
  })()`);
}

async function runSmokeProbe(window) {
  const outputDir = path.resolve(process.env.SHRUGAME_SMOKE_OUTPUT || path.join(ROOT, "..", "builds", "qa", "electron"));
  fs.mkdirSync(outputDir, { recursive: true });
  let probe = null;
  for (let attempt = 0; attempt < 30; attempt += 1) {
    await wait(1000);
    probe = await collectRuntimeProbe(window);
    if (probe.canvasFound && probe.canvasWidth > 0 && probe.canvasHeight > 0) break;
  }

  const before = await window.capturePage();
  const beforeBuffer = before.toPNG();
  fs.writeFileSync(path.join(outputDir, "electron-boot.png"), beforeBuffer);

	const pressKey = async (keyCode, holdMilliseconds = 80) => {
		window.webContents.sendInputEvent({ type: "keyDown", keyCode });
		await wait(holdMilliseconds);
		window.webContents.sendInputEvent({ type: "keyUp", keyCode });
	};
	const clickCanvas = async (x, y) => {
		window.webContents.sendInputEvent({ type: "mouseMove", x, y });
		window.webContents.sendInputEvent({ type: "mouseDown", x, y, button: "left", clickCount: 1 });
		await wait(80);
		window.webContents.sendInputEvent({ type: "mouseUp", x, y, button: "left", clickCount: 1 });
	};
	if (SMOKE_ROUTE === "1") {
		await clickCanvas(992, 256);
		await wait(250);
		await clickCanvas(384, 312);
		await wait(1200);
		for (let index = 0; index < 8; index += 1) {
			await pressKey("E");
			await wait(320);
		}
	} else {
		await wait(SMOKE_ROUTE.startsWith("level_") ? 5000 : 2300);
		if (SMOKE_ROUTE === "battle") {
			await pressKey("1");
			await wait(1200);
		}
	}
	window.webContents.sendInputEvent({ type: "keyDown", keyCode: "D" });
	await wait(600);
	window.webContents.sendInputEvent({ type: "keyUp", keyCode: "D" });
	await wait(800);

  const after = await window.capturePage();
  const afterBuffer = after.toPNG();
  fs.writeFileSync(path.join(outputDir, "electron-after-input.png"), afterBuffer);
  fs.writeFileSync(path.join(outputDir, `electron-${SMOKE_ROUTE}-after-input.png`), afterBuffer);
  const beforeHash = crypto.createHash("sha256").update(beforeBuffer).digest("hex");
  const afterHash = crypto.createHash("sha256").update(afterBuffer).digest("hex");
  const finalProbe = await collectRuntimeProbe(window);
  const report = {
    ...probe,
    ...finalProbe,
    appOrigin: APP_ORIGIN,
    consoleErrors,
    frameChangedAfterInput: beforeHash !== afterHash,
    generatedAt: new Date().toISOString(),
    smokeRoute: SMOKE_ROUTE
  };
  fs.writeFileSync(path.join(outputDir, "electron-runtime-report.json"), `${JSON.stringify(report, null, 2)}\n`);
  const passed = report.canvasFound && report.indexedDbWritable && report.audioState === "running" && report.consoleErrors.length === 0;
  process.exitCode = passed ? 0 : 1;
  await wait(250);
  app.quit();
}

ipcMain.handle("window:toggle-fullscreen", () => {
  if (!mainWindow) return false;
  mainWindow.setFullScreen(!mainWindow.isFullScreen());
  return mainWindow.isFullScreen();
});
ipcMain.handle("window:is-fullscreen", () => Boolean(mainWindow && mainWindow.isFullScreen()));
ipcMain.handle("app:version", () => app.getVersion());
ipcMain.handle("app:platform", () => process.platform);
ipcMain.handle("link:open-external", async (_event, target) => {
  try {
    const url = new URL(String(target));
    const repositoryPath = "/Srimanthl2k6/shrugame";
    const allowed = url.protocol === "https:" && (
      (url.hostname === "github.com" && url.pathname.startsWith(repositoryPath)) ||
      (url.hostname === "srimanthl2k6.github.io" && url.pathname.startsWith("/shrugame"))
    );
    if (!allowed) return false;
    await shell.openExternal(url.toString());
    return true;
  } catch (_error) {
    return false;
  }
});
ipcMain.on("app:quit", () => app.quit());

app.on("second-instance", () => {
  if (!mainWindow) return;
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.focus();
});

app.whenReady().then(async () => {
  installSecurityGuards();
  await createLocalServer();
  createWindow();
});

app.on("window-all-closed", () => app.quit());
app.on("before-quit", () => {
  if (localServer) localServer.close();
});
