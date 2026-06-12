# Ollama Model Storage

## Current state (2026-06-11)

`~/.ollama/models` is a **plain local directory** on the internal drive.
Models are re-pulled by the `pullPiModels` activation in `home/pi/default.nix`
on every `darwin-rebuild switch` (only missing models are downloaded).

## History: dangling external-drive symlink

Until 2026-06-11, `~/.ollama/models` was a symlink to
`/Volumes/HD-2/ollama/models` (created 2026-04-05 to keep large model blobs
off the internal disk). External drives were later shuffled/repurposed — the
volume mounting as `HD-2` no longer contained an `ollama/` directory — so the
symlink dangled. Symptom in the switch report:

```
✗ pullPiModels  (Error: 400 Bad Request: mkdir /Users/james.maes/.ollama/models:
  file exists: ensure path elements are traversable)
```

The ollama server follows the dangling symlink when creating its store, hence
the confusing "file exists" + "not traversable" pair. Fix was to remove the
symlink and `mkdir ~/.ollama/models`.

## If moving models to an external drive again

- Prefer setting `OLLAMA_MODELS` for the ollama server over a symlink — a
  missing target then fails loudly instead of producing 400s through the API.
- Whatever the mechanism, the drive must be mounted before the ollama server
  starts and before any `darwin-rebuild switch` (pullPiModels hits the API).
- The old model store may still exist on the original (now unmounted) drive
  under `<drive>/ollama/models`; it is orphaned and safe to delete.
