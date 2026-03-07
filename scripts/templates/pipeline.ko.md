## 파이프라인(Pipeline) 요약

```
  인식된 사실관계 (자연어)
      │
      │  ← 사람/LLM 판단 (유일한 비기계적 단계)
      ▼
  신원 + 사실 변환 (위 표 참조)
      │
      │  ← 순수 기계적 처리 (evaluateAll + renderJudgment)
      ▼
  프레임워크 출력 (위 표의 오른쪽 열)
      │
      │  ← LLM 하위 에이전트(subagent) (고정 지시문, 컨텍스트 없음)
      ▼
  매칭 검증 (match.yaml)
```
