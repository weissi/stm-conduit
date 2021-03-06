module Main ( main ) where

import Data.List

import Test.Framework (defaultMain, testGroup)
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2 (testProperty)

import Test.QuickCheck
import Test.HUnit

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Class (lift)
import Control.Concurrent
import Control.Concurrent.STM
import Data.Conduit
import Data.Conduit.List
import Data.Conduit.TMChan

main = defaultMain tests

tests = [
        testGroup "Behaves to spec" [
                testCase "simpleList" test_simpleList
            ],
        testGroup "Bug fixes" [
                testCase "multipleWriters" test_multipleWriters
            ]
    ]

test_simpleList = do chan <- atomically $ newTMChan
                     forkIO . runResourceT $ sourceList testList $$ sinkTMChan chan
                     lst' <- runResourceT $ sourceTMChan chan $$ consume
                     assertEqual "for the numbers [1..10000]," testList lst'
                     closed <- atomically $ isClosedTMChan chan
                     assertBool "channel is closed after running" closed
    where
        testList = [1..10000]

test_multipleWriters = do ms <- runResourceT $ mergeSources [ sourceList ([1..10]::[Integer])
                                                            , sourceList ([11..20]::[Integer])
                                                            ] 3
                          xs <- runResourceT $ ms $$ consume
                          liftIO $ assertEqual "for the numbers [1..10] and [11..20]," [1..20] $ sort xs
