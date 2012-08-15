module Maxima ( MaximaServerParams
              , runMaxima
              , askMaxima
              , askMaximaRaw
              )
  where

import Data.List
import Data.Char
import Network.Socket

import System.IO
import System.Process
import System.Posix.Signals
import System.Process.Internals

import Control.Exception
import Control.Concurrent
import Control.Applicative

data MaximaServerParams = MaximaServerParams 
  { mConnection :: Socket
  , mSocket :: Socket
  , mHandle :: Handle
  , mPid :: ProcessHandle 
  }

startMaximaServer port = withSocketsDo $ do
    conn <- listenServer port
    (_, _, _, pid) <- runInteractiveProcess "maxima"
                                            (["-r", ":lisp (setup-client "++show port++")"]) 
                                            Nothing Nothing
    (sock, _) <- accept conn
    socketHandle <- socketToHandle sock ReadWriteMode
    hSetBuffering socketHandle NoBuffering
    hTakeWhileNotFound "(%i" socketHandle >> hTakeWhileNotFound ")" socketHandle
    return$ MaximaServerParams conn sock socketHandle pid
 
askMaximaRaw (MaximaServerParams _ _ hdl _) question = do
    hPutStrLn hdl question
    result <- hTakeWhileNotFound "(%i" hdl
    hTakeWhileNotFound ")" hdl
    return$ take (length result - 3) result

initMaximaVariables maxima = do
    askMaximaRaw maxima "display2d: false;"
    askMaximaRaw maxima "linel: 10000;"

askMaxima maxima question = do
  if null $ dropWhile isSpace question 
     then return []
     else do
       let q = dropWhileEnd isSpace question
           q2 = if elem (last q) ['$',';'] then q else q ++ ";"
       result <- askMaximaRaw maxima q2
       return$ filter (not.null) . map (drop 2) . filter (not.null) . map (dropWhile (/=')'))$ lines result
    
runMaxima port f = bracket (startMaximaServer port)
                           (\srv -> do terminateProcess2 (mPid srv)
                                       waitForProcess (mPid srv)
                                       sClose (mConnection srv))
                           (\x -> initMaximaVariables x >> f x)

listenServer port = do
    sock <- socket AF_INET Stream 0
    setSocketOption sock ReuseAddr 1
    bindSocket sock (SockAddrInet port iNADDR_ANY)
    listen sock 1
    return sock

terminateProcess2 :: ProcessHandle -> IO ()
terminateProcess2 ph = do
    let (ProcessHandle pmvar) = ph
    ph_ <- readMVar pmvar
    case ph_ of
        OpenHandle pid -> do  -- pid is a POSIX pid
            signalProcess 15 pid
        otherwise -> return ()
    
hTakeWhileNotFound str hdl = fmap reverse$ findStr str hdl [0] []
 where
   findStr str hdl indeces acc = do 
     c <- hGetChar hdl
     let newIndeces = [ i+1 | i <- indeces, i < length str, str!!i == c]
     if length str `elem` newIndeces
       then return (c : acc)
       else findStr str hdl (0 : newIndeces) (c : acc)