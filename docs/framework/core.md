# Core Architecture

## Basic Types

```haskell
-- | Identifies a legal person (natural or juristic)
newtype PersonId = PersonId Text

-- | Identifies a specific legal act
newtype ActId = ActId Text

-- | Identifies a thing/property
newtype ThingId = ThingId Text

-- | Reference to a statutory article
data ArticleRef = ArticleRef
  { articleStatute   :: Text       -- e.g., "민법", "BGB"
  , articleNumber    :: Int        -- e.g., 5, 750
  , articleParagraph :: Maybe Int  -- e.g., Just 1 for §5①
  }
```

These are jurisdiction-agnostic identifiers. A `PersonId` could be a Korean
민법 party or a German BGB Geschäftspartner.

## The Facts Type Family

```haskell
type family Facts act :: Type
```

This open type family maps each act type to its evidence structure.
Different acts can require completely different fact types:

```haskell
type instance Facts MinorAct       = Set CivilFact     -- boolean flags
type instance Facts PrescriptionAct = PrescriptionFacts  -- temporal record
type instance Facts CoOwnershipAct  = CoOwnershipFacts   -- owner list + consent set
```

See [Facts Type Family](facts.md) for the full design.

## The Adjudicate Typeclass

```haskell
class Adjudicate act (layers :: [Type]) where
  adjudicate :: act -> Facts act -> Judgment layers
```

This is the core typeclass. The `layers` parameter is a type-level list
that determines which override layers are consulted and in what order.

## The Query Function

```haskell
query :: forall act.
         Adjudicate act (Resolvable act)
      => act -> Facts act -> Judgment (Resolvable act)
query = adjudicate @act @(Resolvable act)
```

`query` is the user-facing entry point. It connects the `Resolvable` type
family (which determines the layer stack for an act type) with the
`Adjudicate` typeclass (which performs the resolution).

The constraint `Adjudicate act (Resolvable act)` is checked at compile
time. If any layer in the stack lacks an instance, you get a type error —
this is the "법의 흠결" (lacuna) detection.

## Existential Wrapper

```haskell
data SomeJudgment where
  SomeJudgment :: Judgment layers -> SomeJudgment
```

`SomeJudgment` hides the `layers` type parameter, allowing heterogeneous
collections of judgments. Used by `combineVerdicts` to combine independent
legal issues:

```haskell
combineVerdicts :: [SomeJudgment] -> Verdict
combineVerdicts = foldl' verdictMeet Valid . map (\(SomeJudgment j) -> verdict j)
```
