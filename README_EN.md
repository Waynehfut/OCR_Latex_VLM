# OCR LaTeX

[中文版](README.md) | **English**

> ⚠️ This is an AI-generated project. The code may contain risks — review before use in production.

OCR LaTeX is a macOS menu bar app that converts screen captures or clipboard images into LaTeX.

Created by **[drhaowang.com](https://drhaowang.com)**

## Features

- Runs in the menu bar, triggerable via global hotkey.
- Uses macOS built-in screenshot capability for region capture.
- Defaults to Apple Vision for on-device OCR — no network required.
- Switch to any Chat Completions-compatible vision LLM endpoint.
- Supports OpenAI, Volcano Engine (Volces), Alibaba Bailian, and custom endpoints.
- Results appear in a candidate panel — edit, copy, accept, or discard.
- Accepted results are saved to history and auto-copied to clipboard (configurable).

## Quick Start

```bash
./script/build_and_run.sh
```

The default global hotkey is **⌃⌥⌘L**. The app requires macOS Screen Recording permission on first capture; if denied, you can open System Settings from the dashboard or menu bar.

## LLM Backend Configuration

In the dashboard, switch the recognition backend to "Large Model" and fill in:

- Platform or custom endpoint URL
- API Key
- Model name
- Image detail level
- Recognition prompt

Request format is Chat Completions-compatible: a `messages` array with one text prompt and one base64 `image_url`. API keys are stored in the macOS Keychain.

## Notes

- **On-device OCR** works well for simple formulas and plain text.
- **Large model** mode sends the selected image to your configured endpoint — choose a provider that meets your privacy and cost requirements.
- Complex math typesetting works best with vision-capable models (e.g., GPT-4o, doubao-vision-pro, qwen-vl-plus).
