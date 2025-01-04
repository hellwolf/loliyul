{-|

Copyright   : (c) 2024-2025 Miao, ZhiCheng
License     : LGPL-3

Maintainer  : hellwolf@yolc.dev
Stability   : experimental
Portability : GHC2024

= Description

The module provides a set of common combinators for working with linearly versioned monad.

These combinators should be reexported by the contextualized module of 'Control.LinearlyVersionedMonad.LVM'.

-}
module Control.LinearlyVersionedMonad.Combinators
  ( embed
  , tossToUnit, toss, tossN
  , pass, pass_, passN, passN_
  , with, with_,
  ) where
-- constraints
import Data.Constraint.Linear         (Dict (Dict))
--
import Control.LinearlyVersionedMonad
import Data.LinearContext
import Data.TupleN                    (ConvertibleTupleN, TupleNtoNP, fromTupleNtoNP)

--------------------------------------------------------------------------------
-- embed
--------------------------------------------------------------------------------

-- | Embed a value into the context of a LVM.
embed :: forall ctx m v a.
  (ContextualEmbeddable ctx m a)
  => a ⊸ LVM ctx v v (m a)
embed a = MkLVM \ctx -> let !(ctx', ma) = contextualEmbed ctx a in (Dict, ctx', ma)

--------------------------------------------------------------------------------
-- toss
--------------------------------------------------------------------------------

-- | Toss a single value into a context-free unit.
tossToUnit :: forall ctx v a.
  (ContextualConsumable ctx a)
  => a ⊸ LVM ctx v v ()
tossToUnit x = MkLVM \ctx -> (Dict, contextualConsume ctx x, ())

-- | Toss a single value into a contextual unit.
toss :: forall ctx v a m.
  (ContextualConsumable ctx a, ContextualEmbeddable ctx m ())
  => a ⊸ LVM ctx v v (m ())
toss x = MkLVM \ctx -> let ctx' = contextualConsume ctx x
                           !(ctx'', mu) = contextualEmbed ctx' ()
                       in (Dict, ctx'', mu)

-- | Toss a TupleN into a contextual unit.
tossN :: forall ctx v tpl m.
  ( ConvertibleTupleN tpl
  , ContextualConsumable ctx (TupleNtoNP tpl)
  , ContextualEmbeddable ctx m ()
  ) => tpl ⊸ LVM ctx v v (m ())
tossN tpl = MkLVM \ctx -> let ctx' = contextualConsume ctx (fromTupleNtoNP tpl)
                              !(ctx'', mu) = contextualEmbed ctx' ()
                          in (Dict, ctx'', mu)

--------------------------------------------------------------------------------
-- pass
--------------------------------------------------------------------------------

-- | Pass the copied data to the next process, then pass both the original data and the result to the next stage.
pass :: forall ctx va vb a b.
  (ContextualDupable ctx a)
  => a ⊸ (a ⊸ LVM ctx va vb b) ⊸ LVM ctx va vb (a, b)
pass a mb = MkLVM \ctx ->
  let !(ctx', (a1, a2)) = contextualDup ctx a
      !(alteb, ctx'', b) = unLVM (mb a1) ctx'
  in (alteb, ctx'', (a2, b))

-- | Pass the copied data to the next process, then pass the original data to the next stage and discard the restart.
pass_ :: forall ctx va vb a b.
  (ContextualDupable ctx a, ContextualConsumable ctx b)
  => a ⊸ (a ⊸ LVM ctx va vb b) ⊸ LVM ctx va vb a
pass_ a mb = MkLVM \ctx ->
  let !(ctx', (a1, a2)) = contextualDup ctx a
      !(alteb, ctx'', b) = unLVM (mb a1) ctx'
      ctx''' = contextualConsume ctx'' b
  in (alteb, ctx''', a2)

-- | Combinator 'pass' for TupleN.
passN :: forall ctx va vb tpl b.
  (ConvertibleTupleN tpl, ContextualDupable ctx (TupleNtoNP tpl))
  => tpl ⊸ (tpl ⊸ LVM ctx va vb b) ⊸ LVM ctx va vb (tpl, b)
passN tpl mb = MkLVM \ctx ->
  let !(ctx', (tpl1, tpl2)) = contextualDupTupleN ctx tpl
      !(alteb, ctx'', b) = unLVM (mb tpl1) ctx'
  in (alteb, ctx'', (tpl2, b))

-- | Combinator 'pass_' for TupleN.
passN_ :: forall ctx va vb tpl b.
  ( ConvertibleTupleN tpl, ContextualDupable ctx (TupleNtoNP tpl)
  , ContextualConsumable ctx b
  ) => tpl ⊸ (tpl ⊸ LVM ctx va vb b) ⊸ LVM ctx va vb tpl
passN_ tpl mb = passN tpl mb >>= (\(tpl', b) -> tossToUnit b >> pure tpl')

--------------------------------------------------------------------------------
-- with
--------------------------------------------------------------------------------

-- | Process input @a@ without creating a copy of it then return the result @b@.
with :: forall ctx va vb a b.
  a ⊸ (a ⊸ LVM ctx va vb b) ⊸ LVM ctx va vb b
with a mb = MkLVM \ctx ->
  let !(alteb, ctx', b) = unLVM (mb a) ctx
  in (alteb, ctx', b)

-- | Process input @a@ without creating a copy of it then discard the result @b@.
with_ :: forall ctx va vb a b.
  (ContextualConsumable ctx b)
  => a ⊸ (a ⊸ LVM ctx va vb b) ⊸ (LVM ctx va vb ())
with_ a mb = MkLVM \ctx ->
  let !(alteb, ctx', b) = unLVM (mb a) ctx
      ctx'' = contextualConsume ctx' b
  in (alteb, ctx'', ())
