module WarmupReadP where

-- Original grammar (E is start symbol):
--   E ::= E "+" T | E "-" T | T | "-" T .
--   T ::= num | "(" E ")" .
-- Lexical specifications:
--   num is one or more decimal digits (0-9)
--   tokens may be separated by arbtrary whitespace (spaces, tabs, newlines).

-- Rewritten grammar, without left-recursion:
--   E  ::= TE' | "-" T
--   E' ::= "+" TE' | "-" TE' | ε
--   T  ::= num | "(" E ")"

import Text.ParserCombinators.ReadP
import Control.Applicative ()
  -- may use instead of +++ for easier portability to Parsec

import Data.Char

type Parser a = ReadP a   -- may use synomym for easier portability to Parsec

type ParseError = String  -- not particularly informative with ReadP

data Exp = Num Int | Negate Exp | Add Exp Exp
  deriving (Eq, Show)

intNum :: Parser Exp
intNum = token (do num <- digits
                   return (Num (read num)))
       where digits = many1(satisfy isDigit)

space :: Parser Char
space = satisfy isSpace
spaces :: Parser String
spaces = many space
spaces1 :: Parser String
spaces1 = many1 space

token :: Parser a -> Parser a
token p = spaces >> p

symbol :: String -> Parser String
symbol = token . string
schar :: Char -> Parser Char
schar = token . char

-- e  =  do t
--          e'
--          return ()
-- e' = (do symbol "+"
--          t
--          e'
--          return ())
--  <|> (do symbol "-"
--          t
--          e'
--          return ())
--  <|> return ()
-- t  = (do _ <- num
--          return ())
--  <|> (do symbol "("
--          e
--          symbol ")"
--          return ())
-- parseString = e >> token eof

e, t :: Parser Exp
e =     (do skipSpaces
            tv <- t
            skipSpaces
            e' tv)
    <++ (do symbol "-"
            skipSpaces
            tv <- t
            skipSpaces
            e' (Negate tv))
e' :: Exp -> Parser Exp
e' inval = 
        (do symbol "+"
            skipSpaces
            tv <- t
            skipSpaces
            e' (Add inval tv))
    <++ (do symbol "-"
            skipSpaces
            tv <- t
            skipSpaces
            e' (Add inval (Negate tv)))
    <++ return inval
t = intNum
    <++ (do symbol "("
            skipSpaces
            ev <- e
            symbol ")"
            skipSpaces
            return ev)

parseString :: String -> Either ParseError Exp
parseString str = case readP_to_S e str of
  [] -> Left "Parsing Error"
  _  -> case snd (last (readP_to_S e str)) of
    "" -> Right (fst (last (readP_to_S e str)))
    _  -> Left "Invalid Input"
