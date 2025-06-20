# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains ZMK firmware configuration for a 5-column Corne split ergonomic keyboard. ZMK is an open-source keyboard firmware built on the Zephyr RTOS. This configuration uses a custom ZMK fork with experimental pointer/scroll support.

## Key Position Numbering System (CRITICAL)

ZMK numbers key positions sequentially from left to right, top to bottom, across BOTH keyboard halves. For a 5-column Corne:

```
Left Half:              Right Half:
 0  1  2  3  4           5  6  7  8  9      (Row 1)
10 11 12 13 14          15 16 17 18 19      (Row 2) 
20 21 22 23 24          25 26 27 28 29      (Row 3)
   30 31 32                33 34 35         (Thumbs)

Physical Layout:
Q  W  E  R  T           Y  U  I  O  P
A  S  D  F  G           H  J  K  L  ;
Z  X  C  V  B           N  M  ,  .  /
  [thumb keys]         [thumb keys]
```

### Common Position References:
- Home row: Left (10-14), Right (15-19)
- Top row: Left (0-4), Right (5-9)
- Bottom row: Left (20-24), Right (25-29)
- Thumb clusters: Left (30-32), Right (33-35)

## Key Files

- **config/corne.keymap**: Main keymap file defining the keyboard layout, layers, combos, and behaviors
- **config/custom.keymap**: Alternative keymap with different thumb arrangements and mod-tap behavior
- **config/corne.conf**: Configuration file for keyboard settings (BT power, debouncing, mouse)
- **build.yaml**: Defines build targets for GitHub Actions
- **config/west.yml**: West manifest pointing to custom ZMK fork (petejohanson/feat/pointers-move-scroll)
- **config/corne.ss**: Experimental Gerbil Scheme compiler for generating ZMK configs from S-expressions
- **config/config.ss**: Sample S-expression configuration

## Current Layout Configuration

### Layers:
0. **Base Layer**: QWERTY with home row mods
1. **Lower Layer** (via Space): Numbers and navigation
2. **Raise Layer** (via Enter): Symbols
3. **Mouse/BT Layer** (via G): Bluetooth and mouse controls
4. **Workspace Layer** (via W): GUI+Number for workspace switching

### Home Row Mods:
- Left: A=GUI, S=Alt, D=Shift, F=Ctrl
- Right: J=Ctrl, K=Shift, L=Alt, ;=GUI

### Combos:
- **Escape**: Q+W (positions 0,1)
- **Caps Word**: D+K (positions 12,17)
- **Undo**: Z+X (positions 20,21)
- **Redo**: .+/ (positions 28,29)

### Special Behaviors:
- **doubletap**: X tap / Alt+X double-tap
- **superthumb**: Alt+X tap / Alt+Shift+7 double-tap
- **stickyctrl**: Sticky Ctrl tap / Ctrl+C double-tap

## Build Commands

### Building the Firmware Locally

```sh
# Build firmware for the left half
west build -d build/left -b nice_nano_v2 -- -DSHIELD="corne_left nice_view_adapter nice_view" -DZMK_CONFIG="/home/z80/dev/zmk-config-2/config"

# Build firmware for the right half
west build -d build/right -b nice_nano_v2 -- -DSHIELD="corne_right nice_view_adapter nice_view" -DZMK_CONFIG="/home/z80/dev/zmk-config-2/config"

# Flash the firmware (example for left half)
west flash -d build/left
```

## Making Layout Changes

When modifying the keymap:
1. Use the position numbering chart above to identify key positions
2. Remember combos use key-positions array (e.g., <20 21> for Z+X)
3. Layer activation is done with &lt (layer tap) or &mo (momentary)
4. Home row mods use &mt (mod tap) with appropriate modifiers

## ZMK Resources

- [ZMK Documentation](https://zmk.dev/docs)
- [Keycode Reference](https://zmk.dev/docs/codes)
- [Behavior Reference](https://zmk.dev/docs/behaviors)