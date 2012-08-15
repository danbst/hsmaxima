hsmaxima
========

*hsmaxima* is simple module for binding Maxima CAS (Computer Algebra System) to Haskell programs.

No installation, just copy-paste the `Maxima.hs` to your working directory. No external 
libraries are required, Haskell Platform and maxima itself are only requirements.

Helloworld program looks like this:
```
{- maxhello.hs -}
import Maxima
 
--   Start maxima client on port 4424 and print answer for 2+2 expression
-- Though one can think, that there is maxima server, in fact Haskell script is server
-- and maxima itself is just client.
main = runMaxima 4424 $ \x -> askMaxima x "2+2" >>= print
```

The output is:
```
$ runhaskell maxhello.hs
["4"]
$ 
```

1. The output is returned as list. This is, because Maxima supports multiline scripts.
   You can make `askMaxima x "2+2;sin(%pi/2);"` and obtain two answers.
2. When error is occured, the output is ignored. So running `askMaxima x "2+2;1/0;sin(%pi/2);"`
   you will get only 2 results without information, which of three failed.
   To resolve this problems, you can run several `askMaxima` or use `askMaximaRaw` and
   parse result manually.

Feedback is welcome.

PS. One more example, interactive console:
```
import Maxima
 
maximaPrompt srv = do
    putStr "> "
    question <- getLine
    if question == ":q"
       then return ()
       else do answer <- askMaxima srv question
               print answer
               maximaPrompt srv
               
main = runMaxima 4424 maximaPrompt
```