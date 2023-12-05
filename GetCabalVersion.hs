{-# LANGUAGE CPP #-}

import Distribution.PackageDescription (package, packageDescription)
#if __GLASGOW_HASKELL__ < 904
import Distribution.PackageDescription.Parsec (readGenericPackageDescription)
#else
import Distribution.Simple.PackageDescription (readGenericPackageDescription)
#endif
import Distribution.Pretty (prettyShow)
import Distribution.Types.PackageId (PackageIdentifier, pkgVersion)
import Distribution.Verbosity (silent)
import System.Environment (getArgs)

getPackageId :: IO PackageIdentifier
getPackageId = do
    args <- getArgs
    gpd <- readGenericPackageDescription silent (head args)
    return $ package $ packageDescription gpd

packageVersion :: PackageIdentifier -> String
packageVersion =
  prettyShow . pkgVersion

main :: IO ()
main = do
    pkgid <- getPackageId
    putStrLn $ packageVersion pkgid
    return ()
