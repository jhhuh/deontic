# 판례 시연: 프레임워크(Framework) vs 법원

각 판례는 세 부분으로 구성됩니다:

1. **식별** — 당사자와 행위를 Haskell 값(value)으로 대응
2. **사실 변환** — 판례 사실관계를 프레임워크 인코딩(encoding)으로 대응
3. **판단 비교** — 실제 법원 판시사항 vs 프레임워크 출력

`python3 scripts/generate-cases.py` 실행 후 `python3 scripts/assemble-cases.py`로 생성됩니다.
프레임워크 출력은 **순수하게 기계적**입니다 — 사실관계가 대응되면, 인간의 판단은 개입하지 않습니다.

---
