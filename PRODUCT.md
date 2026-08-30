# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Solo user (the developer themselves) — someone practicing personal development who wants to track habits across life domains and feel real, earned progress over time. Used daily, alone, on an iPhone, in private moments (morning, evening, between tasks).

## Product Purpose

Levelia is a personal habit tracker that makes self-improvement feel earned rather than arbitrary. Daily habits feed a persistent XP and leveling system segmented by life domain (sport, learning, wellbeing, etc.), turning consistent behavior into visible, long-term progression. Success means opening the app daily and feeling the pull to keep a streak alive.

## Positioning

The XP and leveling system is per-domain and global — you don't just check off boxes, you build a character across life areas. Progress is cumulative, cross-referenced, and never resets from inactivity alone.

## Operating Context

- Opened 1–2 times daily (morning checklist, evening review)
- Used alone, on an iPhone, in a quiet moment
- App in French
- The loop: check off habits → see XP gained → glance at level progress → feel momentum

## Capabilities and Constraints

- Habits with schedule (daily, weekly, custom), difficulty (XP weight), and penalty on miss
- Categories (life domains) with emoji, color, and their own XP/level track
- Goals with sub-tasks
- Weekly day-picker strip, streak tracking
- Stats screen with charts
- Profile screen showing global level + per-category levels
- Local data only (JSON), no cloud sync
- Flutter app, Cupertino (Apple) widgets throughout, dark + light mode
- Adaptive layout: CupertinoTabBar on iPhone, sidebar on iPad and Mac

## Brand Commitments

- App name: Levelia
- Language: French throughout
- No cloud, no social features — "tes données restent sur cet appareil"

## Evidence on Hand

- Full Flutter codebase in c:\dev
- Theme: steel-blue accent #3A8FD1, dark-first, Cupertino chrome, 12px card radius
- Existing gamification: XP bars, level medallion, streak pills, XP feedback on habit completion

## Product Principles

1. Progress is earned, never given — every XP point represents real behavior
2. Calm consistency over excitement — the app should feel settled, not anxious
3. Data belongs to the user — private, local, portable
4. Domains make growth legible — splitting life into areas makes broad progress visible
5. The level system rewards long arcs — not just today, but months of compound effort
