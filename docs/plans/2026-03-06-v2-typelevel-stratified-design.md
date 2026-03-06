# V2: Type-Level Stratified Deontic Semantics

## Goal

Same as V1: practical validity checker for Korean Civil Act (민법).
New approach: encode defeasible stratification in the type system via typeclass instances with context.

## Key Insight

The Haskell instance declaration mechanism IS the defeasibility mechanism:
- Base rule = instance with no Adjudicate context
- Override = instance with context requiring the lower layer
- Delegation = calling the lower layer's method
- Lacuna (법의 흠결) = no instance / TypeError for '[]
- GHC's instance resolver = defeasibility resolver
- Soundness = compile-time (no runtime defeat graph needed)

## Architecture

### Type-Level Layer Tokens

```haskell
data Base           -- 원칙 (general rule)
data Proviso        -- 단서 (proviso/exception within same article)
data SpecialRule    -- 특칙 (lex specialis from another article)
```

### Adjudicate Typeclass

```haskell
class Adjudicate act (layers :: [Type]) where
  adjudicate :: act -> Facts -> Judgment layers
```

Each instance is one stratum. Context enforces ordering:

```haskell
instance Adjudicate MinorAct '[Base] where ...

instance Adjudicate MinorAct '[Base]
      => Adjudicate MinorAct '[Proviso, Base] where ...

instance Adjudicate MinorAct '[Proviso, Base]
      => Adjudicate MinorAct '[SpecialRule, Proviso, Base] where ...
```

### Non-Resolution via '[]

```haskell
instance TypeError ('Text "법의 흠결: " ...)
      => Adjudicate act '[] where ...
```

### Judgment GADT

Judgment carries the full reasoning chain in its structure:

```haskell
data Judgment (layers :: [Type]) where
  JBase     :: Verdict -> ArticleRef -> Text
            -> Judgment '[Base]
  JOverride :: Judgment prev -> Verdict -> ArticleRef -> Text
            -> Judgment (l ': prev)
  JDelegate :: Judgment prev
            -> Judgment (l ': prev)
```

- JBase: direct rule application
- JOverride: this layer changed the verdict
- JDelegate: this layer was available but did not override

### Resolvable Type Family

```haskell
type family Resolvable act :: [Type]
type instance Resolvable MinorAct = '[SpecialRule, Proviso, Base]
```

### Query Interface

```haskell
query :: Adjudicate act (Resolvable act) => act -> Facts -> Judgment (Resolvable act)
query act facts = adjudicate act facts
```

### Rendering

Walk the Judgment GADT to produce Korean legal sentences:

```haskell
renderJudgment :: Judgment layers -> Text
-- Pattern match on JBase/JOverride/JDelegate to produce:
-- "민법 제5조 제1항에 의하면... 다만... 따라서..."
```

## Package Structure

### deontic-core

```
src/Deontic/
  Core/
    Types.hs       -- PersonId, ActId, ArticleRef, Fact, Facts (from V1)
    Verdict.hs     -- Verdict (Valid, Void, Voidable)
    Layer.hs       -- Layer tokens, Resolvable type family
    Adjudicate.hs  -- Adjudicate class, Judgment GADT, query
  Render.hs        -- Renderer class, generic Judgment rendering
```

### deontic-kr-civil

```
src/Deontic/Civil/
  Types.hs         -- MinorAct, JuristicAct, etc. (act data types)
  Persons.hs       -- Adjudicate instances for person-related acts (§5)
  Acts.hs          -- Adjudicate instances for juristic act validity (§103-§107)
  Render.hs        -- KoreanRenderer
```

## What Changes from V1

| V1 (runtime) | V2 (type-level) |
|---|---|
| `Rule` data type with `precondition :: Facts -> Bool` | Typeclass instances with pattern matching |
| `defeatedBy :: [ArticleRef]` | Instance context `=>` |
| `DefeatGraph` + `resolve` at runtime | GHC instance resolver at compile time |
| `LegalCode` typeclass + `query` | `Adjudicate` typeclass + `query` |
| Soundness: hoped for | Soundness: enforced by GHC |
| Lacuna: empty result list | Lacuna: type error |

## What Stays from V1

- flake.nix, cabal.project, .cabal files (adjusted module lists)
- Deontic.Core.Types (PersonId, ActId, ArticleRef, Fact, Facts)
- Korean source text in rules (now in instance bodies / Judgment values)
- KoreanRenderer concept (walks Judgment instead of ProofTree)
