# Bandit Relationship [B42]

> A Project Zomboid mod that brings your NPC companions to life with dynamic relationships, backstories, and daily interactions.

---

## 📖 About

**Bandit Relationship** is a mod for **Project Zomboid (Build 42)** that extends the [Bandits mod](https://steamcommunity.com/workshop/filedetails/?id=3268487204) by adding a relationship and dialogue system to your NPC companions.

Each companion (bandit) now has:
- A **pre-apocalypse profession** (randomly assigned — could be a Lawyer, Doctor, Engineer, Farmer, and many more)
- A **marital status** and **number of children**
- A **personality** (Calm, Aggressive, Stressed, Friendly, Hostile or Sad)
- A **daily mood** that changes each in-game day
- A **relationship score** with the player ranging from **-100** (hostile) to **+100** (close friends)

---

## ✨ Features

- 🗣️ **Dialogue system** — Talk to your companions about their life, their day, ask for survival tips, or even ask them to tell a joke
- 📋 **Acquaintances list** — A UI panel listing all known companions and your current relationship level with each
- 🔄 **Daily mood changes** — Each new in-game day your companion's mood updates, affecting dialogue responses
- 💬 **Relationship scaling** — Dialogues and options available to you vary depending on your relationship level with each NPC
- 🗑️ **Remove companions** — Remove a companion from your acquaintances list directly from the UI

---

## 🔧 Requirements

| Dependency | Link |
|---|---|
| Project Zomboid **Build 42** | [Steam](https://store.steampowered.com/app/108600/Project_Zomboid/) |
| **Bandits** mod | [Steam Workshop](https://steamcommunity.com/workshop/filedetails/?id=3268487204) |

---

## 📦 Installation

### Via Steam Workshop (Recommended)

1. Subscribe to the mod on the [Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3431259170)
2. Launch Project Zomboid
3. Go to **Main Menu → Mods** and enable **Bandit Relationship [B42]**
4. Make sure the **Bandits** mod is also enabled and listed as a dependency
5. Start or load a save

### Manual Installation

1. Download or clone this repository
2. Copy the `Contents/mods/BanditRelationship` folder into your Project Zomboid mods directory:
   - **Windows:** `C:\Users\<YourName>\Zomboid\mods\`
   - **Linux:** `~/.local/share/Zomboid/mods/`
   - **macOS:** `~/Zomboid/mods/`
3. Launch Project Zomboid, enable the mod in **Main Menu → Mods**, and start your game

---

## 🎮 How to Use in Game

### Opening the Acquaintances List

Press **Z** (default keybind) to open the **Acquaintances List** panel. This shows all companions you have interacted with and your current relationship score with each.

> You can change the keybind in **Options → Mods → Bandit Dialogues**.

### Talking to a Companion

Approach a Bandit companion and interact with them (right-click or the standard interaction key). A dialogue menu will appear with available conversation topics based on your current relationship level:

| Relationship Level | Available Topics |
|---|---|
| Any | Greet, ask about their day |
| Positive (> 0) | Ask about their life, survival tips |
| Higher positive | Ask for jokes, deeper personal conversations |

### Relationship Score

Each dialogue choice affects your relationship score:

- ✅ Positive interactions increase the score (up to **+100**)
- ❌ Negative or annoying interactions decrease the score (down to **-100**)

The relationship score is **saved per companion** and **persists across sessions**.

### Removing a Companion from the List

In the **Acquaintances List** panel, each entry has a **Remove** button. Clicking it will delete that companion's data from your records. This is useful if a companion has died or you no longer want to track the relationship.

---

## 🔮 Planned Future Features

- More depth and personal history for each NPC
- Additional relationship milestones and events
- Conversations that grant XP in skills based on the companion's pre-apocalypse profession
- More personality-driven dialogue variations

---

## 🌐 Languages Supported

| Language | Status |
|---|---|
| English | ✅ Supported |
| Portuguese (BR) | ✅ Supported |
| Russian | ✅ Supported |
| Ukrainian | ✅ Supported |

---

## 👤 Author

**Freeze**

---

## 📄 License

This project is distributed as a Project Zomboid mod. Please respect the original author's work when redistributing or building upon it.
