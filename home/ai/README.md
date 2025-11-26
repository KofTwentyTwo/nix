# AI Agent Configuration Module

This Home Manager module manages the `~/.ai/` directory, which contains configuration files for LLM-based coding assistants and AI agents.

## Overview

The `~/.ai/` directory provides a standardized way to communicate your preferences, workflows, and coding standards to AI assistants. All files are managed declaratively through Nix Home Manager.

## Structure

```
~/config/nix/home/ai/
├── default.nix          # Home Manager module (imports into home configuration)
├── rules.md             # Agent behavioral rules (referenced by default.nix)
├── preferences.yaml     # Machine-readable preferences (referenced by default.nix)
├── coding-style.md      # Engineering style guide (referenced by default.nix)
└── README.md            # This file

Generated files in ~/.ai/:
├── profile.md           # Personal operating profile (inline in default.nix)
├── rules.md             # Symlinked from this directory
├── preferences.yaml     # Symlinked from this directory
└── coding-style.md      # Symlinked from this directory
```

## Files

### profile.md
Personal operating profile describing:
- Who you are and your role
- Technical expertise and language preferences
- Communication style preferences
- Active projects and initiatives
- Long-term technical philosophy

**Location:** Inline in `default.nix` (easier to update frequently)

### rules.md
Agent behavioral rules defining:
- Core behavior and identity
- Decision-making policies
- When to ask vs. act autonomously
- Safety boundaries
- QQQ-specific conventions

**Location:** `./rules.md` (sourced via `home.file.source`)

### preferences.yaml
Machine-readable preferences including:
- Communication settings
- Language preferences and style guides
- Agent autonomy level
- Tool configurations
- Workflow definitions

**Location:** `./preferences.yaml` (sourced via `home.file.source`)

### coding-style.md
Engineering style guide covering:
- General coding principles
- Language-specific conventions (Java, Nix, Shell, Rust, Python)
- Comment and documentation standards
- Git commit message format
- Testing standards

**Location:** `./coding-style.md` (sourced via `home.file.source`)

## Usage

### Initial Setup

The module is already imported in `~/config/nix/home/default.nix`. To deploy:

```bash
cd ~/config/nix
darwin-rebuild switch --flake .
```

This will create the `~/.ai/` directory with all configuration files.

### Updating Configuration

1. **Edit files in this directory:**
   ```bash
   cd ~/config/nix/home/ai
   # Edit rules.md, preferences.yaml, or coding-style.md
   # Or edit profile.md inline in default.nix
   ```

2. **Rebuild to apply changes:**
   ```bash
   cd ~/config/nix
   darwin-rebuild switch --flake .
   ```

3. **Verify changes:**
   ```bash
   ls -la ~/.ai/
   cat ~/.ai/profile.md
   ```

### Version Control

All files in this directory are tracked in Git:
```bash
cd ~/config/nix
git add home/ai/
git commit -m "docs(ai): update agent configuration"
git push
```

## Design Decisions

### Why Nix-Managed?

1. **Reproducibility:** Configuration is version-controlled and can be deployed to any machine
2. **Declarative:** Changes are explicit and auditable
3. **Atomic:** Updates are transactional (all-or-nothing)
4. **Consistency:** Follows the same pattern as other dotfile management

### Why Separate Files?

- **profile.md:** Inline in `default.nix` for quick updates (changes frequently)
- **rules.md, preferences.yaml, coding-style.md:** Separate files (more stable, easier to edit)

### File Placement Strategy

Files that change frequently (like active projects in profile.md) are inline in `default.nix` for quick editing. Files that are more stable are separate for better organization.

## Integration with AI Assistants

### Cursor AI / Claude

When using Cursor or similar AI-powered IDEs, you can reference these files:

```markdown
Please review my coding preferences in ~/.ai/preferences.yaml and 
follow the style guide in ~/.ai/coding-style.md.
```

### ChatGPT / Claude API

You can include these files as context:

```bash
cat ~/.ai/profile.md ~/.ai/rules.md ~/.ai/preferences.yaml | pbcopy
# Paste into your conversation
```

### Custom Tooling

Build custom tools that read from `~/.ai/`:

```python
import yaml

with open(os.path.expanduser("~/.ai/preferences.yaml")) as f:
    prefs = yaml.safe_load(f)
    
verbosity = prefs['communication']['verbosity']
```

## Maintenance

### Regular Updates

Update your profile periodically to reflect:
- Current projects and active branches
- New expertise or technology focus
- Changes in communication preferences
- Lessons learned from AI interactions

### Syncing Across Machines

Since this is managed by Nix:

1. **On primary machine:**
   ```bash
   cd ~/config/nix
   git add home/ai/
   git commit -m "feat(ai): update preferences"
   git push
   ```

2. **On other machines:**
   ```bash
   cd ~/config/nix
   git pull
   darwin-rebuild switch --flake .
   ```

## Troubleshooting

### Files Not Appearing

Check Home Manager generation:
```bash
home-manager generations
ls -la ~/.local/state/nix/profiles/home-manager/home-files/.ai/
```

### Symlinks Broken

Rebuild Home Manager:
```bash
cd ~/config/nix
darwin-rebuild switch --flake .
```

### Syntax Errors

Validate Nix syntax:
```bash
cd ~/config/nix
nix flake check --show-trace
```

### YAML Validation

Validate preferences.yaml:
```bash
yamllint ~/config/nix/home/ai/preferences.yaml
# Or
python3 -c "import yaml; yaml.safe_load(open('preferences.yaml'))"
```

## Examples

### Example: Updating Active Project

Edit `default.nix`, find the "Active Initiatives" section in profile.md:

```nix
### Current Work
- **Feature:** New authentication system
- **Branch:** `feature/oauth2-integration`
- **Status:** Initial implementation complete, testing in progress
```

Then rebuild:
```bash
darwin-rebuild switch --flake ~/config/nix
```

### Example: Changing Autonomy Level

Edit `preferences.yaml`:

```yaml
agent:
  autonomy_level: 3  # 0=ask everything, 1=ask major, 2=act on patterns, 3=suggest improvements
```

Then rebuild to apply.

### Example: Adding New Language Standards

Edit `coding-style.md`, add a new section:

```markdown
### Go

#### Formatting
- Use `gofmt` (standard Go formatting)
- No line length limit
- Tab indentation (Go standard)
```

Then rebuild to propagate changes.

## Related Documentation

- **Nix Flake:** `~/config/nix/flake.nix`
- **Home Manager Main:** `~/config/nix/home/default.nix`
- **QQQ Code Style:** `/Users/james.maes/Git.Local/QRun-IO/qqq/CODE_STYLE.md`
- **QQQ Contributing:** `/Users/james.maes/Git.Local/QRun-IO/qqq/CONTRIBUTING.md`

## Future Enhancements

Potential additions to this module:

- [ ] Per-project AI configuration overrides
- [ ] Machine-specific profile sections
- [ ] Integration with commit message templates
- [ ] Automated context generation for PRs
- [ ] LLM prompt templates for common tasks
- [ ] Project-specific coding conventions overlay

## License

This configuration is part of your personal Nix configuration and follows the same license as the parent repository.

---

**Maintained by:** James Maes  
**Last Updated:** 2025-11-26  
**Nix Version:** Flakes-enabled  
**Home Manager Version:** Latest stable

