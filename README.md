# AI4AII — Local AI frontend

**AI4AII** is a lightweight, AI frontend designed for fast, local large‑language‑model inference using **llama.cpp**. It provides a minimal, portable foundation for embedding LLM capabilities directly into native applications—without cloud dependencies, external services, or heavyweight frameworks.

The project focuses on **privacy‑first AI**, **low‑latency inference**, and **clean integration** with higher‑level systems such as digital humans, film engines, or conversational interfaces.

---

## ✨ Overview

AI4All implements a compact **Dart** wrapper around **llama.cpp**, enabling:

- Local inference with GGUF models  
- Simple prompt/response execution  
- Configurable context, sampling, and runtime parameters  
- Easy embedding into larger engines or UI layers  
- Zero external dependencies beyond llama.cpp  

AI4All acts as the “AI core” for applications that need deterministic, offline, and secure LLM behavior—ideal for real‑time agents, film pipelines, or embodied AI systems.

---

## 🧩 Key Features

- **Local LLM Inference**  
  Runs entirely on‑device using llama.cpp, ensuring privacy and predictable performance.

- **Minimal C++ API**  
  Clean, header‑driven interface for loading models, sending prompts, and receiving responses.

- **Configurable Runtime**  
  Supports context size, temperature, top‑k/top‑p, repeat penalties, and other generation parameters.

- **Embeddable Architecture**  
  Designed to plug into engines, assistants, or digital human systems without heavy integration work.

- **Deterministic & Reproducible**  
  Ideal for pipelines where consistent output matters (storyboards, shot generation, scripted agents).

---

## 🔌 Integration Scenarios

AI4AII is designed to serve as the AI backbone for:

- **Digital human interfaces** (MetaHuman‑style agents)  
- **Cinematic AI systems** using Unnu FilmMaker + UnnuFM  
- **Voice‑driven assistants** using UnnuTTS  
- **Local creative tools** (storyboarding, shot generation, script helpers)  
- **Offline conversational agents**  
- **Privacy‑first enterprise applications**  

Its minimal footprint makes it ideal for embedding into real‑time or resource‑constrained environments.

---

## 🛠️ Configuration

AI4AII exposes runtime parameters such as:

- `context_size`  
- `temperature`  
- `top_k`, `top_p`  
- `repeat_penalty`  
- `max_tokens`  

These can be set per‑request or globally depending on your integration needs.

---

## 📜 License

AI4All is released under the **MIT License**, allowing unrestricted use in commercial and non‑commercial applications.

If you want, I can also prepare a **branch‑specific architecture diagram** or a **developer onboarding section** that explains how AI4AII fits into your full Unnu ecosystem.
