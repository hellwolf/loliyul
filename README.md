Yolc - A Safe, Expressive, Fun Language for Ethereum
====================================================

The main motivation behind Yolc is strike a balance between these values for building Ethereum smart contracts:

*Safe*

Yolc is purely functional with linear type safety, made for the Ethereum virtual machine.

> What does *purely functional linear type safety/ mean here? Read more [here](#).

*Expressive*

YulDSL provides an EDSL called 'YulDSL' for transpiling Haskell code to Solidiy/Yul code.

> Why does /expressiveness/ matter? Read more [here](#).

*Fun*

Yolc allows you to write safe code in production, a joyful experience for super coders.

> Find more some [examples code here](#).

> [!CAUTION]
>
> 🚧 While this project is still work in progress 🚧, the good news is after pausing for the good part of 2024 due to
> business reason, I am back to it. As of 2024 October, the end-to-end is working and I have adjusted the roadmap and
> planned an exciting type system for the first release!
>
> Contact me at info@yolc.dev if you are interested in testing this project out soon!

> [!TIP]
>
> Yolc is a compiler program for "YulDSL/Haskell". YulDSL is a domain-specific language (DSL) based on [category
> theory](https://ncatlab.org/nlab/show/category+theory) for [Solidity/Yul](https://soliditylang.org/). YulDSL can be
> embedded in different languages, with "YulDSL/Haskell" being the first of its kind. Curiously, the name "yolc" sounds
> similar to "solc", the compiler program for "Solidity/Yul".
>
> Do not worry if you don't understand some of these concepts, you can start with Yolc right away and have a rewarding,
> fun experience writing safer production smart contracts. However, if you do feel adventurous and want to delve into
> the inner workings of YulDSL, read [here](./hs-pkgs/yul-dsl/README.md).

Packages
========

- *eth-abi* - Ethereum contract ABI specification in Haskell
- [*yul-dsl*](./hs-pkgs/yul-dsl/README.md) - A DSL for Solidity/Yul
- [*yul-dsl-linear-smc*](./hs-pkgs/yul-dsl-linear-smc/README.md) - Embedding YulDSL in Haskell Using Linear Types
- [*yol-suite*](./hs-pkgs/yol-suite/README.md) - A Collection of YulDSL Programs for the New Pioneer of Ethereum Smart
  Contracts Development
  - yolc: the evil twin of "solc"; this is the compiler program for "YulDSL/Haskell".
  - attila: who wields the foundy, forges his path; this is the counter part of the "forge" from
    [foundry](https://github.com/foundry-rs/foundry).
  - drwitch: who persuades the tyrant, shapes our history; this is the counter part of the "cast" from
    [foundry](https://github.com/foundry-rs/foundry).

Features
========

Extensible Type System Compatible with Ethereum Contract ABI Specification
--------------------------------------------------------------------------

> [!NOTE]
>
> These include [Ethereum contract ABI specification](https://docs.soliditylang.org/en/latest/abi-spec.html)
> implemented in as *core types*, their *type extensions*, including *dependently typed extensions*.

| ABIType Instances   | [ABICoreType]     | Name                         | Examples             |
|---------------------|-------------------|------------------------------|----------------------|
| *(core types)*      |                   |                              |                      |
| NP xs               | xs'               | N-ary products               | INT 1 :* true :* Nil |
| BOOL                | [BOOL']           | Boolean                      | true, false          |
| INTx s n            | [INTx' s n]       | Fixed-precision integers     | -1, 0, 42, 0xffff    |
| ADDR                | [ADDR']           | Ethereum addresses           | #0xABC5...290a       |
| BYTESn n            | [BYTESn']         | Binary type of n bytes       |                      |
| BYTES               | [BYTES']          | Packed byte arrays           | TODO                 |
| ARRAY a             | [ARRAY' a]        | Arrays                       | TODO                 |
| FIXx s m n          | [FIX m n]         | Fixed-point decimal numbers  | TODO                 |
| *(extended types)*  |                   |                              |                      |
| U32, ..., U256      | [INTx' False n]   | Aliases of unsigned integers | (see INTx)           |
| I32, ..., I256      | [INTx' True n]    | Aliases of signed integers   | (see INTx)           |
| B1, B2, .. B32      | [BYTESn n]        | Aliases of byte arrays       | (see BYTESn)         |
| REF a w             | [B32']            | Memory or storage references | TODO                 |
| MAYBE a             | [MAYBE' a]        | Maybe a value                | TODO                 |
| FUNC c sel          | [U192']           | Contract function pointer    | TODO                 |
| (a, b)              | [a', b']          | Tuples                       | (a, b)               |
| TUPLEn n            | [a1', a2' .. an'] | Tuples of N-elements         | (), a, (a, b, c)     |
| STRUCT lens_xs      | xs'               | Struct with lenses           | TODO                 |
| STRING              | [BYTES']          | UTF-8 strings                | TODO                 |
| MAP a b             | [B32']            | Hash tables, aka. maps       | TODO                 |
| *(dependent types)* |                   |                              |                      |
| BOOL'd v            | [BOOL']           | Dependent booleans           | TODO                 |
| INTx'd s n v        | [INTx' s n]       | Dependent integers           | TODO                 |
| BYTES'd l           | [BYTES']          | Length-indexed byte arrays   | TODO                 |
| ARRAY'd a l         | [ARRAY' a]        | Length-indexed arrays        | TODO                 |
| STRING'd v          | [BYTES']          | Dependent strings            | TODO                 |

Value Space and Its Combinators
-------------------------------

TODO.

Function Definition & Currying
------------------------------

```haskell
-- define a pure value function
foo3 = fn @(Maybe U8 -> Maybe U8 -> Maybe U8 -> Maybe U8) "id"
       (\a b c -> a + b + c)

-- call other pure value function
call3 = fn @(Maybe U8 -> Maybe U8) "id"
  (\a -> call foo3 a a a)
```

--------------------------------------------------

TODOs & Future Plans
====================

> [!WARNING]
>
> YOU DON'T NEED TO LOOK AT THIS DIRTY LAUNDRY!

**TODOs for 0.1.0.0**

- eth-abi
  - CoreTypes:
    - BYTESn
      - [ ] all supported operations
    - [ ] BYTES
    - [ ] ARRAY
  - ExtendedTypes:
    - [ ] REF
    - [ ] FUNC
    - [ ] Maybe
    - [ ] STRING
    - [ ] Tuple, TUPLEn
    - [ ]  STRUCT
  - ABITypeCodec
    - [ ]  Compatibility with the solidity abi-spec
- yul-dsl
  - Safety:
    - [ ] `P'L (v :: Nat) r a`, linearly-safety with data generation versioning tag "v".
  - Value primitives:
    - [ ] `YulAbi{Enc,Dec}`, contracts ABI serialization.
    - [ ] `YulCast`, casting values between value types.
  - Control flow primitives:
    - [ ] `YulMap`, tight loop over an array.
    - [ ] `YulLen`, array length.
    - [ ] `YulPat`, pattern matching.
  - Effects:
    - [ ] `YulSet, YulSPut`, storage operations.
    - [ ] `YulCall`, external function calls.
  - Combinators:
    - [x] `(>.>)` and `(<.<)` operators for the directional morphisms.
  - Utilities
    - [x] MPOrd class
    - [x] IfThenElse class
    - [x] Num instance
    - [-] Show instance
  - Evaluator
    - [ ] :L: Support all `YulDSL` data constructors.
  - Function Gen:
    - [ ] Change the logic to delay code gen until inner layer requires it.
  - CodeGen core:
    - [ ] Fn autoId (instead of using yulCatDigest.)
  - Object builder:
    - [ ] dispatcher builder with full dispatcher calldata codec support.
    - [ ] constructor support.
- yul-dsl-linear-smc
  - Prelude curation
- yol-suite
  - Software distributions:
    - [ ] github dev console
    - [ ] yolc.dev playground
    - [ ] Nix flake
- yolc
  - Project Builder
    - Manifest Builder:
      - [x] Single-file output mode.
      - [ ] Interface file generation.
      - [ ] Better error messages.
    - Deployment types:
      - [x] Singleton contract.
      - [ ] Factory contract.
      - [ ] Shared library.
    - Upgradability patterns:
      - [ ] Grandfatherly upgradable.
      - [ ] Full upgradable.
      - [ ] Simple library template.
    - Contract verification support:
      - [ ] Stunt contract generator.
      - [ ] Multi-files output mode
  - CLI: `yolc [options] yol_module_spec...`
    - Build Pipeline:
      - [ ] Better YOLSuite build sharing.
    - Output modes:
      - [x] Show output mode.
      - [x] Yul output mode.
      - [ ] Haskell diagrams output mode.
    - Compiler Modes:
      - [x] `symbol   :: FnCat a b`, fnMode
      - [x] `object   :: YulObject`, objectMode
      - [x] `manifest :: Manifest`, projectMode
- attila
  - Test Pipeline: `attila test`
    - [ ] QuickCheck integration using Eval monad.
    - [ ] Foundry testing integration using stunt contract.
  - Deployment Pipeline: `attila deploy`
    - [ ] Deploy the program (program is an unit of deployment.)
    - [ ] Etherscan verification pipeline.
- drwitch (not planned for the first release)

**Feature Plans**

- Generate diagrams using Haskell diagrams package.
- Liquid Haskell integration.
- Portable YulDSL artifact for non-Haskell language embedding and cross-languages modules.
