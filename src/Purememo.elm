module Purememo exposing (Memo(..), purememo, purememoExplicit, apply, repeat, thread)

import Dict exposing (Dict)

type Memo comparable a b = Memo ((a, Dict comparable b) -> (b, Dict comparable b))

apply : Memo comparable a b -> Dict comparable b -> a -> (b, Dict comparable b)
apply (Memo f) d c =
  f (c, d)


-- function composition (WIP)
--fmap : (b -> z) -> Memo comparable a b -> Memo comparable b z
--fmap f p =
--  Memo <| \(a, da) ->
--    let
--      (b, db) = apply p da a
--      z = f b
--      dz = Dict.map (\k b -> f b) db
--    in (z, dz)


-- apply function to each member of the list, threading the memodict through,
-- reusing previous calculation
--    ex:  thread memofac Dict.empty [1..4] |> fst == [1, 2, 6, 24]
thread : Memo comparable a b -> Dict comparable b -> List a -> (List b, Dict comparable b)
thread (Memo f) d0 seq =
  let
    -- the compiler can't handle this type annotation
    -- rf : comparable -> (List b, Dict comparable b) -> (List b, Dict comparable b)
    rf a (bs, d0) =
      let
        (b, d1) = f (a, d0)
      in
        (b :: bs, d1)
    (bs, d1) = List.foldl rf ([], d0) seq
  in
    -- TODO: can this be done without reverse?
    (List.reverse bs, d1)


-- repeat an operation n times, using the last result as the next input
--   ex: repeat (purememo identity ((*) 2)) Dict.empty 2 3 |> fst == 12
repeat : Memo comparable a a -> Dict comparable a -> Int -> a -> (a, Dict comparable a)
repeat (Memo f) d0 n a0 =
  let
    rf _ (a0, d0) =
      let
        (a1, d1) = f (a0, d0)
      in
        (a1, d1)
    (a1, d1) = List.foldl rf (a0, d0) [1..n]
  in
    (a1, d1)


purememo : (a -> comparable) -> (a -> b) -> Memo comparable a b
purememo keyfunc f =
  let
    memoized (a, d0) =
      let k = keyfunc a
      in case Dict.get k d0 of
        Just b -> (b, d0)
        Nothing ->
          let
            b = f a
            d1 = Dict.insert k b d0
          in (b, d1)
  in
    Memo memoized

purememoExplicit : (a -> comparable) -> (a -> Dict comparable b -> b) -> Memo comparable a b
purememoExplicit keyfunc f =
  let
    memoized (a, d0) =
      let k = keyfunc a
      in case Dict.get k d0 of
        Just v -> (v, d0)
        Nothing ->
          let
            v = f a d0
            d1 = Dict.insert k v d0
          in (v, d1)
  in
    Memo memoized
