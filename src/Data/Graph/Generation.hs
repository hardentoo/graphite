{-# LANGUAGE ScopedTypeVariables #-}

module Data.Graph.Generation where

import Control.Monad (replicateM)
import Data.List     (foldl')
import System.Random

import Data.Graph.Types

-- | Probability value between 0 and 1
newtype Probability = P Float deriving (Eq, Ord, Show)

-- | Construct a 'Probability' value
probability :: Float -> Probability
probability v | v >= 1 = P 1 | v <= 0 = P 0 | otherwise = P v

-- | Generate a random Erdős–Rényi G(n, p) model graph
erdosRenyiIO :: Graph g => Int -> Probability -> IO (g Int ())
erdosRenyiIO n (P p) = go [1..n] p empty
    where
        go :: Graph g => [Int] -> Float -> g Int () -> IO (g Int ())
        go [] _ g = return g
        go (v:vs) pv g = do
            rnds <- randomRs (0.0, 1.0) <$> newStdGen
            let vs' = zip rnds vs
            go vs pv $! (foldl' (putV pv v) g vs')

        putV :: Graph g => Float -> Int -> g Int () -> (Float, Int) -> g Int ()
        putV pv v g (p', v') | p' < pv = insertEdgePair (v, v') g | otherwise = g

-- | Generate a random square binary matrix
-- | Useful for use with 'fromAdjacencyMatrix'
randomMatIO :: Int -> IO [[Int]]
randomMatIO n = replicateM n randRow
    where randRow = replicateM n (randomRIO (0,1)) :: IO [Int]