module Deontic.Civil.CaseStudySpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.Prescription ()

-- ═══════════════════════════════════════════════════════════
-- 사례 연구: 미성년자 소유 부동산의 무권대리 사기매매
--
-- 사실관계:
--   갑 (17세, 미성년자)은 토지 소유자이다.
--   을은 갑의 대리인이라 사칭하여 갑의 토지를 병에게 매도하였다.
--   을은 실제로 대리권이 없었고, 갑은 추인하지 않았다.
--   병은 13년 후에 이 사실을 알고 소송을 제기하였다.
--
-- 법적 쟁점:
--   1. 미성년자의 법률행위 (§5) — 법정대리인 동의 없음
--   2. 무권대리 (§130) — 대리권 없음, 추인 없음
--   3. 사기에 의한 의사표시 (§110) — 을의 사기
--   4. 소멸시효 (§162) — 13년 경과
--
-- 종합 판단: Void (소멸시효 완성이 가장 중한 판단)
-- ═══════════════════════════════════════════════════════════

spec :: Spec
spec = do
  describe "사례 연구: 미성년자 소유 부동산의 무권대리 사기매매" $ do
    let 갑   = PersonId "갑"
        을   = PersonId "을"
        병   = PersonId "병"
        actId = ActId "토지매매"

    -- ─── 쟁점 1: 미성년자의 법률행위 (§5) ───
    let minorJ = query (MinorAct 갑 actId)
                       (Set.fromList [IsMinor 갑])
                       -- 법정대리인 동의 없음

    it "쟁점1 §5: 미성년자 동의 없음 → Voidable" $ do
      verdict minorJ `shouldBe` Voidable

    -- ─── 쟁점 2: 무권대리 (§130) ───
    let agencyJ = query (UnauthAgencyAct 갑 을 actId)
                        Set.empty
                        -- 추인 없음, 표현대리 근거 없음

    it "쟁점2 §130: 무권대리, 추인 없음 → Pending" $ do
      verdict agencyJ `shouldBe` Pending

    -- ─── 쟁점 3: 사기에 의한 의사표시 (§110) ───
    let fraudJ = query (FraudAct 병 actId)
                       Set.empty
                       -- 을의 직접 사기 (제3자 사기 아님)

    it "쟁점3 §110: 사기 → Voidable" $ do
      verdict fraudJ `shouldBe` Voidable

    -- ─── 쟁점 4: 소멸시효 (§162) ───
    let prescJ = query (PrescriptionAct 병 actId)
                       (PrescriptionFacts
                         { pfElapsedDays = 13 * 365  -- 13년 경과
                         , pfPeriodDays = 10 * 365   -- 10년 소멸시효
                         , pfInterruptedAfter = Nothing
                         })

    it "쟁점4 §162: 13년 > 10년 → Void (소멸시효 완성)" $ do
      verdict prescJ `shouldBe` Void

    -- ─── 종합 판단 ───
    let allJudgments =
          [ SomeJudgment minorJ
          , SomeJudgment agencyJ
          , SomeJudgment fraudJ
          , SomeJudgment prescJ
          ]

    it "종합: Void (소멸시효가 가장 중한 판단)" $ do
      combineVerdicts allJudgments `shouldBe` Void

    -- ─── 만약 소멸시효 기간 내였다면? ───
    let prescJ' = query (PrescriptionAct 병 actId)
                        (PrescriptionFacts
                          { pfElapsedDays = 5 * 365
                          , pfPeriodDays = 10 * 365
                          , pfInterruptedAfter = Nothing
                          })
        allJudgments' =
          [ SomeJudgment minorJ
          , SomeJudgment agencyJ
          , SomeJudgment fraudJ
          , SomeJudgment prescJ'
          ]

    it "소멸시효 미완성 시: Pending (무권대리가 가장 중한 판단)" $ do
      combineVerdicts allJudgments' `shouldBe` Pending

    -- ─── 만약 추인까지 했다면? ───
    let agencyJ' = query (UnauthAgencyAct 갑 을 actId)
                         (Set.singleton Ratified)
        allJudgments'' =
          [ SomeJudgment minorJ
          , SomeJudgment agencyJ'
          , SomeJudgment fraudJ
          , SomeJudgment prescJ'
          ]

    it "추인 + 소멸시효 미완성: Voidable (취소 가능한 사유 잔존)" $ do
      combineVerdicts allJudgments'' `shouldBe` Voidable

    -- ─── 추론 과정 검증 ───
    it "각 쟁점의 추론 과정이 보존됨" $ do
      let totalSteps = concatMap someJudgmentSteps allJudgments
      -- minorJ: 1 step (base), agencyJ: 1 step (delegate×2 → base),
      -- fraudJ: 1 step (base), prescJ: 1 step (delegate → base)
      length totalSteps `shouldBe` 4

    it "소멸시효 완성 판단의 근거조문은 §162" $ do
      let steps = judgmentSteps prescJ
          lastStep = last steps
      articleNumber (stepArticle lastStep) `shouldBe` 162
