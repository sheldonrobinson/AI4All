enum TokenizerType {
  NONE,
  SENTENCEPIECE,
  HUGGINGFACE,
  RWKV
}


typedef CNERConfig = ({String path, String tokenizer,  TokenizerType type});