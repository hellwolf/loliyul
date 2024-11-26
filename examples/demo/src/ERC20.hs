{-# OPTIONS_GHC -Wno-missing-signatures #-}

module ERC20 where

-- | ERC20 balance storage location for the account.
-- TODO should use hashing of course.
-- erc20_balance_storage :: forall r v. YulObj r => ADDR'L v r ⊸ ADDR'L v r
erc20_balance_storage account =
  mkUnit account
  & \(account, unit) -> coerce'l (coerce'l account + emb'l (fromInteger @U256 0x42) unit)

-- | ERC20 balance of the account.
erc20_balance_of = fn'l "balanceOf" $ uncurry'l @(ADDR -> U256)
  \account -> sget (erc20_balance_storage account)

-- | ERC20 transfer function (no negative balance check for simplicity).
-- erc20_transfer :: Fn (ADDR -> ADDR -> U256 -> BOOL)
erc20_transfer = fn'l "transfer" $ uncurry'l @(ADDR -> ADDR -> U256 -> BOOL)
    \from to amount -> const'l to from
  & \from -> use'l from (call'l erc20_balance_of)
  & \(from, balance) -> sput (erc20_balance_storage from) (balance - amount)
  -- (\amount -> passAp to erc20_balance_of & \(to, balance) ->
  --     sput (erc20_balance_storage to) (balance + amount)) &
  & emb'l true

object = mkYulObject "ERC20" emptyCtor
  [ externalFn erc20_balance_of
  , externalFn erc20_transfer
  ]
