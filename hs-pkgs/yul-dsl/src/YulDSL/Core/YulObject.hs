module YulDSL.Core.YulObject where

import           Data.List                                  (intercalate)
-- eth-abi
import           Ethereum.ContractABI.ABITypeable           (abiTypeCanonName)
-- import Ethereum.ContractABI.CoreType.NP
import           Ethereum.ContractABI.ExtendedType.SELECTOR (SELECTOR, mkTypedSelector)
--
import           YulDSL.Core.YulCat


-- | Effect type for the external function call.
data FuncEffect = FuncTx | FuncStatic

data Fn a b where
  MkFn :: forall as b. YulO2 as b => { fnId :: String, fnCat :: YulCat as b } -> Fn as b


data AnyFn = forall a b. YulO2 a b => MkAnyFn (Fn a b)

instance YulO2 a b => Show (Fn a b) where show (MkFn _ cat) = show cat

data ScopedFn where
  ExternalFn :: forall a b. YulO2 a b => FuncEffect -> SELECTOR -> Fn a b -> ScopedFn
  LibraryFn  :: forall a b. YulO2 a b => Fn a b -> ScopedFn

externalFn :: forall a b. YulO2 a b => Fn a b -> ScopedFn
externalFn fn = ExternalFn FuncTx (mkTypedSelector @a (fnId fn)) fn

staticFn :: forall a b. YulO2 a b => Fn a b -> ScopedFn
staticFn fn = ExternalFn FuncStatic (mkTypedSelector @a (fnId fn)) fn

libraryFn :: forall a b. YulO2 a b => Fn a b -> ScopedFn
libraryFn = LibraryFn

show_fn_spec :: forall a b. YulO2 a b => Fn a b -> String
show_fn_spec fn = "fn " <> fnId fn <> "(" <> abiTypeCanonName @a <> ") -> " <> abiTypeCanonName @b

instance Show ScopedFn where
  show (ExternalFn FuncTx _ fn)     = "external " <> show_fn_spec fn <> "\n" <> show (fnCat fn)
  show (ExternalFn FuncStatic _ fn) = "static "   <> show_fn_spec fn <> "\n" <> show (fnCat fn)
  show (LibraryFn fn)               = "internal " <> show_fn_spec fn <> "\n" <> show (fnCat fn)

removeScope :: ScopedFn -> AnyFn
removeScope (ExternalFn _ _ fn) = MkAnyFn fn
removeScope (LibraryFn fn)      = MkAnyFn fn

-- | A Yul Object per spec.
--
-- Note:
--   * Do not confuse this with YulObj which is an "object" in the category of YulCat.
--   * Specification: https://docs.soliditylang.org/en/latest/yul.html#specification-of-yul-object
data YulObject = MkYulObject { yulObjectName :: String
                             , yulObjectCtor :: YulCat () ()
                             , yulObjectSFns :: [ScopedFn] -- scoped functions
                             , yulSubObjects :: [YulObject]
                             -- , TODO support object data
                             }

instance Show YulObject where
  show o = "-- Functions:\n\n"
           <> intercalate "\n\n" (fmap show (yulObjectSFns  o))
           <> "\n\n-- Init code:\n\n"
           <> (show . yulObjectCtor) o

mkYulObject :: String
            -> YulCat () ()
            -> [ScopedFn]
            -> YulObject
mkYulObject name ctor afns = MkYulObject { yulObjectName = name
                                         , yulObjectCtor = ctor
                                         , yulObjectSFns = afns
                                         , yulSubObjects = []
                                         }
