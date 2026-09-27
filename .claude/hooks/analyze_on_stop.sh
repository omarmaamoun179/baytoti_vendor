#!/usr/bin/env bash
# Stop: CLAUDE.md requires `flutter analyze` to be clean — no issues at all.
# Skips when no Dart file changed since the last clean run, and never blocks
# twice in a row (stop_hook_active) so it cannot loop.
root="$(cd "$(dirname "$0")/../.." && pwd)"
input=$(cat)
flutter=/Users/omar/flutter_ver/flutter_3.47.3/bin/flutter
stamp="$root/.dart_tool/.claude_analyze_stamp"

[ -x "$flutter" ] || exit 0
if [ -f "$stamp" ] && [ -z "$(find "$root/lib" "$root/test" -name '*.dart' -newer "$stamp" 2>/dev/null | head -1)" ]; then
  exit 0
fi

out=$(cd "$root" && "$flutter" analyze --no-pub 2>&1)
if printf '%s' "$out" | grep -q 'No issues found'; then
  mkdir -p "$root/.dart_tool" && touch "$stamp"
  exit 0
fi

issues=$(printf '%s\n' "$out" | grep -E '^ *(error|warning|info) •' | head -30)
if [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ]; then
  jq -n --arg i "$issues" '{systemMessage: ("flutter analyze is still not clean:\n" + $i)}'
  exit 0
fi
jq -n --arg i "$issues" '{decision: "block", reason: ("flutter analyze is not clean (CLAUDE.md requires no issues). Fix these before finishing:\n" + $i)}'
