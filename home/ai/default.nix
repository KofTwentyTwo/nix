# AI Profile Configuration Module
# ================================
# This Home Manager module manages the ~/.ai/ directory with AI agent
# configuration files. All files are generated declaratively from this module.
#
# Files managed:
#   - ~/.ai/0-init.md        Initialization instructions
#   - ~/.ai/1-profile.md     Personal operating profile
#   - ~/.ai/2-coding-style.md Engineering style guide
#   - ~/.ai/3-rules.md       Agent behavioral rules
#   - ~/.ai/4-preferences.yaml Machine-readable preferences
#   - ~/.claude/CLAUDE.md    Claude Code user-level memory (imports ~/.ai/*)
#
# Usage:
#   Import this module in home/default.nix:
#     imports = [ ./ai ];
#
# Updates:
#   Edit this file and run: darwin-rebuild switch --flake ~/.config/nix

{ config, pkgs, lib, ... }:

{
  home.file.".ai/1-profile.md".text = ''
    # Profile

    ## Overview

    **Name:** James Maes  
    **Organization:** Kingsrook, LLC / QRun.IO  
    **Role:** Software Engineer & Architect  
    **Primary Focus:** Enterprise Java development, low-code framework engineering, and declarative infrastructure management

    I am an experienced software engineer working on QQQ, an open-source low-code application framework for engineers. My work spans backend systems, middleware development, and developer tooling. I maintain a declarative development environment using Nix and Home Manager on macOS (Apple Silicon).

    ## Expertise

    ### Languages & Technologies
    - **Primary:** Java 17+ (expert level)
    - **Secondary:** Nix, Shell scripting (Bash/Zsh), Rust, Python, JavaScript
    - **Build Tools:** Maven, Homebrew
    - **Frameworks:** Javalin, Log4j2, JUnit, Spring-adjacent patterns
    - **Databases:** PostgreSQL, SQLite, MongoDB, generic RDBMS
    - **Infrastructure:** Docker, Kubernetes, AWS, Nix/NixOS, Home Manager
    - **Version Control:** Git (with GPG signing), GitHub
    - **IDEs:** IntelliJ IDEA (primary), VS Code, Neovim

    ### Domain Expertise
    - Low-code application framework design
    - Meta-data driven architectures
    - Backend module system design
    - Developer experience and tooling
    - Code quality enforcement (Checkstyle, testing standards)
    - Declarative configuration management (Nix)

    ## Communication Style

    ### Preferences
    - **Tone:** Professional, direct, and concise
    - **Verbosity:** Medium - provide context where needed, but avoid unnecessary elaboration
    - **Technical Depth:** Deep technical understanding is expected; don't oversimplify
    - **Code Examples:** Always use concrete examples from the actual codebase when relevant
    - **Documentation:** Value well-structured, maintainable documentation

    ### What I Appreciate
    - Solutions that align with existing patterns and conventions
    - Understanding of the broader architectural context
    - Recognition that I work in a multi-module Maven project
    - Awareness that code style is enforced via Checkstyle and IntelliJ formatting
    - Suggestions that consider maintainability and team consistency

    ### What I Don't Like
    - Generic advice that doesn't account for QQQ's specific patterns
    - Suggestions to deviate from established code style without justification
    - Over-engineering or unnecessary abstractions
    - Breaking changes without clear value proposition

    ## Interaction Guidelines

    ### When Working on Code
    1. **Always check existing patterns** in the codebase before suggesting new approaches
    2. **Follow QQQ code style guidelines** (see coding-style.md and CODE_STYLE.md)
    3. **Use fluent-style APIs** where they exist (e.g., `.withX().withY()` over `.setX(); .setY();`)
    4. **Include proper Javadoc comments** using the "flower box" style
    5. **Consider the multi-module structure** - understand which module you're working in

    ### When Answering Questions
    1. **Reference actual code** from the codebase when possible
    2. **Explain the "why"** behind architectural decisions
    3. **Consider QQQ conventions** for naming, structure, and patterns
    4. **Acknowledge trade-offs** when discussing design decisions

    ### When Making Suggestions
    1. **Align with existing patterns** unless there's a compelling reason to deviate
    2. **Consider test coverage requirements** (70% instruction, 90% class coverage)
    3. **Respect the MetaDataProducer pattern** for QQQ meta-data objects
    4. **Follow RecordEntity conventions** for entity classes
    5. **Use appropriate logging** (QLogger with LogPair objects)

    ## Active Initiatives

    ### Current Work
    - **Feature:** Support for multiple SPAs in Javalin middleware
    - **Branch:** `feature/support-multiple-spas`
    - **Status:** Active development with uncommitted changes

    ### Development Environment
    - **Machine:** "Darth" (Apple Silicon Mac)
    - **Nix Config:** `/Users/james.maes/config/nix/`
    - **Workspace:** `/Users/james.maes/Git.Local/QRun-IO/qqq/`
    - **QQQ Dev Tools:** Installed and in PATH

    ### Ongoing Maintenance
    - Declarative dotfile management via Nix + Home Manager
    - Integration of LLM tooling into development workflow
    - Code quality and testing standards enforcement

    ## Long-Term Themes

    ### Technical Philosophy
    - **Declarative over imperative:** Use Nix for reproducible environments
    - **Code quality matters:** Enforce standards through tooling, not just documentation
    - **Developer experience:** Invest in tools that make engineers more productive
    - **Open source first:** QQQ is AGPL-licensed and community-oriented

    ### Engineering Principles
    - Favor explicit over implicit
    - Write code for the next maintainer
    - Test at appropriate levels (unit, integration, system)
    - Document the "why" more than the "what"
    - Consistency is a feature, not a constraint

    ### Workflow Preferences
    - Use Git with conventional commits
    - Sign commits with GPG
    - Leverage Home Manager for environment management
    - Keep development environments reproducible
    - Automate repetitive tasks through tooling
  '';

  home.file.".ai/0-init.md".source = ./0-init.md;
  home.file.".ai/2-coding-style.md".source = ./2-coding-style.md;
  home.file.".ai/3-rules.md".source = ./3-rules.md;
  home.file.".ai/4-preferences.yaml".source = ./4-preferences.yaml;

  # Claude Code user-level memory file
  # Imports all ~/.ai/ config files so they load automatically in every session
  home.file.".claude/CLAUDE.md".text = ''
    # Global Development Context

    See @~/.ai/0-init.md for initialization guidelines
    See @~/.ai/1-profile.md for profile information
    See @~/.ai/2-coding-style.md for coding style standards
    See @~/.ai/3-rules.md for development rules
    See @~/.ai/4-preferences.yaml for preferences
  '';
}


