# Managing Secrets in Nix Configuration

This document outlines recommended approaches for handling sensitive values like `NPM_TOKEN` in your Nix Home Manager configuration.

## ✅ Option 1: 1Password CLI (Recommended - Already Configured)

Since you're already using 1Password, this is the most natural fit. The configuration includes a powerful `op-load-secrets` function that can load multiple secrets at once!

### Setup Steps:

#### Method 1: Load by Folder (Recommended)

1. **Create items in your NixEnvironmentVariables vault:**
   - The default vault is "NixEnvironmentVariables" (created specifically for Nix secrets)
   - Create items directly in the vault, or organize them in folders
   - Each item will become an environment variable

2. **Create secrets as API Credentials:**
   - Create items with type "API Credential"
   - Title becomes the env var name (e.g., "NPM Token" → `NPM_TOKEN`)
   - The `credential` field becomes the value

3. **Load secrets:**
   ```bash
   # Auto-detect (tries common folder names)
   op-load-secrets
   
   # Or specify folder explicitly
   op-load-secrets --folder "Environment Variables"
   ```

#### Method 2: Load by Tag

1. **Tag your secrets:**
   - Add a tag like `nix-secrets` to items you want to load
   - Works with any item type (API Credential, Password, Secure Note)

2. **Load secrets:**
   ```bash
   op-load-secrets --tag "nix-secrets"
   ```

#### Method 3: Secure Notes with Named Fields

1. **Create Secure Notes:**
   - Create a Secure Note
   - Add fields with names in `UPPERCASE_WITH_UNDERSCORES` format (e.g., `NPM_TOKEN`, `GITHUB_TOKEN`)
   - The field name becomes the env var name

2. **Load secrets:**
   ```bash
   op-load-secrets --folder "Secrets"
   # or
   op-load-secrets --tag "nix-secrets"
   ```

### Auto-Load on Shell Startup

To automatically load secrets when you open a shell, edit `/Users/james.maes/.config/nix/home/1password/default.nix` and uncomment one of these lines:

```nix
# Auto-load secrets on shell startup (uncomment to enable)
op-load-secrets  # Auto-detects from NixEnvironmentVariables vault
# Or customize it:
# op-load-secrets --folder "Environment Variables"
# op-load-secrets --tag "nix-secrets"
```

**Note:** The default vault is `NixEnvironmentVariables`. All secrets will be loaded from this vault unless you specify a different one with `--vault`.

### Examples:

```bash
# Auto-detect (tries common folders/tags)
op-load-secrets

# Load from specific folder
op-load-secrets --folder "Environment Variables"

# Load from specific tag
op-load-secrets --tag "nix-secrets"

# Load from different vault
op-load-secrets --vault "Work" --tag "dev-secrets"

# Get help
op-load-secrets --help
```

### How It Works:

- **API Credentials**: Item title → env var name, `credential` field → value
  - "NPM Token" → `NPM_TOKEN`
  - "GitHub Token" → `GITHUB_TOKEN`

- **Passwords**: Item title → env var name, `password` field → value

- **Secure Notes**: Field names in `UPPERCASE_WITH_UNDERSCORES` → env var names

### Pros:
- ✅ Already using 1Password
- ✅ Secrets never in git
- ✅ Works across machines with 1Password sync
- ✅ No additional dependencies
- ✅ Loads multiple secrets at once
- ✅ Supports folders, tags, or both
- ✅ Flexible item types (API Credential, Password, Secure Note)

### Cons:
- Requires 1Password CLI to be authenticated
- Slight delay on shell startup (can be disabled for manual loading)

---

## Option 2: External File (Simplest)

Create a gitignored file that loads the token.

### Setup Steps:

1. **Create a secrets file:**
   ```bash
   echo 'export NPM_TOKEN="your-token-here"' > ~/.config/nix/secrets.sh
   chmod 600 ~/.config/nix/secrets.sh
   ```

2. **Add to `.gitignore`:**
   ```bash
   echo "secrets.sh" >> ~/.config/nix/.gitignore
   ```

3. **Update zsh config:**
   In `home/zsh/default.nix`, add to `initContent`:
   ```nix
   initContent = lib.mkOrder 550 ''
     # ... existing content ...
     [ -f ~/.config/nix/secrets.sh ] && source ~/.config/nix/secrets.sh
   '';
   ```

### Pros:
- ✅ Very simple
- ✅ No dependencies
- ✅ Fast

### Cons:
- ❌ File must be manually synced across machines
- ❌ Not encrypted (but gitignored)

---

## Option 3: agenix (Nix-Native Secrets)

Uses Age encryption, fully integrated with Nix.

### Setup Steps:

1. **Add agenix to flake.nix:**
   ```nix
   inputs = {
     # ... existing inputs ...
     agenix.url = "github:ryantm/agenix";
   };
   ```

2. **Generate Age key:**
   ```bash
   mkdir -p ~/.config/agenix
   age-keygen -o ~/.config/agenix/keys.txt
   ```

3. **Create encrypted secret:**
   ```bash
   echo -n "your-npm-token" | agenix -e -i ~/.config/agenix/keys.txt -o secrets/npm_token.age
   ```

4. **Update configuration:**
   ```nix
   { config, agenix, ... }: {
     imports = [ agenix.homeManagerModules.default ];
     
     age.secrets.npm_token = {
       file = ./secrets/npm_token.age;
     };
     
     home.sessionVariables = {
       NPM_TOKEN = "${config.age.secrets.npm_token.path}";
     };
   }
   ```

### Pros:
- ✅ Fully integrated with Nix
- ✅ Encrypted at rest
- ✅ Reproducible builds

### Cons:
- ❌ Additional setup complexity
- ❌ Requires managing Age keys

---

## Option 4: sops-nix (Enterprise-Grade)

More powerful, supports multiple backends (AWS KMS, GCP, etc.).

### Setup Steps:

1. **Add sops-nix to flake.nix:**
   ```nix
   inputs = {
     # ... existing inputs ...
     sops-nix.url = "github:Mic92/sops-nix";
   };
   ```

2. **Generate Age key:**
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

3. **Create secrets.yaml:**
   ```yaml
   npm_token: your-npm-token-here
   ```

4. **Encrypt with sops:**
   ```bash
   sops --encrypt --age $(cat ~/.config/sops/age/keys.txt | grep public | cut -d ' ' -f 4) secrets.yaml > secrets.enc.yaml
   ```

5. **Update configuration:**
   ```nix
   { config, sops-nix, ... }: {
     imports = [ sops-nix.homeManagerModules.sops ];
     
     sops = {
       age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
       secrets.npm_token = {};
     };
     
     home.sessionVariables = {
       NPM_TOKEN = "${config.sops.secrets.npm_token.path}";
     };
   }
   ```

### Pros:
- ✅ Very secure
- ✅ Supports multiple backends
- ✅ Good for teams

### Cons:
- ❌ Most complex setup
- ❌ Overkill for single secret

---

## Recommendation

**Use Option 1 (1Password CLI)** since you're already using 1Password. It's the simplest and most consistent with your existing setup.

To complete the setup:
1. Store your NPM token in 1Password
2. Get the item reference: `op item get "NPM Token" --format json`
3. Uncomment and update the line in `home/zsh/default.nix`

