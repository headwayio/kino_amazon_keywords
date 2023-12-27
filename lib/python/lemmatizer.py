# lib/python/lemmatizer.py

"""
Synopsis:
    Python functions for text processing from Elixir.
See:
    Module KinoKeywords.Lemmatizer in `lib/kino_keywords/lemmatizer.ex`.
"""

from erlport.erlterms import Atom

XmlTreeDict = {}

def upcase(text):
  return text.upper()
