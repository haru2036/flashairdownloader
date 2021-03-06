{-# LANGUAGE OverloadedStrings #-}
module Lib
    ( someFunc
    , getUrl
    , appendBaseUrl
    )
where

import           Network.HTTP.Client
import           Control.Monad
import           Data.Text                      ( Text )
import           Data.Text.Lazy.Encoding
import           Data.ByteString                ( ByteString
                                                , writeFile
                                                )
import           Data.ByteString.Lazy           ( toStrict )
import           Data.ByteString.Char8          ( unpack )
import           Data.List.Split                ( splitOn )
import           Data.List                      ( filter
                                                , notElem
                                                )
import           System.Directory
import           Pages
import           Types
import           FAPath
import           LocalPath
import           HTTP
import           Network.HTTP
import           Network.URI

someFunc = downloadNotDownloadedFiles

downloadAllFiles :: IO ()
downloadAllFiles = do
    fileList <- listFAFiles
    mapM_ downloadAndSaveFile fileList
    return ()

downloadNotDownloadedFiles :: IO ()
downloadNotDownloadedFiles = do
    faFileList <- listFAFiles
    lFileList  <- listLocalFiles
    let lfiles = map (filename . getPath) lFileList
    print lfiles
    mapM_ downloadAndSaveFile
        $ filter (\item -> (filename $ getPath item) `notElem` lfiles) faFileList
    where filename = reverse . takeWhile (/= '/') . reverse -- もっと良い方法がありそう


downloadAndSaveFile :: FAPath -> IO ()
downloadAndSaveFile path = do
    case parseURI $ appendBaseUrl $ getPath path of
        Just uri -> do
            result <- simpleHTTP $ Request uri GET [] ""    
            print ("downloading:" ++ (fileName (getPath path)))
            createDirectoryIfMissing True $ fileDir ("photos" ++ getPath path)
            case result of 
                Right res -> Data.ByteString.writeFile ("photos" ++ getPath path) $ rspBody res
                Left err -> print err
        Nothing -> return ()
  where
    fileDir  = reverse . dropWhile ('/' /=) . reverse
    fileName = reverse . takeWhile ('/' /=) . reverse
