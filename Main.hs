{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE TypeApplications           #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE TypeSynonymInstances       #-}

module Main where

import           System.Environment        (getArgs)
import           GHC.Generics
import qualified Data.ByteString.Char8     as BS
import qualified Data.Text                 as T

import qualified Database.PostgreSQL.Simple as PG

import qualified Database.Beam             as DB
import qualified Database.Beam.Backend.SQL as DB
import qualified Database.Beam.Migrate     as DB
import qualified Database.Beam.Postgres    as PG


data UserT f = User
  { _userName :: DB.Columnar f T.Text
  } deriving Generic

instance DB.Beamable UserT where

instance DB.Table UserT where
  data PrimaryKey UserT f =
    UserName (DB.Columnar f T.Text)
    deriving Generic
  primaryKey = UserName . _userName

instance DB.Beamable (DB.PrimaryKey UserT) where

data PostT f = Post
  { _postId   :: DB.Columnar f (DB.Auto Int)
  , _postText :: DB.Columnar f T.Text
  , _postBy   :: DB.PrimaryKey UserT f
  } deriving Generic

instance DB.Beamable PostT where

instance DB.Table PostT where
  data PrimaryKey PostT f =
    PostId (DB.Columnar f (DB.Auto Int))
    deriving Generic
  primaryKey = PostId . _postId

instance DB.Beamable (DB.PrimaryKey PostT) where

data BlogDb f = BlogDb
  { _blogUsers :: f (DB.TableEntity UserT)
  , _blogPosts :: f (DB.TableEntity PostT)
  } deriving Generic

instance DB.Database BlogDb where

checkedBlogDb :: DB.CheckedDatabaseSettings PG.PgValueSyntax BlogDb
checkedBlogDb = DB.defaultMigratableDbSettings @PG.PgCommandSyntax

blogDb :: DB.DatabaseSettings PG.PgValueSyntax BlogDb
blogDb = DB.unCheckDatabase checkedBlogDb

main :: IO ()
main = do
  (connStr:_) <- getArgs
  conn <- PG.connectPostgreSQL (BS.pack connStr)
  DB.withDatabaseDebug putStrLn conn $ DB.runInsert $
    DB.insert (_blogUsers blogDb) $
    DB.insertValues [ User "mckeankylej", User "tathougies" ]
