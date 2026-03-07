## Pipeline Summary

```
  Recognized facts (natural language)
      │
      │  ← Human/LLM judgment (the only non-mechanical step)
      ▼
  Identity + Fact Translation (tables above)
      │
      │  ← Purely mechanical (evaluateAll + renderJudgment)
      ▼
  Framework output (right column above)
      │
      │  ← LLM subagent (fixed directive, zero context)
      ▼
  Match verification (match.yaml)
```
