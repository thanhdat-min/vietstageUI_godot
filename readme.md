# VietStage UI — Godot (Capstone Project)

![Godot](https://img.shields.io/badge/Godot-478CBF?style=flat-square&logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-6DA55F?style=flat-square)

UI development for **VietStage** — *Virtual Artist for Vietnamese Traditional Instrument Education with Game-Based Learning*.

A 2.5D isometric virtual classroom in **Godot 4.x** where an animated virtual artist demonstrates Vietnamese traditional instruments (đàn tranh, đàn bầu, sáo trúc, trống) and learners practice with real-time audio feedback.

## 🎮 Project Overview

| | |
|---|---|
| **Project** | VietStage — Capstone Project |
| **Engine** | Godot 4.x (2.5D isometric) |
| **Language** | GDScript |
| **Concept** | Game-based learning for Vietnamese traditional music education |

## ✨ UI Modules

- `ui/` — Core UI scenes (HUD, menus, progress dashboard)
- `interactables/` — Interactive instrument stations
- `learner/` — Learner profile and practice mode screens
- `levels/` — Lesson navigation and level structure
- `virtual_artist/` — Virtual artist demonstration UI

## 🎯 Design Goals

- **Practice mode** with real-time visual feedback (pitch indicator, rhythm bar, accuracy meter)
- **Mini-games**: rhythm matching, note recognition quizzes, melody completion
- **Achievement system**: stars per lesson, unlockable rewards, daily challenges
- **Progress dashboard**: accuracy trends, practice time, badges

## 🔗 Related

- Backend: Spring Boot (Java) / Python FastAPI
- Audio analysis: GDExtension (C++) — YIN pitch detection, onset detection
- Web dashboards: React + Tailwind CSS

## ▶️ Run

Open the project folder in **Godot 4.x** and press `F5` (or `Run Project`).

## 📄 License

Capstone project — educational purposes.