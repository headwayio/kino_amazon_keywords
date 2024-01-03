# requirment
# ntlk

import json
import nltk

from nltk.stem import WordNetLemmatizer
from collections import defaultdict

def custom_normalize(lemmatizer, phrase):
    # Separate phrases with spaces
    words = phrase.split()

    # Normalize each word
    normalized_words = [lemmatizer.lemmatize(word) for word in words]

    # Rejoin normalized words
    return ' '.join(normalized_words)

def main(data_list):
    data_list = json.loads(data_list)

    nltk.download('wordnet')

    # nltk in the library
    # WordNetLemmatizer Create object
    lemmatizer = WordNetLemmatizer()

    # Dictionary to store normalized data
    merged_data = defaultdict(lambda: {'volume': 0, 'frequency': 0})

    # list traversal
    for item in data_list:
        normalized_root = custom_normalize(lemmatizer, item['root'])
        merged_data[normalized_root]['volume'] += item['volume']
        merged_data[normalized_root]['frequency'] += item['frequency']

    # Create result list
    result_list = [{'root': root, 'volume': info['volume'], 'frequency': info['frequency']} for root, info in merged_data.items()]

    return json.dumps(result_list)
