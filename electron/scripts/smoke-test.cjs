const path = require("node:path");
const { spawn } = require("node:child_process");

const electronBinary = require("electron");
const appRoot = path.resolve(__dirname, "..");
const outputDir = path.resolve(process.env.SHRUGAME_SMOKE_OUTPUT || path.resolve(appRoot, "..", "builds", "qa", "electron"));
const smokeRoute = process.argv[2] || process.env.SHRUGAME_SMOKE_ROUTE || "1";
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

child.on("exit", (code) => process.exit(code ?? 1));
child.on("error", (error) => {
  console.error(error);
  process.exit(1);
});
