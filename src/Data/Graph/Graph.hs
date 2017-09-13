{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Data.Graph.Graph where

import Data.List (foldl')

import           Data.Hashable
import qualified Data.HashMap.Lazy as HM

import Data.Graph.Types

-- | Undirected Graph of Vertices in /v/ and Edges with attributes in /e/
type Graph v e = HM.HashMap v (Links v e)

-- | The Empty (order-zero) 'Graph' with no vertices and no edges
empty :: (Hashable v) => Graph v e
empty = HM.empty

-- | @O(log n)@ Insert a vertex into a 'Graph'
-- | If the graph already contains the vertex leave the graph untouched
insertVertex :: (Hashable v, Eq v) => v -> Graph v e -> Graph v e
insertVertex v = hashMapInsert v HM.empty

-- | @O(n)@ Remove a vertex from a 'Graph' if present
-- | Every 'Edge' adjacent to this vertex is also removed
-- FIXME
-- removeVertex :: (Hashable v, Eq v) => v -> Graph v e -> Graph v e
-- removeVertex v g = HM.delete v $ foldl' (flip removeEdge) g $ incidentEdges g v

-- | @O(m*log n)@ Insert a many vertices into a 'Graph'
-- | New vertices are inserted and already contained vertices are left untouched
insertVertices :: (Hashable v, Eq v) => [v] -> Graph v e -> Graph v e
insertVertices vs g = foldl' (flip insertVertex) g vs

-- | @O(log n)@ Insert an undirected 'Edge' into a 'Graph'
-- | The involved vertices are inserted if don't exist. If the graph already
-- | contains the Edge, its attribute is updated
insertEdge :: (Hashable v, Eq v) => Edge v e -> Graph v e -> Graph v e
insertEdge (Edge v1 v2 edgeAttr) g = link v2 v1 $ link v1 v2 g'
    where
        g' = insertVertices [v1, v2] g
        link fromV toV = HM.adjust (insertLink toV edgeAttr) fromV

-- | @O(m*log n)@ Insert many directed 'Edge's into a 'Graph'
-- | Same rules as 'insertEdge' are applied
insertEdges :: (Hashable v, Eq v) => [Edge v e] -> Graph v e -> Graph v e
insertEdges as g = foldl' (flip insertEdge) g as

-- | @O(log n)@ Remove the undirected 'Edge' from a 'Graph' if present
-- | The involved vertices are left untouched
removeEdge :: (Hashable v, Eq v) => Edge v e -> Graph v e -> Graph v e
removeEdge = removeEdge' . toUnorderedPair

-- | Same as 'removeEdge' but the edge is an unordered tuple
-- TODO: use containsVertex instead of HM.member
removeEdge' :: (Hashable v, Eq v) => (v, v) -> Graph v e -> Graph v e
removeEdge' (v1, v2) g
    | HM.member v1 g && HM.member v2 g = update v2Links v2 $ update v1Links v1 g
    | otherwise = g
    where
        v1Links = HM.delete v2 $ getLinks v1 g
        v2Links = HM.delete v1 $ getLinks v2 g
        update = HM.adjust . const

-- | @O(log n)@ Remove the undirected 'Edge' from a 'Graph' if present
-- | The involved vertices are also removed
-- removeEdgeAndVertices :: (Hashable v, Eq v) => Edge v e -> Graph v e -> Graph v e
-- removeEdgeAndVertices = removeEdgeAndVertices' . toOrderedPair

-- | Same as 'removeEdgeAndVertices' but the edge is an unordered tuple
-- removeEdgeAndVertices' :: (Hashable v, Eq v) => (v, v) -> Graph v e -> Graph v e
-- removeEdgeAndVertices' (v1, v2) g =
--     removeVertex v2 $ removeVertex v1 $ removeEdge' (v1, v2) g

-- | @O(n)@ Retrieve the vertices of a 'Graph'
vertices :: Graph v e -> [v]
vertices = HM.keys

-- | @O(n)@ Retrieve the order of a 'Graph'
-- | The @order@ of a graph is its number of vertices
order :: Graph v e -> Int
order = HM.size

-- | @O(n*m)@ Retrieve the size of a 'Graph'
-- | The @size@ of an undirected graph is its number of 'Edge's
size :: (Hashable v, Eq v) => Graph v e -> Int
size = length . edges

-- | @O(n*m)@ Retrieve the 'Edge's of a 'Graph'
edges :: forall v e . (Hashable v, Eq v) => Graph v e -> [Edge v e]
edges g = linksToEdges $ zip vs links
    where
        vs :: [v]
        vs = vertices g
        links :: [Links v e]
        links = fmap (`getLinks` g) vs

-- | Same as 'edges' but the edges are unordered tuples, and their attributes
-- | are discarded
edges' :: (Hashable v, Eq v) => Graph v e -> [(v, v)]
edges' g = toUnorderedPair <$> edges g
