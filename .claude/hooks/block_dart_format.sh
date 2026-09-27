#!/usr/bin/env bash
# PreToolUse(Bash): CLAUDE.md forbids `dart format` — the code predates the
# Dart 3.7 formatter, so running it rewrites unrelated indentation everywhere.
cmd=$(jq -r '.tool_input.command // ""')
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]/])(dart|flutter)[[:space:]]+format([[:space:]]|$)'; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
    permissionDecisionReason: "CLAUDE.md: do not run dart format — it rewrites unrelated indentation. Match the surrounding style by hand."}}'
fi
exit 0
