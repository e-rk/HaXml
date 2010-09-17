-- | A type model for Haskell datatypes that bears a reasonable correspondence
--   to the XSD type model.
module Text.XML.HaXml.Schema.HaskellTypeModel
  ( module Text.XML.HaXml.Schema.HaskellTypeModel
  ) where

import Text.XML.HaXml.Schema.NameConversion
import Text.XML.HaXml.Schema.XSDTypeModel (Occurs)
import Text.XML.HaXml.Types (QName(..))
import Data.List (partition)

-- | Comments can be attached to most things, but not all of them will exist.
type Comment = Maybe String

-- | The whole Haskell module.
data Module    = Module
                 { module_name        :: XName   -- the name of this module
                 , module_re_exports  :: [Decl]  -- modules imported + exported
                 , module_import_only :: [Decl]  -- module + alias
                 , module_decls       :: [Decl]  -- the body of the module
                 }

mkModule :: String -> [Decl] -> Module
mkModule name decls = Module { module_name        = XName $ N name
                             , module_re_exports  = reexports
                             , module_import_only = imports
                             , module_decls       = theRest
                             }
    where (reexports,other)   = partition xsdinclude decls
          (imports,  theRest) = partition xsdimport  other
          xsdinclude (XSDInclude _ _)  = True
          xsdinclude _                 = False
          xsdimport  (XSDImport _ _ _) = True
          xsdimport  _                 = False


-- | There are essentially simple types, and complex types, each of which
--   can be either restricted or extended.  There are four kinds of complex
--   type: choices, sequences, named groups, or a simple element with content.
data Decl
                 -- becomes type T = S
               = NamedSimpleType     XName XName Comment

                 -- becomes newtype T = T S
                 --       + instance Restricts T S where restricts ...
               | RestrictSimpleType  XName XName [Restrict] Comment

                 -- becomes data T  = T  S Tf
                 --       + data Tf = Tf {fields}
                 --       + instance Extension T S Tf where ...
               | ExtendSimpleType    XName XName [Attribute] Comment

                 -- becomes data T = Ta S0 | Tb S1 | Tc S2 | ...
               | UnionSimpleTypes    XName [XName] Comment

                 -- becomes data T = T_C0 | T_C1 | T_C2 | ...
               | EnumSimpleType      XName [(XName,Comment)] Comment

                 -- becomes data T  = T { singleattr, fields }
                 --   or    data T  = T { manyattr, singlefield }
                 --   or    data T  = T { t_attrs :: Ta, fields }
                 --       + data Ta = Ta { attributes }
               | ElementsAttrs XName [Element] [Attribute] Comment

                 -- becomes function elementE = parseElement "E" :: Parser T
               | ElementOfType Element

                 -- becomes (global) data T = E0 e0 | E1 e1 | E2 e2 | E3 e3
                 -- becomes (local)  OneOfN e0 e1 e2 e3
               | Choice XName [Element] Comment

                 -- becomes data GroupT = GT e0 e1 e2 e3
               | Group  XName [Element] Comment

      {-         -- becomes data GroupT = GT e0 e1 e2 e3
               | GroupAttrs XName [Attribute] Comment
      -}
                 -- becomes newtype T = T S
                 --       + different (more restrictive) parser
               | RestrictComplexType  XName XName Comment

                 -- becomes data T  = T  S Tf
                 --       + data Tf = Tf {fields}
                 --       + instance Extension T S Tf where ...
      --       | ExtendComplexType XName XName [Element] [Attribute] Comment
               | ExtendComplexType XName XName [Element] [Attribute]
                                               [Element] [Attribute] Comment

                 -- becomes an import and re-export
               | XSDInclude XName Comment
                 -- becomes an import only
               | XSDImport  XName (Maybe XName) Comment
                 -- a top-level annotation
               | XSDComment Comment
                 deriving (Eq,Show)

data Element   = Element { elem_name     :: XName
                         , elem_type     :: XName
                         , elem_modifier :: Modifier
                         , elem_byRef    :: Bool
                         , elem_locals   :: [Decl]
                         , elem_comment  :: Comment
                         }
               | OneOf   { elem_oneOf    :: [Element]
                         , elem_modifier :: Modifier
                         , elem_comment  :: Comment
                         }
                 deriving (Eq,Show)
data Attribute = Attribute { attr_name    :: XName
                           , attr_type    :: XName
                           , attr_comment :: Comment
                           }
                 deriving (Eq,Show)

data Modifier  = Single
               | Optional
               | Range Occurs
                 deriving (Eq,Show)

-- | Restrictions on simpleType
data Restrict  = RangeR Occurs Comment
               | Pattern String{-really Regexp-} Comment
               | Enumeration [(String,Comment)]
               | StrLength Occurs Comment
                 deriving (Eq,Show)

