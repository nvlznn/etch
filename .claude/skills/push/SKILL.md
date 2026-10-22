---
name: push
description: Commit all pending work in focused commits and push to origin main.
disable-model-invocation: true
---

# Push

Etch is a solo project: work goes straight to `main` on `origin`, no branches or PRs.

1. **Read the changes.** `git status` and `git diff`. Every changed file is accounted for: either it belongs in a commit below, or you ask the user about it (an unexpected or generated file).
2. **Build.** `xcodebuild build -project Etch.xcodeproj -scheme Etch -destination 'generic/platform=iOS Simulator' -quiet`. Done when it ends in `BUILD SUCCEEDED`; fix compile errors before committing.
3. **Commit.** One commit per feature or fix, in the style of `git log`:
   - Imperative subject, at most 72 characters (`Add habit notes, reorder on Check-In`).
   - Blank line, then `- ` bullets saying what changed for the user and why, wrapped at 72.
   - End the message with the attribution lines from this session's system reminder.
4. **Push.** `git push origin main`. Done when `git status -sb` shows `## main...origin/main` with nothing ahead.

Report each commit as hash + subject.
