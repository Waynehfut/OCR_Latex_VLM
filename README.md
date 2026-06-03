# OCR LaTeX

OCR LaTeX is a free local macOS menu bar utility for turning selected screen regions or clipboard images into LaTeX-like text.

## Features

- Runs in the menu bar as a background utility.
- Uses macOS `screencapture` for region selection.
- Uses Apple's local Vision OCR framework.
- Can call a configured vision language model through an OpenAI Responses-compatible endpoint.
- Registers a configurable global hotkey.
- Lets you review and edit a candidate LaTeX result before accepting it.
- Copies the accepted LaTeX result to the pasteboard.

## Run

```bash
./script/build_and_run.sh
```

The default global hotkey is `⌃⌥⌘L`.

## Notes

Vision is general-purpose text OCR, not a dedicated formula model. The app adds a local normalization pass for common math symbols, Greek letters, superscripts, subscripts, simple fractions, square roots, and function names.

Large model mode sends the selected image to the configured endpoint. API keys are stored in Keychain.
