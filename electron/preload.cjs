const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("shrugameDesktop", {
  getVersion: () => ipcRenderer.invoke("app:version"),
  getPlatform: () => ipcRenderer.invoke("app:platform"),
  isFullscreen: () => ipcRenderer.invoke("window:is-fullscreen"),
  openExternal: (url) => ipcRenderer.invoke("link:open-external", url),
  quit: () => ipcRenderer.send("app:quit"),
  toggleFullscreen: () => ipcRenderer.invoke("window:toggle-fullscreen")
});
