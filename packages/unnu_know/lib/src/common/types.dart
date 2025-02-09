import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:unnu_dxl/unnu_dxl.dart';
import 'package:unnu_ragl/unnu_ragl.dart';

// Inspiration https://github.com/superagent-ai/super-rag
// https://github.com/SciPhi-AI/R2R/blob/main/py/shared/api/models/retrieval/responses.py
// https://github.com/QuivrHQ/quivr/tree/main/core/quivr_core/rag

@immutable
class RequestPayload {
  RequestPayload({
    required this.query,
    required this.corpus,
  });

  factory RequestPayload.fromMap(Map<String, dynamic> map) {
    return RequestPayload(
      query: (map['query'] ?? '') as String,
      corpus: Uri.tryParse((map['corpus'] ?? '') as String) ?? Uri(),
    );
  }

  factory RequestPayload.fromJson(String source) =>
      RequestPayload.fromMap(json.decode(source) as Map<String, dynamic>);
  final String query;
  final Uri corpus;

  RequestPayload copyWith({
    String? query,
    Uri? corpus,
  }) {
    return RequestPayload(
      query: query ?? this.query,
      corpus: corpus ?? this.corpus,
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}
          ..addAll({'query': query, 'corpus': corpus.toString()});

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'RequestPayload(query: $query, corpus: $corpus)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RequestPayload &&
        other.query == query &&
        other.corpus == corpus;
  }

  @override
  int get hashCode => query.hashCode ^ corpus.hashCode;
}

class DocumentChunk {
  DocumentChunk({
    required this.id,
    required this.document_id,
    required this.content,
    required this.chunk_index,
    required this.title,
    required this.reference,
    required this.metadata,
  });

  factory DocumentChunk.fromMap(Map<String, dynamic> map) {
    return DocumentChunk(
      id: (map['id'] ?? '') as String,
      document_id: (map['document_id'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      chunk_index: (map['chunk_index'] ?? 0) as int,
      title: (map['title'] ?? '') as String,
      reference: Uri.tryParse((map['reference'] ?? '') as String) ?? Uri(),
      metadata:
          (map['metadata'] ?? <String, dynamic>{}) as Map<String, dynamic>,
    );
  }

  factory DocumentChunk.fromJson(String source) =>
      DocumentChunk.fromMap(json.decode(source) as Map<String, dynamic>);
  String id;
  String document_id;
  String content;
  int chunk_index;
  String title;
  Uri reference;
  Map<String, dynamic> metadata;

  DocumentChunk copyWith({
    String? id,
    String? document_id,
    String? content,
    int? chunk_index,
    String? title,
    Uri? reference,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentChunk(
      id: id ?? this.id,
      document_id: document_id ?? this.document_id,
      content: content ?? this.content,
      chunk_index: chunk_index ?? this.chunk_index,
      title: title ?? this.title,
      reference: reference ?? this.reference,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'document_id': document_id});
    result.addAll({'content': content});
    result.addAll({'chunk_index': chunk_index});
    result.addAll({'title': title});
    result.addAll({'reference': reference.toString()});
    result.addAll({'metadata': metadata});

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'DocumentChunk(id: $id, document_id: $document_id, content: $content, chunk_index: $chunk_index, title: $title, reference: $reference, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is DocumentChunk &&
        other.id == id &&
        other.document_id == document_id &&
        other.content == content &&
        other.chunk_index == chunk_index &&
        other.title == title &&
        other.reference == reference &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        document_id.hashCode ^
        content.hashCode ^
        chunk_index.hashCode ^
        title.hashCode ^
        reference.hashCode ^
        metadata.hashCode;
  }
}

class ResponseData {
  ResponseData({
    required this.content,
    required this.citations,
    required this.references,
    required this.metadata,
  });

  factory ResponseData.fromMap(Map<String, dynamic> map) {
    return ResponseData(
      content: (map['content'] ?? '') as String,
      citations: (map['citations'] ?? <String, Uri>{}) as Map<String, Uri>,
      references: (map['references'] ?? <String, Uri>{}) as Map<String, Uri>,
      metadata:
          (map['metadata'] ?? <String, dynamic>{}) as Map<String, dynamic>,
    );
  }

  factory ResponseData.fromJson(String source) =>
      ResponseData.fromMap(json.decode(source) as Map<String, dynamic>);
  String content;
  Map<String, Uri> citations;
  Map<String, Uri> references;
  Map<String, dynamic> metadata;

  ResponseData copyWith({
    String? content,
    Map<String, Uri>? citations,
    Map<String, Uri>? references,
    Map<String, dynamic>? metadata,
  }) {
    return ResponseData(
      content: content ?? this.content,
      citations: citations ?? this.citations,
      references: references ?? this.references,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'content': content});
    result.addAll({'citations': citations});
    result.addAll({'references': references});
    result.addAll({'metadata': metadata});

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '''
    ResponseData:
    \tcontent: $content
    \tcitations: $citations
    \treferences: $references
    \tmetadata: $metadata
    ''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is ResponseData &&
        other.content == content &&
        mapEquals(other.citations, citations) &&
        mapEquals(other.references, references) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return content.hashCode ^
        citations.hashCode ^
        references.hashCode ^
        metadata.hashCode;
  }
}

class ResponsePayload {
  ResponsePayload({
    required this.status,
    required this.data,
  });

  factory ResponsePayload.fromMap(Map<String, dynamic> map) {
    return ResponsePayload(
      status: (map['status'] ?? false) as bool,
      data: List<DocumentChunk>.from(
        ((map['data'] ?? <Map<String, dynamic>>[])
                as List<Map<String, dynamic>>)
            .map((x) => DocumentChunk.fromMap(x)),
      ),
    );
  }

  factory ResponsePayload.fromJson(String source) =>
      ResponsePayload.fromMap(json.decode(source) as Map<String, dynamic>);
  bool status;
  List<DocumentChunk> data;

  ResponsePayload copyWith({
    bool? status,
    List<DocumentChunk>? data,
  }) {
    return ResponsePayload(
      status: status ?? this.status,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}
          ..addAll({'status': status})
          ..addAll({'data': data.map((x) => x.toMap()).toList()});

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'ResponsePayload(status: $status, data: $data)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is ResponsePayload &&
        other.status == status &&
        listEquals(other.data, data);
  }

  @override
  int get hashCode => status.hashCode ^ data.hashCode;
}

class UnnuEmbeddings implements Embeddings {
  @override
  Future<List<List<double>>> embedDocuments(List<Document> documents) async {
    final embeddings = <List<double>>[];
    for (final doc in documents) {
      final val = await RagLite.instance.embedQuery(doc.pageContent);
      embeddings.add(val.embeddings);
    }
    return embeddings;
  }

  @override
  Future<List<double>> embedQuery(String query) async {
    final val = await RagLite.instance.embedQuery(query);
    return val.embeddings;
  }
}

@immutable
class UnnuCorpusSettings {
  UnnuCorpusSettings({
    required this.uri,
    required this.embeddings,
    required this.vectorStore,
  });
  final Set<Uri> uri;
  final Embeddings embeddings;
  final VectorStore vectorStore;

  static UnnuCorpusSettings defaults() {
    final store = InMemoryStore<String, List<double>>(initialData: <String, List<double>>{});
    final embeddings = CacheBackedEmbeddings(
      underlyingEmbeddings: UnnuEmbeddings(),
      documentEmbeddingsStore: store,
    );
    return UnnuCorpusSettings(
      uri: const <Uri>{},
      embeddings: embeddings,
      vectorStore: MemoryVectorStore(
        embeddings: embeddings,
        initialMemoryVectors: <MemoryVector>[]
      ),
    );
  }

  UnnuCorpusSettings copyWith({
    Set<Uri>? uri,
    BaseStore<String, List<double>>? store,
    Embeddings? embeddings,
    VectorStore? vectorStore,
  }) {
    return UnnuCorpusSettings(
      uri: uri ?? this.uri,
      embeddings: embeddings ?? this.embeddings,
      vectorStore: vectorStore ?? this.vectorStore,
    );
  }

  @override
  String toString() =>
      'UnnuCorpusSettings(uri: $uri, embeddings: $embeddings, vectorStore: $vectorStore)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnnuCorpusSettings &&
        other.uri == uri &&
        other.embeddings == embeddings &&
        other.vectorStore == vectorStore;
  }

  @override
  int get hashCode => uri.hashCode ^ embeddings.hashCode ^ vectorStore.hashCode;
}

typedef EmbeddedDocument = ({Set<String> id, Uri uri});

class UnnuCorpusController extends JuneState {
  UnnuCorpusSettings settings = UnnuCorpusSettings.defaults();

  Future<void> doSwitch(List<EmbeddedDocument> documents) async {
    var mappings = <String, List<double>>{};
    var vs = <MemoryVector>[];
    final uris =
        documents
            .map(
              (e) => e.uri,
            )
            .toSet();
    for (final element in documents) {
      for (final id in element.id) {
        final docs = await RagLite.instance.retrieve(id).toList();
        for (final doc in docs) {
          mappings[doc.document] = doc.embeddings;
          vs.add(
            MemoryVector(
              document: Document(
                id: doc.documentId,
                pageContent: doc.document,
              ),
              embedding: doc.embeddings,
            ),
          );
        }
      }
    }

    final store = InMemoryStore<String, List<double>>(initialData: mappings);
    final embeddings = CacheBackedEmbeddings(
      underlyingEmbeddings: UnnuEmbeddings(),
      documentEmbeddingsStore: store,
    );

    settings = UnnuCorpusSettings(
      // store: store,
      embeddings: embeddings,
      vectorStore: MemoryVectorStore(
        embeddings: embeddings,
        initialMemoryVectors: vs,
      ),
      uri: uris,
    );
  }

  void doEmbed(List<Document> documents) async {
    await settings.vectorStore.addDocuments(documents: documents);
  }

  Future<List<Document>> doQuery(
    String query, {
    VectorStoreSimilaritySearch config = const VectorStoreSimilaritySearch(),
  }) {
    return settings.vectorStore.similaritySearch(query: query,config: config);
  }

  Future<List<Document>> load(File file) async {
    final extract = await UnnuDxl.instance.process(file.path);
    return extract
        .map((e) => Document(pageContent: e.text, metadata: e.metadata))
        .toList(growable: false);
  }

  void doDelete(String uri) {
    settings.uri.removeWhere(
      (element) => element.toString() == uri,
    );
  }
}
