module ObjectDispatcherTests where

foo1 = fn'l "foo1"
  (curry'l @(U256 -> BOOL)
    \x -> dup2'l x
    \(x1, x2) -> case toAddr 0xdeadbeef of
      Just addr -> const'l true (addr <==@ x1 + x2)
  )

object :: YulObject
object = mkYulObject "ObjectDispatcherTests" ctor
  [ -- externalFn foo1
  ]
  where ctor = YulId
