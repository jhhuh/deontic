## 부록: 검증 방법론(Verification Methodology)

### 일치 검증 하위 에이전트(Match Verification Subagent)

각 사례는 LLM 하위 에이전트(subagent)가 프레임워크 출력과 실제 법원 판결을
비교하여 검증합니다. 하위 에이전트는 다음 제약 조건 하에서 동작합니다:

- **모델(Model)**: Claude (claude-opus-4-6 via Claude Code Agent tool)
- **제공되는 맥락(Context)**: 없음 — `fulltext.md`와 `framework-output.md`만 제공
- **지시문(Directive)**: [`scripts/directives/verify-match.md`](../../scripts/directives/verify-match.md)

하위 에이전트는 프로젝트 구조, Haskell 코드, 또는 다른 사례에 대한 사전 지식이
없습니다. 지정된 두 파일만 읽고 YAML 형식의 판정 결과를 출력합니다.

### 일치 기준(Match Criteria)

- **true**: 프레임워크의 최종 판단이 법원의 판시 사항과 본질적으로 일치함
- **partial**: 일부 쟁점에서는 일치하나 다른 쟁점에서는 불일치함
- **false**: 프레임워크의 결론이 법원의 결정과 모순됨
