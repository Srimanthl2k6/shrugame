const path = require("node:path");
const { spawn } = require("node:child_process");

const electronBinary = require("electron");
const appRoot = path.resolve(__dirname, "..");
const outputDir = path.resolve(process.env.SHRUGAME_SMOKE_OUTPUT || path.resolve(appRoot, "..", "builds", "qa", "electron"));
const smokeRoute = process.argv[2] || process.env.SHRUGAME_SMOKE_ROUTE || "1";
const quitMarker = path.join(outputDir, "electron-quit-verified.json");
if (smokeRoute === "quit_button") {
  try { require("node:fs").unlinkSync(quitMarker); } catch (_error) { /* Marker did not exist. */ }
}
const childEnvironment = { ...process.env };
delete childEnvironment.ELECTRON_RUN_AS_NODE;
const child = spawn(electronBinary, [appRoot], {
  cwd: appRoot,
  env: {
    ...childEnvironment,
    SHRUGAME_SMOKE: "1",
    SHRUGAME_SMOKE_OUTPUT: outputDir,
    SHRUGAME_SMOKE_ROUTE: smokeRoute
  },
  stdio: "inherit"
});

const watchdog = setTimeout(() => {
  child.kill("SIGKILL");
  console.error(`Electron smoke timed out for route ${smokeRoute}`);
  process.exit(1);
}, smokeRoute === "quit_button" ? 20000 : 120000);

child.on("exit", (code) => {
  clearTimeout(watchdog);
  if (smokeRoute === "quit_button" && !require("node:fs").existsSync(quitMarker)) {
	console.error("Electron Quit smoke exited without receiving the secure quit IPC command");
	process.exit(1);
	return;
  }
  process.exit(code ?? 1);
});
child.on("error", (error) => {
  console.error(error);
  process.exit(1);
});
