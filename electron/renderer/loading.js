const frame = document.querySelector("#game-frame");
const loading = document.querySelector("#loading");
const status = document.querySelector("#loading-status");
const progress = document.querySelector("#loading-progress");
const enterButton = document.querySelector("#enter-game");
const fullscreenButton = document.querySelector("#fullscreen");
const buildLabel = document.querySelector("#build-label");
const isSmoke = new URLSearchParams(window.location.search).has("smoke");

let attempts = 0;

async function updateVersion() {
  const version = await window.shrugameDesktop.getVersion();
  buildLabel.textContent = `Electron build ${version}`;
}

function revealGame() {
  loading.classList.add("is-hidden");
  const canvas = frame.contentDocument && frame.contentDocument.querySelector("canvas");
  frame.focus();
  if (frame.contentWindow) frame.contentWindow.focus();
  if (canvas) canvas.focus();
}

function pollGame() {
  attempts += 1;
  const frameDocument = frame.contentDocument;
  const canvas = frameDocument && frameDocument.querySelector("canvas");
  const percent = Math.min(92, 10 + attempts * 4);
  progress.style.width = `${percent}%`;
  status.textContent = attempts < 5 ? "Reading the Ishiville weather..." : "Opening the road to Divorcee Harbour...";
  if (canvas && canvas.width > 0 && canvas.height > 0) {
    progress.style.width = "100%";
    status.textContent = "The town noticed you.";
    enterButton.hidden = false;
    loading.classList.add("is-ready");
    if (isSmoke) revealGame();
    return;
  }
  if (attempts >= 80) {
    status.textContent = "Ishiville did not answer. The game export may be missing.";
    progress.style.width = "100%";
    progress.style.background = "#d85151";
    return;
  }
  window.setTimeout(pollGame, 250);
}

frame.addEventListener("load", pollGame, { once: true });
frame.addEventListener("error", () => {
  status.textContent = "The game files could not be loaded.";
});
enterButton.addEventListener("click", revealGame);
fullscreenButton.addEventListener("click", () => window.shrugameDesktop.toggleFullscreen());

updateVersion();
