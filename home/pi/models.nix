# Pi providers + models. Rendered to ~/.pi/agent/models.json via
# home/pi/default.nix. Pi hot-reloads this on every `/model` invocation.
#
# Auth strategy:
#   - ollama: no auth (apiKey = "ollama" is a dummy)
#   - anthropic / openai / google: subscription auth — first /model selection
#     triggers browser OAuth using existing Claude Code / Codex / Gemini CLI sessions
#
# Default model is claude-opus-4-7 (set in SYSTEM.md).
#
# Deferred: Groq provider — add when op://Personal/groq-api-key/credential
# exists in 1Password. Uses !op read shell-command auth pattern.

{
  providers = {
    ollama = {
      baseUrl = "http://localhost:11434/v1";
      api = "openai-completions";
      apiKey = "ollama";
      models = [
        { id = "qwen3-coder:30b";                name = "Qwen3 Coder 30B (local)";   contextWindow = 256000; }
        { id = "qwen2.5-coder:7b";               name = "Qwen2.5 Coder 7B (fast)";   contextWindow = 128000; }
        { id = "llama3.3:70b-instruct-q4_K_M";   name = "Llama 3.3 70B (reasoning)"; }
      ];
    };
    anthropic = {
      api = "anthropic-messages";
      models = [
        { id = "claude-opus-4-7";   name = "Claude Opus 4.7"; }
        { id = "claude-sonnet-4-6"; name = "Claude Sonnet 4.6"; }
      ];
    };
    openai = {
      api = "openai-responses";
      models = [ { id = "gpt-5"; name = "GPT-5"; } ];
    };
    google = {
      api = "google-generative-ai";
      models = [ { id = "gemini-2.5-pro"; name = "Gemini 2.5 Pro"; } ];
    };
    # groq: deferred — add when op://Personal/groq-api-key/credential exists in 1Password
  };
}
