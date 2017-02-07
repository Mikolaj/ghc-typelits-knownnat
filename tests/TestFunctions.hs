{-# LANGUAGE DataKinds, FlexibleInstances, GADTs, KindSignatures,
             MultiParamTypeClasses, RankNTypes, ScopedTypeVariables, TemplateHaskell,
             TypeApplications, TypeFamilies, TypeOperators,
             UndecidableInstances #-}

module TestFunctions where

import Data.Proxy            (Proxy (..))
import Data.Singletons.TH    (genDefunSymbols)
import Data.Type.Bool        (If)
import GHC.TypeLits.KnownNat
import GHC.TypeLits

type family Max (a :: Nat) (b :: Nat) :: Nat where
  Max 0 b = b -- See [Note: single equation TFs are treated like synonyms]
  Max a b = If (a <=? b) b a

genDefunSymbols [''Max]

instance (KnownNat a, KnownNat b) => KnownNat2 $(nameToSymbol ''Max) a b where
  type KnownNatF2 $(nameToSymbol ''Max) = MaxSym0
  natSing2 = let x = natVal (Proxy @ a)
                 y = natVal (Proxy @ b)
                 z = max x y
             in  SNatKn z
  {-# INLINE natSing2 #-}

{- [Note: single equation TFs are treated like synonyms]
Single equation (closed) type families (TF) are treated like type synonyms, this
means that type-applications of such a TF only shows up in its expanded form.

Consequently, the KnownNat solver plugin does not have a TyCon name to look
up the corresponding instance of the KnownNat2 class.
-}

type family Min (a :: Nat) (b :: Nat) :: Nat where
  Min 0 b = 0 -- See [Note: single equation TFs are treated like synonyms]
  Min a b = If (a <=? b) a b

-- Unary functions.

withNat :: Integer -> (forall n. (KnownNat n) => Proxy n -> r) -> r
withNat n f = case someNatVal n of
               Just (SomeNat proxy) -> f proxy
               Nothing              -> error ("withNat: negative value (" ++ show n ++ ")")

type family Log (n :: Nat) :: Nat where

genDefunSymbols [''Log]

logInt :: Integer -> Integer
logInt 0 = error "log 0"
logInt n = go 0
  where
    go k = case compare (2^k) n of
             LT -> go (k + 1)
             EQ -> k
             GT -> k - 1

instance (KnownNat a) => KnownNat1 $(nameToSymbol ''Log) a where
  type KnownNatF1 $(nameToSymbol ''Log) = LogSym0
  natSing1 = let x = natVal (Proxy @ a)
             in SNatKn (logInt x)
