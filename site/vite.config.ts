import { defineConfig } from "vite";

export default defineConfig({
  base: "/shrugame/",
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
