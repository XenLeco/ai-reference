---
name: incident-postmortem
description: Write a blameless incident postmortem from a timeline, logs and chat transcripts - impact, timeline, root cause, contributing factors, what went well, action items with owners. Use after an outage, a security incident, a bad deploy, or when asked for a post-incident review or RCA.
license: MIT
metadata:
  version: "1.0"
---

# Incident postmortem

Blameless: the question is why the system let this happen, never who did it. Facts with
timestamps; conclusions separated from facts; every action item has an owner and a date.

## Inputs to gather

- Alert and ticket timestamps, deploy log, chat transcript, dashboards, the fix PR.
- Who was paged, when they acknowledged, when mitigation started and ended.
- What users saw (error rates, latency, wrong data, downtime) and for how long.

## Template

```
# <Title: what broke, in plain words> — <YYYY-MM-DD>

Severity: <S1..S4>   Duration: <detect → mitigate → resolve>   Owner: <name>

## Impact
<who was affected, how many, what they saw, any data or money consequences>

## Timeline (UTC)
- 10:02 deploy of <sha> starts
- 10:07 error rate on /orders rises to 8%
- 10:11 alert fires; <role> acknowledges
- 10:19 rollback started; 10:24 error rate normal
- 11:40 root cause identified

## Root cause
<the mechanism: the change, the condition, why the system did not stop it>

## Contributing factors
- <missing test / alert threshold / review gap / config drift / unclear ownership>

## What went well
- <fast rollback, good runbook, clear comms>

## What was hard
- <alert noise, missing dashboard, unclear owner>

## Action items
| Action | Owner | Due | Ticket |
|---|---|---|---|
| add a test for <condition> | | | |
| alert on <metric> at <threshold> | | | |
| runbook step for <situation> | | | |

## Lessons
<one or two sentences someone can remember>
```

## Rules

- Timeline entries are facts with sources; interpretations go in "Root cause" and
  "Contributing factors".
- One root cause mechanism; several contributing factors are normal.
- Action items are specific and testable ("add alert at 2% for 5 min", not "improve
  monitoring"). Fewer, owned items beat a long wish list.
- If AI-assisted changes were involved, say so factually (which tool, which review
  happened); it is a contributing factor like any other, not a headline.
- Security incidents: include what data could have been accessed, the containment
  steps, and notification obligations; keep details that would help an attacker out of
  the widely shared version.

## Do not

- Do not name individuals as causes; name roles and system gaps.
- Do not close the postmortem with open unowned actions.
- Do not write it before the incident is actually resolved.
