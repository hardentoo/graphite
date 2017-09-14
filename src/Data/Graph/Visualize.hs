module Data.Graph.Visualize where

import Data.GraphViz
import Data.Hashable
import Data.Monoid    ((<>))
import System.Process

-- import qualified Data.Graph.DGraph as DG
import qualified Data.Graph.Graph as G
import           Data.Graph.Types

labeledNodes :: (Show v) => G.Graph v e -> [(v, String)]
labeledNodes g = fmap (\v -> (v, show v)) $ G.vertices g

labeledEdges :: (Hashable v, Eq v, Show e) => G.Graph v e -> [(v, v, String)]
labeledEdges g = fmap (\(Edge v1 v2 attr) -> (v1, v2, show attr)) $ G.edges g

toDot' :: (Show e) => G.Graph Int e -> DotGraph Int
toDot' g = graphElemsToDot params (labeledNodes g) (labeledEdges g)
    where params = nonClusteredParams { isDirected = False }

plotIO :: (Show e) => G.Graph Int e -> FilePath -> IO FilePath
plotIO g fp = addExtension (runGraphviz $ toDot' g) Png fp

plotXdgIO :: (Show e) => G.Graph Int e -> FilePath -> IO ()
plotXdgIO g fp = do
    fp' <- plotIO g fp
    _ <- system $ "xdg-open " <> fp'
    return ()
