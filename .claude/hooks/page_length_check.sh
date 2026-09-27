#!/usr/bin/env bash
# PostToolUse(Edit|Write): CLAUDE.md caps page files at 200 lines, 250 absolute.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // ""')
case "$f" in
  */lib/*/presentation/pages/*_page.dart) ;;
  *) exit 0 ;;
esac
[ -f "$f" ] || exit 0
n=$(wc -l < "$f" | tr -d ' ')
if [ "$n" -gt 250 ]; then
  msg="$(basename "$f") is $n lines — over the 250-line hard limit in CLAUDE.md. Move widgets into presentation/widgets/."
elif [ "$n" -gt 200 ]; then
  msg="$(basename "$f") is $n lines — past the 200-line target in CLAUDE.md (250 absolute)."
else
  exit 0
fi
jq -n --arg m "$msg" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'
