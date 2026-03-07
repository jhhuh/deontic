{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.Render
  ( KoreanRenderer(..)
  , OutputFormat(..)
  , Block(..)
  , Inline(..)
  , renderBlocks
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Deontic.Core.Types (ArticleRef(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate (Judgment(..))
import Deontic.Render

data OutputFormat = PlainText | Markdown
  deriving (Eq, Show)

-- | Inline text elements.
data Inline
  = Plain Text       -- ^ Unformatted text
  | Italic Inline    -- ^ Italic (emphasis)
  | Bold Inline      -- ^ Bold (strong emphasis)
  | Code Text        -- ^ Inline code
  | Seq [Inline]     -- ^ Sequence of inlines
  deriving (Eq, Show)

-- | Block-level document elements.
data Block
  = Heading Int Inline  -- ^ Heading with level (e.g. 4 → ####)
  | Para Inline         -- ^ Paragraph
  | Blank               -- ^ Empty line
  deriving (Eq, Show)

-- | Render blocks to text in the given output format.
renderBlocks :: OutputFormat -> [Block] -> Text
renderBlocks fmt = T.intercalate "\n" . concatMap (renderBlock fmt)
  where
    renderBlock PlainText (Heading _ i) = [renderInline PlainText i <> ":"]
    renderBlock Markdown  (Heading n i) = [T.replicate n "#" <> " " <> renderInline Markdown i]
    renderBlock f         (Para i)      = [renderInline f i]
    renderBlock _         Blank         = [""]

-- | Render inline elements to text.
renderInline :: OutputFormat -> Inline -> Text
renderInline _         (Plain t)  = t
renderInline PlainText (Italic i) = "\"" <> renderInline PlainText i <> "\""
renderInline Markdown  (Italic i) = "*\"" <> renderInline Markdown i <> "\"*"
renderInline PlainText (Bold i)   = renderInline PlainText i
renderInline Markdown  (Bold i)   = "**" <> renderInline Markdown i <> "**"
renderInline _         (Code t)   = "`" <> t <> "`"
renderInline fmt       (Seq is)   = T.concat (map (renderInline fmt) is)

-- | Smart constructors
plain :: Text -> Inline
plain = Plain

italic :: Text -> Inline
italic = Italic . Plain

data KoreanRenderer = KoreanRenderer
  { rendererFormat :: OutputFormat
  }

instance Renderer KoreanRenderer where
  renderJudgment r j =
    let fmt = rendererFormat r
    in renderBlocks fmt (judgmentBlocks j)

-- | Build structured blocks from a judgment.
judgmentBlocks :: Judgment layers -> [Block]
judgmentBlocks j =
  let steps = judgmentSteps j
      v = case steps of
            [] -> Valid
            _  -> stepVerdict (last steps)
  in [ Heading 4 (plain "판단")
     , Para (plain (verdictText v))
     , Blank
     ]
     ++ concatMap stepBlocks steps
     ++ [ Para (plain ("따라서, " <> verdictText v)) ]

stepBlocks :: Step -> [Block]
stepBlocks s =
  [ Heading 4 (plain (kindLabel (stepKind s)))
  , Para (plain (articleRefText (stepArticle s) <> kindSuffix (stepKind s)))
  , Para (Italic (plain (stepSourceText s)))
  , Blank
  ]

-- | Human-readable label for each step kind
kindLabel :: StepKind -> Text
kindLabel Applied    = "근거"
kindLabel Overridden = "번복"
kindLabel Delegated  = "검토"

-- | Suffix appended to article reference
kindSuffix :: StepKind -> Text
kindSuffix Applied    = "에 의하면,"
kindSuffix Overridden = "에 의하여,"
kindSuffix Delegated  = "을 검토하였으나 해당 없어,"

verdictText :: Verdict -> Text
verdictText Valid    = "본 법률행위는 유효하다."
verdictText Void     = "본 법률행위는 무효이다."
verdictText Voidable = "본 법률행위는 취소할 수 있다."
verdictText Pending  = "본 법률행위의 효력은 미정이다."

articleRefText :: ArticleRef -> Text
articleRefText ref =
  "민법 제" <> T.pack (show (articleNumber ref)) <> "조"
  <> maybe "" (\p -> " 제" <> T.pack (show p) <> "항") (articleParagraph ref)
