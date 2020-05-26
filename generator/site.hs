--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend, mempty)
import           Hakyll
import qualified GHC.IO.Encoding as E


--------------------------------------------------------------------------------

preambleForTag 
  :: String 
  -> [Item String] 
  -> Compiler (Maybe String)
preambleForTag tag preambles =
  let
    headMay [] = 
      Nothing
    headMay (x:_) = 
      Just x
    matchesTag i = 
      case capture "tags/preambles/*.md" i of
        Just [x] -> x == tag
        _ -> False
  in
    pure . 
    fmap itemBody . 
    headMay . 
    filter (matchesTag . itemIdentifier) $ 
    preambles

main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= saveSnapshot "post-content"
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "tags/preambles/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/preamble.html" defaultContext

    tags <- buildTags "posts/*" (fromCapture "tags/*.html")
    tagsRules tags $ \tag pattern -> do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots pattern "post-content"
        mPreamble <- preambleForTag tag =<< loadAll "tags/preambles/*"
        let 
          preambleCtx = maybe mempty (constField "preamble") mPreamble
          ctx = constField "tag" tag
                `mappend` preambleCtx
                `mappend` listField "posts" postCtx (return posts)
                `mappend` defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAllSnapshots "posts/*" "post-content"
            let
                indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    constField "home-active" ""              `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%Y-%m-%d %H:%M:%S" `mappend`
    defaultContext
