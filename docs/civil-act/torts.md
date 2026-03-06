# 불법행위 Torts

**Module:** `Deontic.Civil.Tort`

## §750 불법행위의 내용

> 고의 또는 과실로 인한 위법행위로 타인에게 손해를 가한 자는
> 그 손해를 배상할 책임이 있다.

**Act type:** `TortAct` — **Layers:** `'[ContributoryNeg, Base]`

```haskell
data TortFacts = TortFacts
  { tfFault     :: Bool   -- 고의 또는 과실
  , tfUnlawful  :: Bool   -- 위법성
  , tfDamage    :: Bool   -- 손해 발생
  , tfCausation :: Bool   -- 인과관계
  , tfVictimNeg :: Bool   -- 피해자의 과실 (과실상계)
  }
```

## Multi-Element Requirement

§750 requires **all four elements** to be present for liability:

1. **고의 또는 과실** (fault) — intentional or negligent
2. **위법성** (unlawfulness) — the act violates legal norms
3. **손해** (damage) — actual harm occurred
4. **인과관계** (causation) — the act caused the harm

If any element is missing, the base verdict is `Valid` (no liability).
If all four are present, the verdict is `Void` (full liability).

```haskell
instance Adjudicate TortAct '[Base] where
  adjudicate _ facts
    | tfFault facts && tfUnlawful facts
      && tfDamage facts && tfCausation facts =
        JBase Void ...   -- all 4 elements → liability
    | otherwise =
        JBase Valid ...  -- missing element → no liability
```

## §763→§396 과실상계

> §763: 제396조의 규정은 불법행위로 인한 손해배상에 준용한다.
>
> §396: 채무불이행에 관하여 채권자에게 과실이 있는 때에는 법원은
> 손해배상의 책임 및 그 금액을 정함에 이를 참작하여야 한다.

The `ContributoryNeg` layer implements contributory negligence reduction:

```haskell
instance Adjudicate TortAct rest
      => Adjudicate TortAct (ContributoryNeg ': rest) where
  adjudicate act facts
    | tfVictimNeg facts                        -- victim had negligence
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =                   -- AND liability exists
        JOverride prev Voidable ...            -- reduce to Voidable
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

!!! important "Verdict-Conditional Override"
    The `ContributoryNeg` layer only fires when **both** conditions hold:

    1. The victim was negligent (`tfVictimNeg facts`)
    2. The base verdict is `Void` (liability established)

    If there's no liability to begin with (`Valid`), victim negligence is
    irrelevant — you can't reduce zero liability. This is the
    **verdict-conditional override** pattern, also used in §390 (creditor
    defense) and §580② (buyer knowledge).

## Reasoning Chain Example

For a traffic accident where the tortfeasor is liable but the victim
was also negligent:

```haskell
let facts = TortFacts True True True True True  -- all elements + victim neg
    j = query (TortAct victim tortfeasor actId) facts
```

The judgment structure:

```
JOverride                                    -- ContributoryNeg: victim neg
  (JBase Void (ArticleRef "민법" 750 ...) ...) -- Base: all 4 elements → Void
  Voidable
  (ArticleRef "민법" 396 ...)
  "피해자에게도 과실이 있으므로 과실상계에 의하여 손해배상 책임이 감경된다."
```

Steps:

1. `Applied` — §750: all elements present, verdict `Void`
2. `Overridden` — §396: victim negligence reduces to `Voidable`
