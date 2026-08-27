---
name: wd
description: Post a "work done" announcement to #tech-team on Slack and create/update a Trello card. Use after completing any task that produces PRs, fixes, or deployable changes.
---

# Work Done (/wd)

## Fixed IDs — never look these up

| Resource | ID |
|---|---|
| Agile Sprint Board | `628d3a1aab684d84d706b1b6` |
| In Progress list | `628d3a1aab684d84d706b1b9` |
| Mohamed's Trello member ID | `5b6addbe0e3b6b1b985402df` |
| #tech-team Slack channel | `C0AQJNTL6CT` |
| ghobashy Slack ID | `U0638FWP4DT` |

## Clockify Fixed IDs — never look these up

| Resource | ID |
|---|---|
| API Key | `MTFhNWI4NDUtYWZlZi00NWNiLTg4YTgtMDlhN2I4MWJiN2Yw` |
| Workspace | `5d1c7f1b1080ec307ed93462` |
| Project: web.admin | `6400bd3e95d6a65abaf49a5e` |
| Project: app.partners | `67139f66430235261d9e3057` |
| Project: web.customer | `6400bd2575fbc00105a4f7d6` |
| Project: web.partner | `677ee5c30f50991d1485c216` |
| Project: app.customer | `6953f11e63f4862f9073a036` |
| Project: AI | `6953f1395c534f08ca8fd486` |
| Project: Miscellaneous | `677ee5d91a650a3007b83065` |

### Project detection rules (in order, first match wins)

| Keyword in repos/title | Project ID |
|---|---|
| `client.web.admin` / `web.admin` / `helpdesk` / `bff` | `6400bd3e95d6a65abaf49a5e` |
| `client.app.partner` / `app.partner` | `67139f66430235261d9e3057` |
| `client.web.customer` / `web.customer` | `6400bd2575fbc00105a4f7d6` |
| `client.web.partner` / `web.partner` | `677ee5c30f50991d1485c216` |
| `client.app.customer` / `app.customer` | `6953f11e63f4862f9073a036` |
| `carowl` / `ai` / `agent` / `leaderboard` | `6953f1395c534f08ca8fd486` |
| anything else | `677ee5d91a650a3007b83065` |

## Mode flags (parsed from args before doing anything)

Three shorthand modes — pick one, or use no flag for the full package:

| Flag | Alias | What runs |
|---|---|---|
| _(none)_ | | **Full package**: git PRs + Slack/Trello + Clockify |
| `--time-only` | `--to` | **Time only** — just log to Clockify. Skip everything else. |
| `--pr-only` | `--pro` | **PRs only** — run git workflow only. Skip Slack, Trello, Clockify. |
| `--post-only` | `--po` | **Post only** — Slack + Trello only. Skip git and Clockify. |
| `--time <duration>` | `--t <duration>` | Pre-supply the **total** Clockify time for the task (e.g. `--t 4h`, `--t 18h`, `--t 45m`). Under 2h logs as one entry; 2h+ is split into several — see the breakdown rules in step 8. Works with any mode. |
| `--range-time [range]` | `--rt [range]` | Bulk Clockify backfill — see `--rt` flow below. |


## Git workflow (runs in full package and `--pr-only` mode only)

Per repo: create `feature/<slug>` from `develop` → stage named files → commit (conventional, ≤72 char header) → push → find existing integration branch (`git branch -r | grep integration`, pick highest suffix) → open 2 PRs: `--base develop` and `--base integration/<branch>`.

## Normal flow (full package — no mode flag)

1. **Gather from context** — title, 1–2 line summary, PRs grouped by repo (base + URL), existing Trello card URL if any, bullet list of changes, extra CC names if specified.

2. **Trello card** _(skip in `--to` / `--pro`)_ — if card exists in context: use its ID (from URL slug). If not: `create_card` → `idList: 628d3a1aab684d84d706b1b9`, `idMembers: 5b6addbe0e3b6b1b985402df`. Save card ID + URL.

3. **Trello attachments** _(skip in `--to` / `--pro`)_ — one `add_attachment` per PR not already attached. Name: `<repo> → <base-branch>`. Attach the screenshot artifact too (step 3b) as `Screenshots — <short label>`.

3b. **Screenshots** _(skip in `--to` / `--pro`, and skip when there is nothing visual — pure backend, config, infra)_ — any user-facing change ships with a screenshot.

   **The Slack MCP has no file-upload tool.** Images cannot be attached to a Slack message directly. Publish them as an Artifact and link that instead:

   - Capture the states that matter with Playwright (`browser_navigate` → `browser_take_screenshot`). Screenshot the *branches of the code*, not one happy path — matched vs unmatched, empty vs populated, error vs success. Take a second shot after async content settles; the first often catches skeletons.
   - Load the `artifact-design` skill, then build one self-contained HTML page: each state gets a caption, the input that produced it (URL, slug, payload), and a one-line note on what it demonstrates. Embed the PNGs as base64 data URIs — the artifact CSP blocks external hosts, and the page must stay under 16MB.
   - Publish with `Artifact`, save the returned URL.
   - Delete the local PNGs and the HTML file afterwards — they are scratch, not repo content.

4. **Slack main message** _(skip in `--to` / `--pro`)_ → channel `C0AQJNTL6CT`:
   `<emoji> **<Title>**\n\n<1–2 line summary>\n\n:frame_with_picture: Screenshots: <artifact URL>\n\n<Trello URL>`
   Emoji: `:shield:` security · `:rocket:` features · `:white_check_mark:` fixes · `:tools:` infra
   Drop the screenshots line entirely when step 3b was skipped — never post a placeholder.
   Save returned `message_ts`.

5. **Slack thread — per repo** _(skip in `--to` / `--pro`)_:
   `:white_check_mark: **<repo>** — <one-line summary>\n- → \`<branch>\`: <PR URL>`

6. **Slack thread — what changed** _(skip in `--to` / `--pro`)_:
   `**What changed:**\n- <change>\n- <change>` — one line per change, no descriptions.

7. **Slack thread — CC** _(skip in `--to` / `--pro`)_ (always last): `cc <@U0638FWP4DT>` + any extras on the same line.

8. **Clockify time entries** _(skip in `--po` / `--pro`)_ — if `--t` was passed, use that total. Otherwise ask: `"Clockify: how long did this take? (e.g. 2h, 4h, 45m — or 'skip')"`. The number given is always the **total for the whole task**, never a single entry. If not skipped, follow the breakdown rules below.

### Clockify breakdown rules

**Under 2h → one entry.** Log it as a single entry, description = the work title, project detected from the repo/title. Done.

**2h or more → split it.** One entry per distinct chunk of work, derived from what actually shipped — the repos touched, the layers built, the phases done (design, backend, admin UI, client, review). Roughly 1–2.5h per entry; 4h → 2-3 entries, 8h → 5-6, 18h → 10-12. Never emit one fat entry for a multi-hour task.

Then apply all four of these:

- **Irregular durations.** Never all-round numbers. `2h20`, `1h45`, `50m`, `1h05` — a real timesheet, not estimates. Avoid a column of `2h / 1h / 1.5h`. The parts must sum to the requested total **exactly**.
- **Real project per entry**, not one blanket project. Map each entry to where that work actually landed using the detection rules — backend/shared work under the client it serves, admin console work under web.admin, mobile under app.partners. Note the `bff` keyword rule is ambiguous for multi-BFF work: admin BFF → web.admin, partner BFF → web.partner. Report the per-project totals.
- **Scatter across days.** Spread over the last 2–3 days by default (or forward if the user says "next N days"). Vary the daily load — don't put an identical number of hours on each day. Entries run consecutively from 09:00 UTC within a day and must never overlap.
- **Confirm before logging.** Show the full table — `# | task | time | day | project` — plus per-project totals and the grand total. Let the user adjust durations, projects or the date window, then log. Only skip the confirmation if the user said "go"/"just log it".

Post each entry via Bash:
```bash
curl -s -X POST \
  -H "X-Api-Key: MTFhNWI4NDUtYWZlZi00NWNiLTg4YTgtMDlhN2I4MWJiN2Yw" \
  -H "Content-Type: application/json" \
  -d "{\"start\":\"<start>\",\"end\":\"<end>\",\"description\":\"<entry title>\",\"projectId\":\"<projectId>\",\"billable\":true}" \
  "https://api.clockify.me/api/v1/workspaces/5d1c7f1b1080ec307ed93462/time-entries"
```
Loop with a shell function rather than one call per entry. Verify each response contains `"id"`; report OK/FAIL per line, then the day and per-project totals.

9. Return Trello card URL + Slack message link + Clockify confirmation (or "skipped").

## `--range-time` / `--rt` flow (bulk backfill)

Use case: forgot to log time for a period. Scans your Slack announcements for that range and batch-logs them to Clockify.

### Range parsing (step 1)

Parse the optional string after `--rt` / `--range-time`. If absent, default to `"this month"`.

| Input | `oldest` | `latest` |
|---|---|---|
| _(none)_ / `"this month"` | First second of current month (UTC) | Now |
| `"this week"` | Last Monday 00:00:00 UTC | Now |
| `"last week"` | Monday of previous week 00:00:00 UTC | Last Sunday 23:59:59 UTC |
| `"last two weeks"` / `"last 2 weeks"` | 14 days ago 00:00:00 UTC | Now |
| `"last N weeks"` / `"last N days"` | N×7 days ago (or N days ago) 00:00:00 UTC | Now |
| `"last month"` | First second of previous calendar month UTC | Last second of previous calendar month UTC |
| `"YYYY-MM-DD to YYYY-MM-DD"` | Given start date 00:00:00 UTC | Given end date 23:59:59 UTC |

Compute timestamps via Bash `date` commands. Always confirm the resolved range to the user before fetching: `"Scanning: 2026-05-01 → 2026-05-24"`.

1. **Compute range** — parse range string → compute `oldest` + `latest` UTC Unix timestamps via Bash. Print resolved date range for confirmation.

2. **Fetch all #tech-team messages** — read channel `C0AQJNTL6CT` with `oldest` set, paginate with cursor until all pages exhausted. Collect only top-level messages from `Mohammed Elzanaty` (user ID `U070VS8BHGV`) that look like work announcements. A message qualifies if it has ANY of: a Trello link (trello.com), a bold title (`*text*`), or a work emoji at the start (`:rocket:`, `:white_check_mark:`, `:tools:`, `:shield:`, `:ladybug:`). Skip purely casual messages (no work markers, no Trello link, Arabic chat, @-mentions with no deliverable). If a single message contains multiple separate bug/task entries each with their own Trello link, split them into individual items.

3. **Present numbered list** — show each item as:
   `#N [YYYY-MM-DD] <title> — <auto-detected project name>`
   Example:
   ```
   #1  [2026-05-22] feat(referral): Wallet Withdraw Modal — web.partner → Project: web.partner
   #2  [2026-05-21] feat(design-review): customer app design review → Project: web.admin
   ...
   ```

4. **Ask for durations in one shot**:
   `"Enter durations for each item (comma-separated, same order). Use 'skip' to skip an item. Example: 2h, 1.5h, skip, 3h"`

5. **Log each non-skipped item to Clockify** — for each item with a duration:
   - Detect `projectId` from title/content using project detection rules.
   - Use the message's actual date for `start` (set time to 09:00:00 UTC). Compute `end` = `start` + duration.
   - POST time entry via Bash (same curl as normal flow, always `"billable":true`).
   - Collect results.

6. **Report summary**:
   ```
   Logged N entries to Clockify:
   ✓ [2026-05-22] feat(referral)... — 2h → web.partner
   ✓ [2026-05-21] feat(design-review)... — 1.5h → web.admin
   - [2026-05-19] ... — skipped
   ```

## Rules

- Use `thread_ts` for all replies (steps 5–7).
- Do not post if no PRs or deliverables — ask what to announce instead.
- Screenshots go in the **main** message, never buried in the thread — that link is the first thing anyone opens.
- ghobashy is always CC'd. Never look up Trello/Slack IDs.
- `--rt` never posts to Slack or Trello — read-only on those systems.
