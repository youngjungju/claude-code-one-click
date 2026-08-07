<p align="center">
  <img src="assets/banner.svg" alt="Claude Code One-Click Install — paste one line, done" width="100%">
</p>

# ⚡ Claude Code One-Click Install

[🇰🇷 한국어](README.md) · **[🇺🇸 English](README.en.md)**

> Never used a terminal before? No problem. Installing takes exactly three actions:
>
> ### ① Click the copy button on the command below → ② Paste into Terminal / PowerShell → ③ Press Enter
>
> Everything else — install, setup, Node.js, launch — happens automatically.

[![Install on macOS](https://img.shields.io/badge/🍎_macOS-Install-0071e3?style=for-the-badge)](#-install-on-macos)
[![Install on Windows](https://img.shields.io/badge/🪟_Windows-Install-0078d4?style=for-the-badge)](#-install-on-windows)
[![I'm stuck](https://img.shields.io/badge/🆘_Stuck%3F-Get_help-e74c3c?style=for-the-badge)](#-stuck-this-always-works)

> **Note:** the installer's progress messages are currently in Korean. The steps and this guide are fully in English, and the install works identically.

## ✅ One thing to check first

Claude Code requires a **paid Claude subscription (Pro / Max / Team / Enterprise)**. Free accounts cannot log in. Sign up at [claude.ai](https://claude.ai) first if needed.

---

## 🍎 Install on macOS

### Step 1 — Open Terminal

1. Press **⌘ Command + Space** (Spotlight search opens)
2. Type **terminal** and press **Enter**

### Step 2 — Copy & paste this one line

Hover over the box below and click the **copy button (📋)** in its top-right corner.

```bash
curl -fsSL https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-mac.sh | bash
```

Click the Terminal window, paste with **⌘ Command + V**, press **Enter**.

### Step 3 — Done!

You'll see progress steps `[1/6]`...`[6/6]`, then a success banner. Claude launches automatically after 3 seconds — log in when your browser opens. From now on, just type `claude` in any terminal.

---

## 🪟 Install on Windows

### Step 1 — Open PowerShell

1. Press the **⊞ Windows key**
2. Type **powershell** and press **Enter**

### Step 2 — Copy & paste this one line

Click the **copy button (📋)** in the top-right corner of the box below.

```powershell
irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex
```

**Right-click** inside the PowerShell window to paste, then press **Enter**.

### Step 3 — Done!

After `[1/7]`...`[7/7]` and the success banner, Claude launches automatically. Log in when your browser opens.

---

## 🆘 Stuck? This always works

No matter where it stopped or what the error says:

1. Select the entire terminal/PowerShell screen with your mouse and copy it
2. Open a new chat at [claude.ai](https://claude.ai)
3. Paste this:

```
I got stuck installing Claude Code. Below is my full screen. How do I fix it?
---
(paste your copied screen here)
```

Claude will diagnose your exact situation. Afterwards, **close and reopen** the terminal window and run the install command again — it safely restarts from the beginning.

## ❓ Common issues

| Symptom | Fix |
|---|---|
| `'claude' is not recognized` | **Fully close and reopen** the terminal/PowerShell window, then type `claude` again |
| `App unavailable in region` | Connect via VPN (US/Japan) and retry |
| Logged in but `API Error 400 ... organization disabled` | An `ANTHROPIC_API_KEY` environment variable is overriding your subscription — the installer warns about this; follow its guidance or use the [Stuck?](#-stuck-this-always-works) method |
| Can't log in with a free account | Expected — a paid subscription (Pro or higher) is required |

## 🔍 What the script actually does (transparency)

1. Skips reinstall if Claude Code already works (auto-repairs corrupted installs)
2. Runs the [official Anthropic installer](https://claude.ai/install.sh) — this repo merely wraps it with beginner-friendly automation (PATH setup, common-trap detection, guided errors)
3. Makes the `claude` command work in your terminal
4. Detects settings that block login
5. Installs **Node.js** LTS if missing (Mac: nvm — no admin password / Windows: winget) — failures never block the Claude Code install
6. Verifies the install, then launches Claude

All code is right here in this repository for inspection.
