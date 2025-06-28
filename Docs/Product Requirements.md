# Product Requirements Document (PRD)
**Product Name:** Fog & Fern  
**Prepared by:** Kyle Olivo  
**Last Updated:** 2025-06-20  
**Version:** 1.0  

---

## 1. Executive Summary

**Fog & Fern** is a mobile app designed to inspire and guide residents and visitors in San Francisco to explore the city's parks and green spaces. The app blends simple discovery tools, personal journaling, and soft gamification to drive recurring outdoor behavior rooted in mindfulness and local connection. The initial market is SF, but the system is designed to scale to any city.

---

## 2. Problem Statement

Although San Francisco has over 220 parks, most residents are unaware of the diversity available to them. Existing apps are overly technical, purely fitness-oriented, or lack emotional engagement. There’s a need for a tool that treats parks not just as destinations, but as spaces for personal experience.

---

## 3. Target Users

### Primary
- **Urban Explorers** — Local residents who love discovering their city’s hidden corners
- **Wellness Seekers** — Users looking for calm, grounded experiences in nature
- **Lightweight Naturalists** — People who want regular, simple contact with greenery

### Secondary
- **Tourists** — Visitors who want more than just the biggest parks
- **Parents & Educators** — Adults seeking quality time outside with children

---

## 4. Market Opportunity

### Total Addressable Market (TAM)
- 850K SF residents
- 3–5M tourists annually
- US-wide market: urban dwellers seeking lightweight nature interaction

### Competitive Landscape
| Product      | Gap Compared to Fog & Fern            |
|--------------|----------------------------------------|
| Google Maps  | No emotional or goal-driven features  |
| AllTrails    | Too fitness/hike-centric              |
| Apple Maps   | Limited content, no engagement loop   |
| Day One      | Great for journaling, no location tie |

---

## 5. Product Objectives

| Objective | Description |
|-----------|-------------|
| **Drive park engagement** | Users explore a broader range of parks |
| **Encourage habit formation** | Create light, repeatable use cases |
| **Enable reflection** | Build memory and attachment to place |
| **Reward discovery** | Deliver intrinsic motivation (badges, stats) |
| **Validate in SF, then scale** | Design for city modularity from the start |

---

## 6. Core Features

### Park Discovery
- Map + list of parks (with filters)
- “Suggested park” module
- Park detail pages

### Visit Logging
- Manual check-in (tap to log)
- Automatic check-in (GPS based)
- Add a short note
- Time + date stored locally

### Journaling
- Feed of past visits
- Tap to view/edit notes
- Optionally attach mood or photo (future)

### Goal Tracking
- Simple challenges (e.g., 5 parks in a month)
- Neighborhood-based goals
- Progress shown visually

### Badges
- Earned for behavioral milestones
- Badge gallery in profile
- Static in MVP, dynamic in later phases

### Profile Dashboard
- Summary of parks visited, goals completed, badges earned
- Weekly/monthly activity views (non-graphical)

---

## 7. Personas (Lite)

| Persona           | Behavior                         | Needs                       |
|------------------|----------------------------------|-----------------------------|
| “Lana the Local” | Walks every day, loves SF hills  | Wants suggestions, variety |
| “Quiet Tourist”  | Doesn’t want to do big attractions | Wants peaceful places, offline utility |
| “Mindful Parent” | Looking for weekend park ideas   | Needs trust + ease of use   |

---

## 8. Key User Journeys

### First Visit
1. Open app → See map and 2–3 nearby parks
2. Tap one → Read about it → Tap "Check In"
3. Add a quick note: “Sat on a bench with coffee”
4. View that log in Journal

### Repeat Use
1. Open app → See “Suggested goal” (e.g., 2 more parks in the Sunset)
2. See map pins → Choose a new one
3. Visit and log
4. Earn badge for “3 parks in a weekend”

---

## 9. Launch Plan (Expanded, Micro-Phased)

| Phase | Description | Outcome |
|-------|-------------|---------|
| **Phase 0 – Setup & Scaffolding** | Create Xcode project, app icon, SwiftData model stub, dummy views | App compiles, opens, and displays basic UI on device |
| **Phase 1 – Park List (Hardcoded)** | Scrollable list of ~5 parks (static JSON or in-code) | Users can see and tap park names |
| **Phase 2 – Park Detail & Check-In** | Detail view + check-in button + text entry | User logs a park visit |
| **Phase 3 – Visit History / Journal** | List of past visits with notes | Can view a personal log |
| **Phase 4 – Profile View + Static Goals** | Shows # of visits, static badges earned | Light gamification begins |
| **Phase 5 – Interactive Map** | SF map with tappable park pins → detail views | Geography-first discovery working |
| **Phase 6 – Goal Progress Tracking** | Track progress toward dynamic challenges | System responds to real activity |
| **Phase 7 – Visual Polish + Shareable Log** | Add icons, better spacing, markdown/share button for visit logs | MVP is visually coherent and useful |
| **Phase 8 – Feedback Round** | Light test with 5–10 users | Prioritize Phase 9 features |

---

## 10. Success Metrics

| Metric                     | Target      |
|----------------------------|-------------|
| D1 Retention               | ≥ 40%       |
| Avg. parks visited/user    | ≥ 5 in 30 days |
| Visit logging completion   | ≥ 60% of park opens |
| Goal participation         | ≥ 30% opt in |
| Badge unlock rate (1+)     | ≥ 50% within 7 days |

---

## 11. Risks & Assumptions

### Risks
- Users may not revisit after logging one park
- Low motivation without social or rewards
- Battery/privacy friction from location access

### Assumptions
- Park discovery is inherently rewarding
- SF data is solid enough for initial use
- Journaling is an appealing behavior

---

## 12. Non-Goals

- Complex routing
- Cross-user sharing / social feed
- Multi-city support in MVP
- Heavy data tracking or fitness analytics

---

## 13. Brand Positioning

- **Emotion:** Quiet, grounding, rewarding
- **Tone:** Calm, minimalist, thoughtful
- **Visual Style:** Clean lines, foggy gradients, subtle nature motifs

---

## 14. Appendix

- Product tagline (WIP): *"Wander. Log. Grow."*
- MVP completion goal: **within 48 hours**
- Internal goal: **New build every 2–3 days with visible value**
