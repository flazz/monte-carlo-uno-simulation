import Control.Monad.State
import Random
import Data.List

data Color = Red | Green | Blue | Yellow deriving Eq

instance Show Color where
  show Red = "R"
  show Green = "G"
  show Blue = "B"
  show Yellow = "Y"

data Card = Wild | WildPlus4 | Rank Color Int |
            Skip Color | Reverse Color | Plus2 Color
            deriving Eq

instance Show Card where
  show Wild = "W"
  show WildPlus4 = "W+4"
  show (Rank c n) = (show c) ++ (show n)
  show (Skip c) = (show c) ++ "skip"
  show (Reverse c) = (show c) ++ "rev"
  show (Plus2 c) = (show c) ++ "+2"

-- TODO implement Card instance of Show

type Hand = [Card]
type Pile = [Card]

deck = wilds ++ actions ++ actions ++ zeros ++ ranks ++ ranks
  where ranks = [ Rank c n |  c <- [Red, Green, Blue, Yellow], n <- [1..9] ]
        zeros = [ Rank c 0 |  c <- [Red, Green, Blue, Yellow] ]
        actions = [ a c | a <- [Skip, Reverse, Plus2], c <- [Red, Green, Blue, Yellow] ]
        wilds = (replicate 4 Wild) ++ (replicate 4 WildPlus4)

-- draw n cards
draw n cs = (take n cs, drop n cs)

-- a machine that shuffles some of cards
shuffle :: [Card] -> IO [Card]
shuffle [] = return []
shuffle cs = do
  let upper = length cs - 1
  r <- randomRIO (0, upper)
  let c = cs !! r
  let cs' = delete c cs
  xs <- shuffle cs'
  return $ [c] ++ xs

data Uno = Uno [Hand] Pile

instance Show Uno where
  show (Uno hands pile) = players ++ "pile: " ++ (show $ head pile) ++ ", ..."
    where players = unlines [ "player " ++ (show ix) ++ ": " ++ show h | (h, ix) <- zip hands [0..] ]

initialUno :: IO Uno
initialUno = do
  scs <- shuffle deck
  let (h1, cs1) = draw 7 scs
  let (h2, cs2) = draw 7 cs1
  return $ Uno [h1,h2] cs2

--canLayDown Wild _ = true
--canLayDown WildPlus4 _ = true
--canLayDown handCard topCard = handCard.color == topCard.color || handCard.value == topCard.value
--canLayDown (Skip cc) (Skip tc) = cc == tc || cn == tc

--playHand :: Uno -> Uno
--playHand Uno [h1, h2] topCard:restOfPile =
