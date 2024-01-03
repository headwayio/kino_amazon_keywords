# lib/python/lemmatizer.py

"""
Synopsis:
    Python functions for text processing from Elixir.
See:
    Module KinoKeywords.Lemmatizer in `lib/kino_keywords/lemmatizer.ex`.
"""

from erlport.erlterms import Atom

import inspect
import json
import sys
import nltk

from nltk.stem import WordNetLemmatizer
from collections import defaultdict

XmlTreeDict = {}

def foo():
    return json.dumps({'foo': sys.path})

def upcase(text):
    nltk.download('wordnet')

    text = json.loads(text)

    result = {'foo': text.get('foo').upper()}

    return json.dumps(result)
