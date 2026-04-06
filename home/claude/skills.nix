# Claude Code Skills Module
# =========================
# Manages ~/.claude/skills/ with curated PM/PO/Agile skills from community repos.
#
# Skills are fetched as flake inputs (pinned in flake.lock) and symlinked
# into ~/.claude/skills/ as read-only Nix store paths.
#
# To update skills: nix flake update
# To add/remove skills: edit the `selectedSkills` list below.
#
# Skill sources:
#   - phuryn/pm-skills: Sprint planning, PRDs, OKRs, discovery, strategy
#   - alirezarezvani/claude-skills: Scrum master, Jira, Confluence, product toolkit
#   - SpillwaveSolutions/jira: Deep Jira operations
#   - product-on-purpose/pm-skills: Triple Diamond PM framework
#   - deanpeters/Product-Manager-Skills: Interactive PM skills with templates
#   - automazeio/ccpm: GitHub Issues-based PM workflow

{ config, lib, inputs ? {}, ... }:

let
  # Shorthand for the fetched source trees
  phuryn = inputs.claude-skills-phuryn or null;
  alireza = inputs.claude-skills-alireza or null;
  spillwave = inputs.claude-skills-spillwave-jira or null;
  pop = inputs.claude-skills-product-on-purpose or null;
  deanpeters = inputs.claude-skills-deanpeters or null;
  ccpm = inputs.claude-skills-ccpm or null;

  # Helper: create a home.file entry for a skill directory
  # Maps source-repo/path -> ~/.claude/skills/<namespace>--<name>/
  mkSkill = namespace: name: src: path: {
    ".claude/skills/${namespace}--${name}".source = "${src}/${path}";
  };

  # Helper: create a home.file entry for a single-directory skill (root level)
  mkRootSkill = namespace: name: src: {
    ".claude/skills/${namespace}--${name}".source = src;
  };

  # ─────────────────────────────────────────────────────────────
  # SKILL SELECTION
  # ─────────────────────────────────────────────────────────────
  # Edit these lists to add/remove skills.
  # Format: mkSkill "<namespace>" "<skill-name>" <source> "<path-in-repo>"

  # phuryn/pm-skills: Plugin-based, skills at {plugin}/skills/{name}/
  phurynSkills = lib.optionalAttrs (phuryn != null) (lib.attrsets.mergeAttrsList [
    # pm-execution (sprint, PRDs, stories, OKRs, retros, meetings)
    (mkSkill "phuryn" "sprint-plan" phuryn "pm-execution/skills/sprint-plan")
    (mkSkill "phuryn" "create-prd" phuryn "pm-execution/skills/create-prd")
    (mkSkill "phuryn" "user-stories" phuryn "pm-execution/skills/user-stories")
    (mkSkill "phuryn" "job-stories" phuryn "pm-execution/skills/job-stories")
    (mkSkill "phuryn" "brainstorm-okrs" phuryn "pm-execution/skills/brainstorm-okrs")
    (mkSkill "phuryn" "outcome-roadmap" phuryn "pm-execution/skills/outcome-roadmap")
    (mkSkill "phuryn" "retro" phuryn "pm-execution/skills/retro")
    (mkSkill "phuryn" "summarize-meeting" phuryn "pm-execution/skills/summarize-meeting")
    (mkSkill "phuryn" "pre-mortem" phuryn "pm-execution/skills/pre-mortem")
    (mkSkill "phuryn" "stakeholder-map" phuryn "pm-execution/skills/stakeholder-map")
    (mkSkill "phuryn" "test-scenarios" phuryn "pm-execution/skills/test-scenarios")
    (mkSkill "phuryn" "release-notes" phuryn "pm-execution/skills/release-notes")
    (mkSkill "phuryn" "prioritization-frameworks" phuryn "pm-execution/skills/prioritization-frameworks")
    (mkSkill "phuryn" "wwas" phuryn "pm-execution/skills/wwas")
    (mkSkill "phuryn" "dummy-dataset" phuryn "pm-execution/skills/dummy-dataset")

    # pm-product-discovery (experiments, assumptions, interviews, metrics)
    (mkSkill "phuryn" "opportunity-solution-tree" phuryn "pm-product-discovery/skills/opportunity-solution-tree")
    (mkSkill "phuryn" "brainstorm-experiments-existing" phuryn "pm-product-discovery/skills/brainstorm-experiments-existing")
    (mkSkill "phuryn" "brainstorm-experiments-new" phuryn "pm-product-discovery/skills/brainstorm-experiments-new")
    (mkSkill "phuryn" "brainstorm-ideas-existing" phuryn "pm-product-discovery/skills/brainstorm-ideas-existing")
    (mkSkill "phuryn" "brainstorm-ideas-new" phuryn "pm-product-discovery/skills/brainstorm-ideas-new")
    (mkSkill "phuryn" "identify-assumptions-existing" phuryn "pm-product-discovery/skills/identify-assumptions-existing")
    (mkSkill "phuryn" "identify-assumptions-new" phuryn "pm-product-discovery/skills/identify-assumptions-new")
    (mkSkill "phuryn" "interview-script" phuryn "pm-product-discovery/skills/interview-script")
    (mkSkill "phuryn" "metrics-dashboard" phuryn "pm-product-discovery/skills/metrics-dashboard")
    (mkSkill "phuryn" "prioritize-assumptions" phuryn "pm-product-discovery/skills/prioritize-assumptions")
    (mkSkill "phuryn" "prioritize-features" phuryn "pm-product-discovery/skills/prioritize-features")
    (mkSkill "phuryn" "summarize-interview" phuryn "pm-product-discovery/skills/summarize-interview")
    (mkSkill "phuryn" "analyze-feature-requests" phuryn "pm-product-discovery/skills/analyze-feature-requests")

    # pm-product-strategy (business models, vision, competitive analysis)
    (mkSkill "phuryn" "product-strategy" phuryn "pm-product-strategy/skills/product-strategy")
    (mkSkill "phuryn" "product-vision" phuryn "pm-product-strategy/skills/product-vision")
    (mkSkill "phuryn" "value-proposition" phuryn "pm-product-strategy/skills/value-proposition")
    (mkSkill "phuryn" "lean-canvas" phuryn "pm-product-strategy/skills/lean-canvas")
    (mkSkill "phuryn" "business-model" phuryn "pm-product-strategy/skills/business-model")
    (mkSkill "phuryn" "swot-analysis" phuryn "pm-product-strategy/skills/swot-analysis")
    (mkSkill "phuryn" "porters-five-forces" phuryn "pm-product-strategy/skills/porters-five-forces")
    (mkSkill "phuryn" "pestle-analysis" phuryn "pm-product-strategy/skills/pestle-analysis")
    (mkSkill "phuryn" "ansoff-matrix" phuryn "pm-product-strategy/skills/ansoff-matrix")
    (mkSkill "phuryn" "pricing-strategy" phuryn "pm-product-strategy/skills/pricing-strategy")
    (mkSkill "phuryn" "monetization-strategy" phuryn "pm-product-strategy/skills/monetization-strategy")
    (mkSkill "phuryn" "startup-canvas" phuryn "pm-product-strategy/skills/startup-canvas")
  ]);

  # alirezarezvani/claude-skills: Category-based, skills at {category}/{name}/
  alirezaSkills = lib.optionalAttrs (alireza != null) (lib.attrsets.mergeAttrsList [
    # Project management
    (mkSkill "alireza" "scrum-master" alireza "project-management/scrum-master")
    (mkSkill "alireza" "jira-expert" alireza "project-management/jira-expert")
    (mkSkill "alireza" "confluence-expert" alireza "project-management/confluence-expert")
    (mkSkill "alireza" "atlassian-templates" alireza "project-management/atlassian-templates")
    (mkSkill "alireza" "senior-pm" alireza "project-management/senior-pm")
    (mkSkill "alireza" "meeting-analyzer" alireza "project-management/meeting-analyzer")
    (mkSkill "alireza" "team-communications" alireza "project-management/team-communications")

    # Product team
    (mkSkill "alireza" "agile-product-owner" alireza "product-team/agile-product-owner")
    (mkSkill "alireza" "product-manager-toolkit" alireza "product-team/product-manager-toolkit")
    (mkSkill "alireza" "product-strategist" alireza "product-team/product-strategist")
    (mkSkill "alireza" "product-discovery" alireza "product-team/product-discovery")
    (mkSkill "alireza" "product-analytics" alireza "product-team/product-analytics")
    (mkSkill "alireza" "roadmap-communicator" alireza "product-team/roadmap-communicator")
    (mkSkill "alireza" "competitive-teardown" alireza "product-team/competitive-teardown")
    (mkSkill "alireza" "experiment-designer" alireza "product-team/experiment-designer")
    (mkSkill "alireza" "code-to-prd" alireza "product-team/code-to-prd")
    (mkSkill "alireza" "research-summarizer" alireza "product-team/research-summarizer")
  ]);

  # SpillwaveSolutions/jira: Root-level skill
  spillwaveSkills = lib.optionalAttrs (spillwave != null) (
    mkRootSkill "spillwave" "jira" spillwave
  );

  # product-on-purpose/pm-skills: Triple Diamond, skills at skills/{phase}-{name}/
  popSkills = lib.optionalAttrs (pop != null) (lib.attrsets.mergeAttrsList [
    # Discover
    (mkSkill "pop" "competitive-analysis" pop "skills/discover-competitive-analysis")
    (mkSkill "pop" "interview-synthesis" pop "skills/discover-interview-synthesis")
    (mkSkill "pop" "stakeholder-summary" pop "skills/discover-stakeholder-summary")

    # Define
    (mkSkill "pop" "hypothesis" pop "skills/define-hypothesis")
    (mkSkill "pop" "jtbd-canvas" pop "skills/define-jtbd-canvas")
    (mkSkill "pop" "opportunity-tree" pop "skills/define-opportunity-tree")
    (mkSkill "pop" "problem-statement" pop "skills/define-problem-statement")

    # Develop
    (mkSkill "pop" "adr" pop "skills/develop-adr")
    (mkSkill "pop" "solution-brief" pop "skills/develop-solution-brief")
    (mkSkill "pop" "spike-summary" pop "skills/develop-spike-summary")
    (mkSkill "pop" "design-rationale" pop "skills/develop-design-rationale")

    # Deliver
    (mkSkill "pop" "prd" pop "skills/deliver-prd")
    (mkSkill "pop" "user-stories" pop "skills/deliver-user-stories")
    (mkSkill "pop" "acceptance-criteria" pop "skills/deliver-acceptance-criteria")
    (mkSkill "pop" "edge-cases" pop "skills/deliver-edge-cases")
    (mkSkill "pop" "release-notes" pop "skills/deliver-release-notes")
    (mkSkill "pop" "launch-checklist" pop "skills/deliver-launch-checklist")

    # Measure
    (mkSkill "pop" "experiment-design" pop "skills/measure-experiment-design")
    (mkSkill "pop" "experiment-results" pop "skills/measure-experiment-results")
    (mkSkill "pop" "dashboard-requirements" pop "skills/measure-dashboard-requirements")
    (mkSkill "pop" "instrumentation-spec" pop "skills/measure-instrumentation-spec")

    # Iterate
    (mkSkill "pop" "retrospective" pop "skills/iterate-retrospective")
    (mkSkill "pop" "refinement-notes" pop "skills/iterate-refinement-notes")
    (mkSkill "pop" "lessons-log" pop "skills/iterate-lessons-log")
    (mkSkill "pop" "pivot-decision" pop "skills/iterate-pivot-decision")

    # Foundation
    (mkSkill "pop" "persona" pop "skills/foundation-persona")
  ]);

  # deanpeters/Product-Manager-Skills: Flat, skills at skills/{name}/
  deanpetersSkills = lib.optionalAttrs (deanpeters != null) (lib.attrsets.mergeAttrsList [
    (mkSkill "deanpeters" "epic-breakdown-advisor" deanpeters "skills/epic-breakdown-advisor")
    (mkSkill "deanpeters" "epic-hypothesis" deanpeters "skills/epic-hypothesis")
    (mkSkill "deanpeters" "user-story" deanpeters "skills/user-story")
    (mkSkill "deanpeters" "user-story-mapping" deanpeters "skills/user-story-mapping")
    (mkSkill "deanpeters" "user-story-splitting" deanpeters "skills/user-story-splitting")
    (mkSkill "deanpeters" "jobs-to-be-done" deanpeters "skills/jobs-to-be-done")
    (mkSkill "deanpeters" "prd-development" deanpeters "skills/prd-development")
    (mkSkill "deanpeters" "roadmap-planning" deanpeters "skills/roadmap-planning")
    (mkSkill "deanpeters" "customer-journey-map" deanpeters "skills/customer-journey-map")
    (mkSkill "deanpeters" "opportunity-solution-tree" deanpeters "skills/opportunity-solution-tree")
    (mkSkill "deanpeters" "problem-framing-canvas" deanpeters "skills/problem-framing-canvas")
    (mkSkill "deanpeters" "problem-statement" deanpeters "skills/problem-statement")
    (mkSkill "deanpeters" "lean-ux-canvas" deanpeters "skills/lean-ux-canvas")
    (mkSkill "deanpeters" "positioning-statement" deanpeters "skills/positioning-statement")
    (mkSkill "deanpeters" "proto-persona" deanpeters "skills/proto-persona")
    (mkSkill "deanpeters" "prioritization-advisor" deanpeters "skills/prioritization-advisor")
    (mkSkill "deanpeters" "storyboard" deanpeters "skills/storyboard")
    (mkSkill "deanpeters" "discovery-process" deanpeters "skills/discovery-process")
    (mkSkill "deanpeters" "product-strategy-session" deanpeters "skills/product-strategy-session")
    (mkSkill "deanpeters" "workshop-facilitation" deanpeters "skills/workshop-facilitation")
  ]);

  # automazeio/ccpm: GitHub Issues PM workflow
  ccpmSkills = lib.optionalAttrs (ccpm != null) (
    mkSkill "ccpm" "project-management" ccpm "skill/ccpm"
  );

  # Merge all skill sets into one attrset
  allSkills = phurynSkills
    // alirezaSkills
    // spillwaveSkills
    // popSkills
    // deanpetersSkills
    // ccpmSkills;
in
{
  home.file = allSkills;
}
