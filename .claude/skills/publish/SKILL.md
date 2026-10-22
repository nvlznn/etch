---
name: publish
description: Release a new major version — bump, tag, GitHub release with dev log, archive, upload to App Store Connect.
disable-model-invocation: true
---

# Publish

Etch's release rules:

- Versions are major-only: the next version after `N.0` is `(N+1).0`. The build number (`CURRENT_PROJECT_VERSION`) is always `1`.
- Tags are the bare version (`4.0`). Older `v2.0` predates this rule.
- Every target (Etch, EtchWidgets, EtchTests, EtchUITests) carries the same version.

Work in a scratch directory (`$TMPDIR/etch-publish`) for notes and the archive.

1. **Pending work.** If `git status` shows changes, commit and push them following `.claude/skills/push/SKILL.md`. Done when the tree is clean and `main` matches `origin/main`.
2. **Version.** Read `MARKETING_VERSION` in `Etch.xcodeproj/project.pbxproj`, set every occurrence to the next major (`sed` all 8 lines), leave `CURRENT_PROJECT_VERSION = 1`. Build as in push step 2. Commit as `Set version to N.0 (1)` and push. Done when `grep MARKETING_VERSION` shows only `N.0`.
3. **Tag.** `git tag -a N.0 -m "Etch N.0: <one-line headline>"`, `git push origin N.0`.
4. **GitHub release.** Find the previous release tag (`git describe --tags --abbrev=0 N.0^`) and read every commit and diff in `<prev>..N.0`. Write notes with:
   - `## What's new`: user-facing changes grouped by feature, in plain words; give the zh-Hant UI name in parentheses where it helps (記錄, 打卡).
   - `## Dev log`: the code-level changes: models and migrations, new types, design decisions, test changes.
   - `**Full changes:** https://github.com/nvlznn/etch/compare/<prev>...N.0`

   Name the release `N.0 (yy.MM.dd)` with today's date, zero-padded: `5.0 (26.10.11)`.
   `gh release create N.0 -R nvlznn/etch --title "N.0 ($(date +%y.%m.%d))" --notes-file <notes> --verify-tag`. Done when it prints the release URL.
5. **Archive.** `xcodebuild archive -project Etch.xcodeproj -scheme Etch -configuration Release -destination 'generic/platform=iOS' -archivePath <scratch>/Etch-N.0.xcarchive -allowProvisioningUpdates`. Verify inside the archive's `Etch.app`: `CFBundleShortVersionString` is `N.0`, `CFBundleVersion` is `1`, and `codesign -d --entitlements -` shows `group.dev.noky.etch` on both the app and `PlugIns/EtchWidgets.appex`.
6. **Upload.** `xcodebuild -exportArchive -archivePath <archive> -exportOptionsPlist .claude/skills/publish/ExportOptions.plist -exportPath <scratch>/export -allowProvisioningUpdates`. That plist turns off `manageAppVersionAndBuildNumber`, which keeps the build at 1. Done when the output shows `Upload succeeded` and `EXPORT SUCCEEDED`.
7. **Organizer.** Copy the archive to `~/Library/Developer/Xcode/Archives/<yyyy-MM-dd>/Etch N.0 (1).xcarchive` so it shows in Xcode's Organizer.

Report the version, the release URL and the upload result. Then remind the user that App Store Connect processes the build for 5–30 minutes, and that submitting the version for review is theirs to do.
