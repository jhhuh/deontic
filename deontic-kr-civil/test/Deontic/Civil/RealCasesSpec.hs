module Deontic.Civil.RealCasesSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.Possession ()
import Deontic.Civil.Prescription ()
import Deontic.Civil.CoOwnership ()
import Deontic.Civil.Tort ()

-- ═══════════════════════════════════════════════════════════
-- 실제 판례 기반 사례 연구
--
-- 대법원 판례에서 확립된 법리를 기반으로 한 사실관계를 모델링.
-- 각 사례는 실제 판례 번호와 핵심 법리를 주석으로 기재.
-- ═══════════════════════════════════════════════════════════

spec :: Spec
spec = do

  -- ─────────────────────────────────────────────
  -- §5 미성년자의 법률행위
  -- ─────────────────────────────────────────────
  describe "§5 미성년자 — 판례 기반" $ do
    let 미성년자 = PersonId "미성년자"
        actId   = ActId "신용구매"

    -- 대법원 2005다71659: 미성년자가 법정대리인 동의 없이
    -- 신용구매계약을 체결한 경우, 법정대리인이 이를 취소할 수 있다.
    -- 미성년자 보호가 거래의 안전보다 우선한다.
    it "신용구매계약 — 동의 없음 → Voidable (대법원 2005다71659)" $ do
      let j = query (MinorAct 미성년자 actId) (Set.singleton (IsMinor 미성년자))
      verdict j `shouldBe` Voidable

    -- 묵시적 동의도 유효 (대법원 2005다71659 법리)
    -- "법정대리인의 동의는 명시적이어야 하는 것은 아니고 묵시적으로도 가능"
    it "묵시적 동의 있는 경우 → Valid (묵시적 동의 인정)" $ do
      let j = query (MinorAct 미성년자 actId)
                (Set.fromList [ IsMinor 미성년자
                              , HasConsent (PersonId "부모") actId ])
      verdict j `shouldBe` Valid

    -- §5① 단서: 권리만 얻는 행위 (증여 수령)
    -- 대법원 법리: 채무 부담 없이 순수하게 권리만 취득하는 행위
    it "증여 수령 → Valid (권리만을 얻는 행위)" $ do
      let giftId = ActId "증여수령"
          j = query (MinorAct 미성년자 giftId)
                (Set.fromList [IsMinor 미성년자, MerelyAcquiresRight])
      verdict j `shouldBe` Valid

    -- 부동산 매매계약: 의무를 부담하므로 단서 적용 불가
    it "부동산 매매 — 동의 없음 → Voidable" $ do
      let saleId = ActId "부동산매매"
          j = query (MinorAct 미성년자 saleId)
                (Set.singleton (IsMinor 미성년자))
      verdict j `shouldBe` Voidable

  -- ─────────────────────────────────────────────
  -- §103 반사회질서의 법률행위
  -- ─────────────────────────────────────────────
  describe "§103 반사회질서 — 판례 기반" $ do
    let 표의자 = PersonId "표의자"
        actId  = ActId "계약"

    -- 대법원: 보험금 부정취득 목적 보험계약 → 무효
    -- "다수의 보험계약을 통하여 보험금을 부정취득할 목적으로
    --  체결한 보험계약은 반사회질서 법률행위로 무효"
    it "보험금 부정취득 목적 보험계약 → Void" $ do
      let j = query (JuristicAct 표의자 (ActId "보험계약"))
                (Set.singleton ContraBonorsMores)
      verdict j `shouldBe` Void

    -- 대법원: 형사사건 성공보수약정 → 무효
    -- "수사·재판의 결과를 금전적 대가와 결부시켜 변호사
    --  직무의 공공성을 저해하므로 반사회질서"
    it "형사사건 성공보수약정 → Void" $ do
      let j = query (JuristicAct 표의자 (ActId "성공보수약정"))
                (Set.singleton ContraBonorsMores)
      verdict j `shouldBe` Void

    -- §104 불공정한 법률행위
    -- 대법원: 궁박·경솔·무경험을 이용한 현저하게 불공정한 거래
    it "고리대금 — 궁박 이용 → Void (§104)" $ do
      let j = query (JuristicAct 표의자 (ActId "고리대금"))
                (Set.singleton ExploitativeAct)
      verdict j `shouldBe` Void

  -- ─────────────────────────────────────────────
  -- §107 비진의 의사표시
  -- ─────────────────────────────────────────────
  describe "§107 비진의 의사표시 — 판례 기반" $ do
    let 표의자 = PersonId "표의자"

    -- 대법원: 명의대여 — 상대방이 진의 아님을 모르면 유효
    -- (회사 명의를 빌려주는 경우)
    it "명의대여 — 상대방 선의 → Valid (§107①)" $ do
      let j = query (JuristicAct 표의자 (ActId "명의대여"))
                (Set.singleton HiddenIntention)
      verdict j `shouldBe` Valid

    -- 상대방이 명의대여 사실을 알고 있었던 경우
    it "명의대여 — 상대방 악의 → Void (§107②)" $ do
      let j = query (JuristicAct 표의자 (ActId "명의대여"))
                (Set.fromList [HiddenIntention, CounterpartyKnew])
      verdict j `shouldBe` Void

  -- ─────────────────────────────────────────────
  -- §108 통정허위표시
  -- ─────────────────────────────────────────────
  describe "§108 통정허위표시 — 판례 기반" $ do
    let 채무자 = PersonId "채무자"

    -- 대법원 94다12074:
    -- 채권자의 강제집행을 면탈하기 위해 부동산을 허위로 이전한 경우
    -- → 통정허위표시로 무효
    it "강제집행 면탈 목적 허위 명의이전 → Void (대법원 94다12074)" $ do
      let j = query (ShamAct 채무자 (ActId "허위명의이전")) Set.empty
      verdict j `shouldBe` Void

    -- 대법원 2019다280375: 통정허위표시와 선의의 제3자
    -- "제3자는 특별한 사정이 없는 한 선의로 추정되고,
    --  악의라는 사실의 입증책임은 무효를 주장하는 자에게 있다"
    -- 선의이면 족하고 무과실은 요건이 아님
    it "허위 명의이전 → 선의 제3자 보호 (§108②)" $ do
      let j = query (ShamAct 채무자 (ActId "허위명의이전"))
                (Set.singleton BonaFideThirdParty)
      verdict j `shouldBe` Valid

    -- 2인의 법률관계: 통정허위표시 당사자 사이에서는 무효
    it "당사자 사이에서는 무효" $ do
      let j = query (ShamAct 채무자 (ActId "가장매매")) Set.empty
      verdict j `shouldBe` Void

  -- ─────────────────────────────────────────────
  -- §109 착오에 의한 의사표시
  -- ─────────────────────────────────────────────
  describe "§109 착오 — 판례 기반" $ do
    let 매수인 = PersonId "매수인"

    -- 대법원 97다26210: 토지 면적의 착오
    -- "법률행위의 내용의 중요부분에 착오가 있는 때에는 취소할 수 있다"
    it "토지 면적 착오 → Voidable (대법원 97다26210)" $ do
      let j = query (MistakeAct 매수인 (ActId "토지매매")) Set.empty
      verdict j `shouldBe` Voidable

    -- 대법원 2013다49794: 표의자의 중대한 과실
    -- "표의자의 직업, 행위의 종류, 목적 등에 비추어 보통 요구되는
    --  주의를 현저히 결여한 것" → 취소 불가
    it "중과실로 인한 착오 → Valid (취소 불가, 대법원 2013다49794)" $ do
      let j = query (MistakeAct 매수인 (ActId "토지매매"))
                (Set.singleton GrossNegligence)
      verdict j `shouldBe` Valid

    -- 대법원 2017다227264: 표의자 중과실 + 상대방의 착오 이용
    -- 최근 법리: 상대방이 착오를 알고 이용한 경우,
    -- 표의자 중과실이 있더라도 취소 가능할 수 있음
    -- (현재 프레임워크에서는 이 법리 미반영 — 향후 확장 가능)

  -- ─────────────────────────────────────────────
  -- §110 사기·강박에 의한 의사표시
  -- ─────────────────────────────────────────────
  describe "§110 사기 — 판례 기반" $ do
    let 피해자 = PersonId "피해자"

    -- 부동산 하자 은닉에 의한 사기
    -- 매도인이 중대한 하자를 고의로 숨기고 매매한 경우
    it "부동산 하자 은닉 사기 → Voidable" $ do
      let j = query (FraudAct 피해자 (ActId "부동산매매")) Set.empty
      verdict j `shouldBe` Voidable

    -- 대법원 98다60828: 제3자에 의한 사기
    -- "상대방의 대리인 등 상대방과 동일시할 수 있는 자의 사기는
    --  제3자의 사기에 해당하지 아니한다"
    -- 제3자 사기 + 상대방 악의 → 취소 가능
    it "제3자 사기 + 상대방 악의 → Voidable (대법원 98다60828)" $ do
      let j = query (FraudAct 피해자 (ActId "매매계약"))
                (Set.fromList [ThirdPartyFraud, CounterpartyKnewFraud])
      verdict j `shouldBe` Voidable

    -- 제3자 사기 + 상대방 선의 → 취소 불가
    it "제3자 사기 + 상대방 선의 → Valid (취소 불가)" $ do
      let j = query (FraudAct 피해자 (ActId "매매계약"))
                (Set.singleton ThirdPartyFraud)
      verdict j `shouldBe` Valid

  -- ─────────────────────────────────────────────
  -- §125-126 표현대리
  -- ─────────────────────────────────────────────
  describe "§125-126 표현대리 — 판례 기반" $ do
    let 본인 = PersonId "본인"
        대리인 = PersonId "대리인"

    -- 대법원 91다32190: 기본대리권이 있어야 §126 성립
    -- "제126조의 표현대리가 성립하기 위해서는 적어도
    --  무권대리인에게 법률행위에 관한 기본대리권이 있어야 한다"
    it "기본대리권 있는 자의 권한초과 → Valid (표현대리, 대법원 91다32190)" $ do
      let j = query (UnauthAgencyAct 본인 대리인 (ActId "매매"))
                (Set.singleton ExceededScope)
      verdict j `shouldBe` Valid

    -- 대리권수여 표시 (§125)
    -- 대법원: 본인이 제3자에게 대리권 수여를 표시한 경우
    it "대리권수여 표시 → Valid (§125)" $ do
      let j = query (UnauthAgencyAct 본인 대리인 (ActId "계약"))
                (Set.singleton IndicatedAuthority)
      verdict j `shouldBe` Valid

    -- 대리권 소멸 후 (§129)
    it "대리권 소멸 후 선의 제3자 → Valid (§129)" $ do
      let j = query (UnauthAgencyAct 본인 대리인 (ActId "계약"))
                (Set.singleton AuthorityExpired)
      verdict j `shouldBe` Valid

    -- 순수 무권대리: 아무런 표현대리 근거 없음
    it "순수 무권대리 — 추인 없음 → Pending" $ do
      let j = query (UnauthAgencyAct 본인 대리인 (ActId "매매")) Set.empty
      verdict j `shouldBe` Pending

    -- 무권대리 후 추인 (§132)
    -- 대법원: "추인은 계약시에 소급하여 효력이 생긴다"
    it "무권대리 후 추인 → Valid (§132)" $ do
      let j = query (UnauthAgencyAct 본인 대리인 (ActId "매매"))
                (Set.singleton Ratified)
      verdict j `shouldBe` Valid

    -- 자기계약 (§118)
    it "자기계약 → Voidable (§118)" $ do
      let j = query (AuthAgencyAct 본인 대리인 (ActId "매매"))
                (Set.singleton SelfDealing)
      verdict j `shouldBe` Voidable

  -- ─────────────────────────────────────────────
  -- §162 소멸시효 + 시효중단
  -- ─────────────────────────────────────────────
  describe "§162 소멸시효 — 판례 기반" $ do
    let 채권자 = PersonId "채권자"

    -- 일반 채권: 10년 소멸시효 (§162①)
    it "대여금 채권 9년 경과 → Valid (시효 미완성)" $ do
      let j = query (PrescriptionAct 채권자 (ActId "대여금"))
                (PrescriptionFacts (9 * 365) (10 * 365) Nothing)
      verdict j `shouldBe` Valid

    it "대여금 채권 11년 경과 → Void (시효 완성)" $ do
      let j = query (PrescriptionAct 채권자 (ActId "대여금"))
                (PrescriptionFacts (11 * 365) (10 * 365) Nothing)
      verdict j `shouldBe` Void

    -- 단기소멸시효: 3년 (§163)
    -- 이자, 부양료, 급료, 봉급, 용역비 등
    it "용역비 채권 4년 경과 → Void (3년 단기시효 완성)" $ do
      let j = query (PrescriptionAct 채권자 (ActId "용역비"))
                (PrescriptionFacts (4 * 365) (3 * 365) Nothing)
      verdict j `shouldBe` Void

    -- 대법원 93다47745: 채무승인에 의한 시효중단
    -- "채무자가 일부 변제를 한 때에도 잔존 채무에 대하여
    --  승인을 한 것으로 보아 시효중단의 효력을 인정"
    it "11년 경과 but 8년차 채무승인 → Valid (시효중단, 대법원 93다47745)" $ do
      let j = query (PrescriptionAct 채권자 (ActId "대여금"))
                (PrescriptionFacts (11 * 365) (10 * 365) (Just (8 * 365)))
      verdict j `shouldBe` Valid

    -- 중단 후에도 새 시효기간 경과
    it "20년 경과, 8년차 중단 → Void (중단 후 12년 > 10년)" $ do
      let j = query (PrescriptionAct 채권자 (ActId "대여금"))
                (PrescriptionFacts (20 * 365) (10 * 365) (Just (8 * 365)))
      verdict j `shouldBe` Void

  -- ─────────────────────────────────────────────
  -- §197, §200 점유 추정
  -- ─────────────────────────────────────────────
  describe "§197, §200 점유 추정 — 판례 기반" $ do
    let 점유자 = PersonId "점유자"

    -- 대법원: 점유자는 선의, 평온, 공연으로 추정 (§197)
    -- "점유자의 점유가 자주점유인지는 점유 취득원인 사실에 의하여 판단"
    it "점유자 — 반증 없음 → Valid (선의 추정)" $ do
      let j = query (PossessionAct 점유자 (ActId "부동산점유")) Set.empty
      verdict j `shouldBe` Valid

    -- 악의 점유 반증
    it "악의 점유 반증 → Voidable" $ do
      let j = query (PossessionAct 점유자 (ActId "부동산점유"))
                (Set.singleton BadFaith)
      verdict j `shouldBe` Voidable

    -- 타주점유 반증 (§200)
    -- 대법원: "점유자가 소유자와의 관계에서 타주점유의 외형을 가진 경우"
    it "타주점유 반증 → Voidable (§200)" $ do
      let j = query (PossessionAct 점유자 (ActId "부동산점유"))
                (Set.singleton NoOwnershipIntent)
      verdict j `shouldBe` Voidable

  -- ─────────────────────────────────────────────
  -- §264 공유물의 처분
  -- ─────────────────────────────────────────────
  describe "§264 공유물 처분 — 판례 기반" $ do
    let 갑 = PersonId "갑"
        을 = PersonId "을"
        병 = PersonId "병"

    -- 대법원: 공유물의 처분·변경은 공유자 전원의 동의가 필요
    it "3인 공유 토지 — 전원 동의 → Valid" $ do
      let j = query (CoOwnershipAct (ActId "토지처분"))
                (CoOwnershipFacts [갑, 을, 병] (Set.fromList [갑, 을, 병]))
      verdict j `shouldBe` Valid

    it "3인 공유 토지 — 1인 미동의 → Void" $ do
      let j = query (CoOwnershipAct (ActId "토지처분"))
                (CoOwnershipFacts [갑, 을, 병] (Set.fromList [갑, 을]))
      verdict j `shouldBe` Void

    -- 2인 공유 부동산 매각
    it "부부 공유 아파트 — 1인만 동의 → Void" $ do
      let 남편 = PersonId "남편"
          아내 = PersonId "아내"
          j = query (CoOwnershipAct (ActId "아파트매각"))
                (CoOwnershipFacts [남편, 아내] (Set.singleton 남편))
      verdict j `shouldBe` Void

  -- ─────────────────────────────────────────────
  -- §750 불법행위
  -- ─────────────────────────────────────────────
  describe "§750 불법행위 — 판례 기반" $ do
    let 피해자 = PersonId "피해자"
        가해자 = PersonId "가해자"

    -- 교통사고: 4요건 모두 충족
    it "교통사고 — 전 요건 충족 → Void (배상책임)" $ do
      let j = query (TortAct 피해자 가해자 (ActId "교통사고"))
                (TortFacts True True True True False)
      verdict j `shouldBe` Void

    -- 교통사고: 피해자 과실 있음 → 과실상계
    -- 대법원: "사고 발생에 피해자의 과실이 경합한 경우 과실상계"
    it "교통사고 — 피해자 과실 → Voidable (과실상계, §396)" $ do
      let j = query (TortAct 피해자 가해자 (ActId "교통사고"))
                (TortFacts True True True True True)
      verdict j `shouldBe` Voidable

    -- 의료과오: 과실은 있으나 인과관계 불명
    it "의료과오 — 인과관계 불명 → Valid (책임 없음)" $ do
      let j = query (TortAct 피해자 (PersonId "의사") (ActId "의료과오"))
                (TortFacts True True True False False)
      verdict j `shouldBe` Valid

    -- 명예훼손: 위법성 조각 (진실한 공적 사안의 보도)
    it "명예훼손 — 위법성 조각 → Valid" $ do
      let j = query (TortAct 피해자 (PersonId "언론사") (ActId "보도"))
                (TortFacts True False True True False)
      verdict j `shouldBe` Valid

  -- ─────────────────────────────────────────────
  -- 복합 사례: 다수의 법적 쟁점 결합
  -- ─────────────────────────────────────────────
  describe "복합 사례 — 다수 쟁점 결합" $ do

    -- 사례 1: 미성년자의 사기 매매 + 시효 미완성
    -- 갑(17세)이 을에게 사기를 당해 부동산 매매 (3년 후 소송)
    it "미성년자 사기 피해 + 시효 미완성 → Voidable" $ do
      let 갑 = PersonId "갑"
          js = [ SomeJudgment $ query (MinorAct 갑 (ActId "매매"))
                   (Set.singleton (IsMinor 갑))
               , SomeJudgment $ query (FraudAct 갑 (ActId "매매"))
                   Set.empty
               , SomeJudgment $ query (PrescriptionAct 갑 (ActId "매매"))
                   (PrescriptionFacts (3 * 365) (10 * 365) Nothing)
               ]
      combineVerdicts js `shouldBe` Voidable

    -- 사례 2: 무권대리 + 반사회질서
    -- 무권대리인이 본인 명의로 도박채무 담보 설정
    it "무권대리 도박채무 담보 → Void (반사회질서가 지배)" $ do
      let 본인 = PersonId "본인"
          대리인 = PersonId "대리인"
          js = [ SomeJudgment $ query (UnauthAgencyAct 본인 대리인 (ActId "담보설정"))
                   Set.empty
               , SomeJudgment $ query (JuristicAct 본인 (ActId "담보설정"))
                   (Set.singleton ContraBonorsMores)
               ]
      combineVerdicts js `shouldBe` Void

    -- 사례 3: 통정허위표시 + 선의 제3자 + 소멸시효
    -- 허위 명의이전 후 선의 제3자가 취득, 10년 경과
    it "허위표시 + 선의 제3자 + 시효 미완성 → Valid" $ do
      let js = [ SomeJudgment $ query (ShamAct (PersonId "원소유자") (ActId "명의이전"))
                   (Set.singleton BonaFideThirdParty)
               , SomeJudgment $ query (PrescriptionAct (PersonId "원소유자") (ActId "명의이전"))
                   (PrescriptionFacts (5 * 365) (10 * 365) Nothing)
               ]
      combineVerdicts js `shouldBe` Valid

    -- 사례 4: 착오 + 표현대리
    -- 대리인이 권한을 넘어 계약, 본인이 착오 주장
    it "표현대리 + 착오 → Voidable (착오 취소 가능)" $ do
      let js = [ SomeJudgment $ query (UnauthAgencyAct (PersonId "본인")
                   (PersonId "대리인") (ActId "계약"))
                   (Set.singleton ExceededScope)  -- 표현대리 Valid
               , SomeJudgment $ query (MistakeAct (PersonId "본인") (ActId "계약"))
                   Set.empty  -- 착오 Voidable
               ]
      combineVerdicts js `shouldBe` Voidable

    -- 사례 5: 교통사고 + 소멸시효 완성
    -- 사고 후 12년 경과
    it "교통사고 배상청구 + 시효 완성 → Void" $ do
      let js = [ SomeJudgment $ query (TortAct (PersonId "피해자")
                   (PersonId "가해자") (ActId "사고"))
                   (TortFacts True True True True False)
               , SomeJudgment $ query (PrescriptionAct (PersonId "피해자") (ActId "사고"))
                   (PrescriptionFacts (12 * 365) (10 * 365) Nothing)
               ]
      combineVerdicts js `shouldBe` Void

    -- 사례 6: 공유물 처분 + 미성년 공유자
    -- 3인 공유인데 1인이 미성년자, 미성년자의 법정대리인 동의 없음
    it "공유물 처분 + 미성년 공유자 동의 없음 → Void (전원 동의 불충족)" $ do
      let 갑 = PersonId "갑"
          을 = PersonId "을"
          병 = PersonId "병(미성년)"
          -- 공유자 전원 동의 확인: 병의 동의 없음 → Void
          j = query (CoOwnershipAct (ActId "토지처분"))
                (CoOwnershipFacts [갑, 을, 병] (Set.fromList [갑, 을]))
      verdict j `shouldBe` Void

    -- 사례 7: 점유자가 불법행위로 점유 취득 + 악의
    it "불법 점유 + 악의 → Voidable" $ do
      let js = [ SomeJudgment $ query (PossessionAct (PersonId "점유자") (ActId "점유"))
                   (Set.singleton BadFaith)
               ]
      combineVerdicts js `shouldBe` Voidable
