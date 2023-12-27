# requirment
# ntlk

from nltk.stem import WordNetLemmatizer
from collections import defaultdict
import nltk

def custom_normalize(lemmatizer,phrase):
    # 문구를 공백으로 분리
    words = phrase.split()
    # 각 단어를 정규화
    normalized_words = [lemmatizer.lemmatize(word) for word in words]
    # 정규화된 단어를 다시 합침
    return ' '.join(normalized_words)

def main():
    nltk.download('wordnet')
    # nltk 라이브러리에서 WordNetLemmatizer 객체 생성
    lemmatizer = WordNetLemmatizer()

    data_list = [
      {
        "root": "candles",
        "volume": 2.75,
        "frequency": 2
      },
      {
        "root": "candle",
        "volume": 4.75,
        "frequency": 1
      },
      {
        "root": "holiday",
        "volume": 2.25,
        "frequency": 1
      },
      {
        "root": "scented",
        "volume": 0.5,
        "frequency": 1
      },
      {
        "root": "the",
        "volume": 0.5,
        "frequency": 1
      },
      {
        "root": "holidays",
        "volume": 0.5,
        "frequency": 1
      },
      {
        "root": "holiday candles",
        "volume": 2.25,
        "frequency": 1
      },
      {
        "root": "candles the",
        "volume": 0.5,
        "frequency": 1
      },
      {
        "root": "scented candles",
        "volume": 0.5,
        "frequency": 1
      },
      {
        "root": "the holidays",
        "volume": 0.5,
        "frequency": 1
      }
    ]

    # 데이터
    # data_list = Root_list

    # 정규화된 데이터를 저장할 딕셔너리
    merged_data = defaultdict(lambda: {'volume': 0, 'frequency': 0})

    # 리스트 순회
    for item in data_list:
        normalized_root = custom_normalize(lemmatizer,item['root'])
        merged_data[normalized_root]['volume'] += item['volume']
        merged_data[normalized_root]['frequency'] += item['frequency']

    # 결과 리스트 생성
    result_list = [{'root': root, 'volume': info['volume'], 'frequency': info['frequency']} for root, info in merged_data.items()]
    return result_list
