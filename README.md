# ⏱️ TimerApp for macOS

A beautiful, floating timer app for macOS with auto-compact mode, global hotkeys, and multiple concurrent timers.

![TimerApp Demo](https://img.shields.io/badge/macOS-13.0+-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

## ✨ Features

- 🪟 **Floating Windows** - Always-on-top timer windows that stay visible
- 🫧 **Auto-Compact Mode** - Automatically shrinks to bubble when running
- ⌨️ **Global Hotkeys** - Create new timer with ⌘+Shift+T
- 📝 **Editable Names** - Click timer title to rename
- ⏸️ **Click to Pause** - Click running timer to pause/resume
- 🎯 **Multiple Timers** - Run as many timers as you need
- 📱 **Menu Bar Integration** - Access timers from menu bar
- 🎨 **Custom Time Input** - Set any duration with picker
- 🔴 **Completion Alerts** - Red flash when timer completes

## 🚀 Quick Start

### 📥 Download (Recommended)

1. **[Download Latest Release](https://github.com/Aarush1010/Desktop-Timer/releases/latest)**
2. Unzip and drag `TimerApp.app` to Applications folder
3. **Important:** Right-click → "Open" (bypasses security warning)
4. Grant accessibility permissions when prompted

### 🛠 Build from Source

```bash
git clone https://github.com/Aarush1010/Desktop-Timer.git
cd TimerApp
swift build -c release
./.build/release/TimerApp
```

## ⚠️ Security Notice

This app is **unsigned** (free distribution). macOS will show a security warning on first launch.

**To bypass the warning:**
1. Right-click on TimerApp.app
2. Select "Open"  
3. Click "Open" in the dialog

This is normal for free macOS apps!

## 🎯 Usage

- **New Timer:** ⌘+Shift+T or menu bar → "New Timer"
- **Rename:** Click timer title to edit
- **Pause:** Click running timer bubble
- **Auto-Compact:** Timers shrink when running, expand when stopped

## 🐛 Issues

Found a bug? [Open an issue](https://github.com/Aarush1010/Desktop-Timer/issues)!

---

⭐ **Star this repo if you find it useful!** ⭐
