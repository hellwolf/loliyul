{-|

Copyright   : (c) 2023 Miao, ZhiCheng
License     : LGPL-3
Maintainer  : zhicheng.miao@gmail.com
Stability   : experimental

= Description

This module provides a function 'evalYulDSL' simulating the evaluation of the 'YulDSL'.

-}

module YulDSL.Eval where

-- base
import           Data.Maybe           (fromJust)
-- containers
import qualified Data.Map             as M
-- eth-abi
import           Ethereum.ContractABI
--
import           YulDSL.Core.YulCat   (YulCat (..))


{-# ANN EvalState "HLint: ignore Use newtype instead of data" #-}
data EvalState = EvalState { store_map :: M.Map ADDR WORD
                           }
               deriving Show

initEvalState :: EvalState
initEvalState = EvalState { store_map = M.empty
                          }

evalYulDSL :: EvalState -> YulCat a b -> a -> (EvalState, b)
evalYulDSL s YulId             a  = (s, a)
-- evalYulDSL s YulCoerce         a  = (s, fromJust . abi_decode . abi_encode $ a)
evalYulDSL s (YulComp n m)     a  = (s'', c) where (s' , b) = evalYulDSL s  m a
                                                   (s'', c) = evalYulDSL s' n b
evalYulDSL s (YulProd m n) (a, b) = (s'', (c, d)) where (s',  c) = evalYulDSL s  m a
                                                        (s'', d) = evalYulDSL s' n b
evalYulDSL s  YulSwap      (a, b) = (s, (b, a))
evalYulDSL s  YulDis           _  = (s, ())
evalYulDSL s  YulDup           a  = (s, (a, a))
evalYulDSL s (YulEmbed b)      _  = (s, b)
evalYulDSL s  YulNumNeg       a   = (s, negate a)
evalYulDSL s  YulNumAdd    (a, b) = (s, a + b)
evalYulDSL s  YulSGet          r  = (s, fromJust (fromWord =<< M.lookup r (store_map s)))
evalYulDSL s  YulSPut      (r, a) = (s', ()) where s' = s { store_map = M.insert r (toWord a) (store_map s) }
evalYulDSL _ _ _ = error "evalYulDSL"
