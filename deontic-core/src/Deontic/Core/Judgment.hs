module Deontic.Core.Judgment
  ( Judgment(..)
  , isValid, isVoid, isVoidable
  , citations
  , ProofTree(..)
  , rootArticle
  ) where

import Deontic.Core.Types (ArticleRef)

data Judgment
  = JValid    [ArticleRef]
  | JVoid     [ArticleRef]
  | JVoidable [ArticleRef]
  | JAmbiguous [(Judgment, [ArticleRef])]
  deriving (Eq, Show)

isValid :: Judgment -> Bool
isValid (JValid _) = True
isValid _          = False

isVoid :: Judgment -> Bool
isVoid (JVoid _) = True
isVoid _         = False

isVoidable :: Judgment -> Bool
isVoidable (JVoidable _) = True
isVoidable _             = False

citations :: Judgment -> [ArticleRef]
citations (JValid cs)     = cs
citations (JVoid cs)      = cs
citations (JVoidable cs)  = cs
citations (JAmbiguous js) = concatMap snd js

data ProofTree
  = Leaf ArticleRef
  | Defeated ArticleRef [ArticleRef]
  | Derived ArticleRef [ProofTree]
  deriving (Eq, Show)

rootArticle :: ProofTree -> ArticleRef
rootArticle (Leaf a)       = a
rootArticle (Defeated a _) = a
rootArticle (Derived a _)  = a
