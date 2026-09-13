# Research Intake — Dual User Tracking
**Updated:** 2026-09-13 17:35 CST

---

## AUTHORIZED USERS

| ID | Name | Role | Status |
|---|---|---|---|
| **6787170323** | José | Owner + Admin | ✅ Active |
| **6247704701** | Laura | Collaborator | ✅ Active |

---

## TRACKING SYSTEM

Every intake item includes:
```yaml
userId: "6787170323" or "6247704701"
userName: "José" or "Laura"
timestamp: "2026-09-13T17:35:00"
```

Filenames automatically tagged:
```
2026-09-13_173500-[José]-tiktok-video.md
2026-09-13_173510-[Laura]-instagram-post.md
```

---

## INTAKE WORKFLOWS

### José or Laura sends LINK:
```
📨 Receives: https://github.com/...
🔄 Workflow: Classify → Analyze → Archive (HEADLESS)
💾 Saved: REPO/GPU-CUDA/2026-09-13_173500-[José]-nvidia-cuda.md
📝 Indexed: Intake-Log.md shows [José] as contributor
```

### José or Laura sends QUESTION:
```
📨 Receives: "Find a sushi restaurant in Polanco"
🔄 Workflow: Search → Analyze → Respond in Telegram
💬 Response: Sent directly to chat
💾 Logged: Research-Intake/Queries/[user]/question-log.md
```

---

## INDEX TRACKING

All three indices now track contributor:

**Intake-Log.md:**
```
### 2026-09-13 17:35 — SOCIAL: Instagram Post [Laura]
- **Link:** [url]
- **Contributor:** Laura
```

**Relevance-Index.md:**
```
| 2026-09-13_173510 — Instagram [Laura] | Social-Media | Pending | ARCHIVED |
```

**Category-Index.md:**
```
### Instagram
- [2026-09-13 17:35 — Post (Laura)]
```

---

## BENEFITS

✅ Full audit trail (who uploaded what)
✅ Collaborative research base
✅ Easy to trace items back to source
✅ Both users see indexed items
✅ Preferences: Each user can have custom tags/notes

---

## READY FOR LAURA

Laura can now:
1. Send links to Research Intake bot
2. Ask questions (search + respond)
3. See her contributions tracked + indexed
4. Access shared vault

---
