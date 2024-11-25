{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE LinearTypes         #-}
{-# OPTIONS_GHC -Wno-orphans #-}

{-|

Copyright   : (c) 2024 Miao, ZhiCheng
License     : MIT

Maintainer  : zhicheng.miao@gmail.com
Stability   : experimental
Portability : GHC2024

= Description

Ethereum contract ABI compatible tuples encoded as n-ary products (NP).

-}
module Ethereum.ContractABI.CoreType.NP
  ( NP (Nil, (:*))
  , Multiplicity (Many, One)
  , LiftFunction
  , UncurryNP'Fst, UncurryNP'Snd, UncurryNP'Multiplicity, UncurryNP
  , CurryNP
  , CurryingNP'Head, CurryingNP'Tail
  , CurryingNP (curryingNP), UncurryingNP(uncurryingNP)
  , module Internal.Data.Type.List
  ) where

-- base
import           Data.Kind                        (Constraint, Type)
import           Data.List                        (intercalate)
import           GHC.Base                         (Multiplicity (..))
-- cereal
import qualified Data.Serialize                   as S
--
import           Internal.Data.Type.List
--
import           Ethereum.ContractABI.ABICodec
import           Ethereum.ContractABI.ABITypeable


{- * NP -}

-- | N-ary product with simplified than its homonym in the sop package.
data NP :: [Type] -> Type where
  Nil  :: NP '[]
  (:*) :: x -> NP xs -> NP (x : xs)
infixr 5 :*

-- | Existential wrapper of any 'NP' values.
data AnyNP (c :: Type -> Constraint) where
  MkAnyEmptyNP    :: forall c. AnyNP c
  MkAnyNonEmptyNP :: forall c x xs. (c x, c (NP xs)) => NP (x:xs) -> AnyNP c

{- * Type class instances -}

{- ** ABITypeable instances: NP xs -}

instance ABITypeable (NP '[]) where
  type instance ABITypeDerivedOf (NP '[]) = NP '[]
  abiTypeInfo = []

instance ( ABITypeable x, ABITypeable (NP xs)
         ) => ABITypeable (NP (x : xs)) where
  type instance ABITypeDerivedOf (NP (x : xs)) = NP (x : xs)
  abiTypeInfo = abiTypeInfo @x <> abiTypeInfo @(NP xs)

instance ABITypeCodec (NP '[]) where
  abiEncoder Nil = S.put ()
  abiDecoder = S.get @() >> pure Nil

instance ( ABITypeable x, ABITypeCodec x, ABITypeCodec (NP xs)
         ) => ABITypeCodec (NP (x : xs)) where
  abiEncoder (x :* xs) = do
    abiEncoder x
    abiEncoder xs
  abiDecoder = do
    x <- abiDecoder
    xs <- abiDecoder
    pure (x :* xs)

{- ** ABITypeable instances: (), (a, b) -}

-- | ABI typeable unit.
instance ABITypeable () where
  type instance ABITypeDerivedOf () = NP '[]
  abiToCoreType () = Nil
  abiFromCoreType Nil = ()

-- | ABI typeable tuple.
instance (ABITypeable a1, ABITypeable a2) => ABITypeable (a1, a2) where
  type instance ABITypeDerivedOf (a1, a2) = NP '[a1, a2]
  abiToCoreType (a1, a2) = a1 :* a2 :* Nil
  abiFromCoreType (a1 :* a2 :* Nil) = (a1, a2)

instance ABITypeCodec () where
  abiEncoder = S.put
  abiDecoder = S.get

instance ( ABITypeable a1, ABITypeable a2
         , ABITypeCodec a1, ABITypeCodec a2
         ) => ABITypeCodec (a1, a2) where
  abiEncoder (x1, x2) = do
    abiEncoder x1
    abiEncoder x2
  abiDecoder = do
    x1 <- abiDecoder
    x2 <- abiDecoder
    pure (x1, x2)

{- ** Show instances -}

instance Show (NP '[]) where
  show _ = "()"

instance (Show x, Show (NP xs)) => Show (NP (x : xs)) where
  show xs = "(" ++ intercalate "," (show_any_np (MkAnyNonEmptyNP xs)) ++ ")"

-- | Show a NP as a list of strings.
show_any_np :: AnyNP Show -> [String]
show_any_np MkAnyEmptyNP                 = []
show_any_np (MkAnyNonEmptyNP (x :* Nil)) = [show x]
show_any_np (MkAnyNonEmptyNP (x :* xs))  = [show x] <> show_any_np (MkAnyNonEmptyNP (xs :* Nil))

{- ** Type level functions for NP -}

-- | Lift a currying function type from its simplified form, denoted as @f@, into a new form.
--
--   This lifted function consists of a type function, @m@, for each argument, followed by a multiplicity arrow of @p@,
--   and uses a type function @mb@, for the result of the lifted function.
type family LiftFunction f (m  :: Type -> Type) (mb :: Type -> Type) (p :: Multiplicity) where
  LiftFunction  (x1 -> g) m mb p = m x1 %p-> LiftFunction g m mb p
  LiftFunction        (b) m mb _ = mb b

-- | Uncurry the arguments of a function to a list of types.
type family UncurryNP'Fst f :: [Type] where
  UncurryNP'Fst (x1 %_-> g) = x1 : UncurryNP'Fst (g)
  UncurryNP'Fst         (b) = '[]

-- | Uncurry the result of a function.
type family UncurryNP'Snd f  where
  UncurryNP'Snd (_ %_-> g) = UncurryNP'Snd (g)
  UncurryNP'Snd        (b) = b

-- | Uncurry and extract the multiplicity of the last arrow.
type family UncurryNP'Multiplicity f :: Multiplicity where
  UncurryNP'Multiplicity         (x1 %p-> b) = p
  UncurryNP'Multiplicity                 (b) = Many

-- | Uncurry a function to its NP form whose multiplicity of the last arrow is preserved.
type UncurryNP f = NP (UncurryNP'Fst f) %(UncurryNP'Multiplicity f)-> UncurryNP'Snd f

-- | Convert a function in ts NP form @np -> b@ to a curried function with multiplicity arrows in @p@.
--
--   Note: To add multiplicity-polymorphic arrows or to decorate arguments with additional type function, use
--   'LiftFunction'.
type family CurryNP np b where
  CurryNP (NP (x:xs)) b = x -> CurryNP (NP xs) b
  CurryNP (NP    '[]) b = b

-- | The type of the head of arguments of an currying function.
type family CurryingNP'Head f where
  CurryingNP'Head (a1 %_-> g) = a1
  CurryingNP'Head         (b) = ()

-- | The type of the tail of an currying function.
type family CurryingNP'Tail f where
  CurryingNP'Tail (a1 %p-> g) = CurryingNP'Tail g
  CurryingNP'Tail         (b) = b

-- | Uncurrying a function into a function of @NP xs@ to @b@.
class UncurryingNP f (xs :: [Type]) b
      (m1 :: Type -> Type) (m1b :: Type -> Type)
      (m2 :: Type -> Type) (m2b :: Type -> Type)
      (p :: Multiplicity) where
  uncurryingNP :: forall.
                  ( UncurryNP'Fst f ~ xs
                  , UncurryNP'Snd f ~ b
                  -- rewrite the second lift function into its one-arity form
                  , LiftFunction (NP xs -> b) m2 m2b p ~ (m2 (NP xs) %p-> m2b b)
                  ) => LiftFunction           f  m1 m1b p  -- ^ from this lifted function
                  %p-> LiftFunction (NP xs -> b) m2 m2b p  -- ^ to this lifted function

-- | Currying a function of @NP xs@ to @b@.
class CurryingNP (xs :: [Type]) b
      (m1 :: Type -> Type) (mb :: Type -> Type)
      (m2 :: Type -> Type)
      (p :: Multiplicity) where
  curryingNP :: forall f.
                ( CurryNP (NP xs) b ~ f
                -- rewrite the first lift function into its one-arity form
                , LiftFunction (NP xs -> b) m2 mb p ~ (m2 (NP xs) %p-> mb b)
                ) => LiftFunction (NP xs -> b) m2 mb p -- ^ from this lifted function
                %p-> LiftFunction           f  m1 mb p -- ^ to this lifted function
