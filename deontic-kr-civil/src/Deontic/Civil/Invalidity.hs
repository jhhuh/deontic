module Deontic.Civil.Invalidity () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

type instance Resolvable PartialInvalidityAct = '[Conversion, HypotheticalIntent, Base]

-- §137 본문: 일부 무효이면 전부 무효
instance Adjudicate PartialInvalidityAct '[Base] where
  adjudicate _ facts
    | pifPartVoid facts =
        JBase Void
          (ArticleRef "민법" 137 Nothing)
          "법률행위의 일부분이 무효인 때에는 그 전부를 무효로 한다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 137 Nothing)
          "법률행위의 일부분이 무효가 아니므로 전부 유효하다."

-- §137 단서 + §139 단서
instance Adjudicate PartialInvalidityAct rest
      => Adjudicate PartialInvalidityAct (HypotheticalIntent ': rest) where
  adjudicate act facts
    | pifHypotheticalIntent facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 137 Nothing)
                  "그 무효부분이 없더라도 법률행위를 하였을 것이라고 인정되므로 나머지 부분은 유효하다."
    | pifRatifiedWithKnowledge facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 139 Nothing)
                  "당사자가 그 무효임을 알고 추인한 때에는 새로운 법률행위로 본다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- §138 무효행위의 전환
instance Adjudicate PartialInvalidityAct rest
      => Adjudicate PartialInvalidityAct (Conversion ': rest) where
  adjudicate act facts
    | pifMeetsOtherReqs facts
    , pifConversionIntent facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 138 Nothing)
                  "무효인 법률행위가 다른 법률행위의 요건을 구비하고 당사자가 그 무효를 알았더라면 다른 법률행위를 하는 것을 의욕하였으리라고 인정되므로 다른 법률행위로서 효력을 가진다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
