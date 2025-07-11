// Based on https://colab.research.google.com/github/mozilla-ai/structured-qa/blob/main/demo/notebook.ipynb#scrollTo=EXoMLseCvjtX&line=7&uniqifier=1
const UNNU_RAG_SYSTEM_PROMPT = '''
You are a rigorous assistant answering questions.
You must only answer based on the current information available which is:

```
{CURRENT_INFO}
```

If the current information available not enough to answer the question,
you must return "I need more info" and nothing else.
''';

// Based on https://machinelearningmastery.com/prompt-engineering-patterns-successful-rag-implementations/
const UNNU_RAG_QUERY_EXPANSION_PROMPT = '''
Expand the query:
```
{USER_QUERY} 
```
into 3 search-friendly versions using synonyms and related terms.

Prioritize technical terms from {KEYWORDS}.
''';

const UNNU_RAG_CONTEXTUAL_CONTINUITY_PROMPT = '''
Based on the chat history:
``` 
{CHAT_HISTORY} 
```

Rewrite the query:
```
{USER_QUERY}
```
into a standalone search query.
''';

const UNNU_RAG_HyDE_PROMPT = '''
Write a hypothetical paragraph answering:
```
{USER_QUERY}.
```

Use this text to find relevant documents.
''';

const UNNU_RAG_RETRIEVAL_CONSTRAINTS_PROMPT = '''
Answer the question:
```
{USER_QUERY}
```
using ONLY using the provided context:
```
{CURRENT_INFO}
```

If the answer isn’t there, say ‘I don’t know.’
Do not use prior knowledge.
''';

const UNNU_RAG_COT_PROMPT = '''
Based on the provided context:
```
{CURRENT_INFO}
```

Answer the question:
``` 
{USER_QUERY}
``` 
Using a step by step process: 
- first, identify key facts, 
- then reasoning through the answer.

Answer should be consistent with the provided context.
''';

const UNNU_RAG_EXTRACTIVE_ANSWER_PROMPT = '''
Extract the most relevant passage from the retrieved documents:
```
{CURRENT_INFO}
````
that answers the query:
```
{USER_QUERY}
```

Return only the exact text from
```
{CURRENT_INFO} 
```
without modification.
''';

const UNNU_RAG_CONTRASTIVE_ANSWER_PROMPT = '''
Based on the provided context:
``` 
{CURRENT_INFO}
``` 
provide a balanced analysis of
```
{USER_QUERY}
``` 
You should provide a listing of:
– Pros (supporting arguments)
– Cons (counterarguments)
Support each point with evidence from the provided context.
''';