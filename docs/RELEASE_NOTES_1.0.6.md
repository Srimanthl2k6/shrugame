# Shrugame 1.0.6

Version 1.0.6 is a focused final-media and controls update.

## Changes

- The supplied `Literally My Life` Nightcore track now loops from application launch until Shrububu defeats SRMT, then remains stopped for the ending and completed saves.
- Starting a New Game clears that completed state and restarts the track from the beginning.
- The supplied children-cheering sound plays once when the birthday card appears.
- The birthday card now shows the complete, uncropped `Shrubudday.jpeg` photograph without placing text over it.
- Forms 1 and 2 use their correct horizontal source poses; Forms 3-5 are unchanged.
- Enter, E, Escape, controller Confirm, and controller Cancel return from the birthday card to the title.
- The Electron Quit button now exits through the sandboxed preload IPC API; native Godot Quit remains the fallback.

## Packaging

Windows x64 Setup and Portable packages and unsigned macOS x64/arm64 archives are provided. Platform security warnings can appear because these builds are unsigned.
