import 'package:langchain/langchain.dart';
import 'package:langchain_core/documents.dart';
import 'package:langchain_core/embeddings.dart';


abstract class EmbeddingOptions extends BaseLangChainOptions {
  final int dimensions;
  final String? model;

  /// {@macro llm_options}
  const EmbeddingOptions({
    required this.dimensions,
    this.model,
    super.concurrencyLimit,
  });
}

final class UnnuEmbeddings implements Embeddings {

  final EmbeddingOptions? options;

  final Future<List<List<double>>> Function(
      List<Document> documents, {
      BaseLangChainOptions? config,
      }) doEmbed;

  final Future<List<double>> Function(
      String query, {
      BaseLangChainOptions? config,
      }) doQuery;

  const UnnuEmbeddings._(
      this.doEmbed,
      this.doQuery,
      this.options
  );

  @override
  Future<List<List<double>>> embedDocuments(
      final List<Document> documents,
      ) async {

    return doEmbed(documents, config: options);
  }

  @override
  Future<List<double>> embedQuery(String query) async {
    return doQuery(query, config: options);
  }
}

class UnnuknowSimilaritySearch extends VectorStoreSimilaritySearch {
  /// {@macro chroma_similarity_search}
  const UnnuknowSimilaritySearch({
    super.k = 4,
    final Map<String, dynamic>? where,
    this.whereDocument,
    super.scoreThreshold,
  }) : super(filter: where);

  /// Optional query condition to filter results based on document content.
  final Map<String, dynamic>? whereDocument;
}

final class UnnuVectorStore extends VectorStore {
  final Uri corpus;

  UnnuVectorStore({
  required this.corpus,
  required super.embeddings,
  });

  @override
  Future<List<String>> addVectors({required List<List<double>> vectors, required List<Document> documents}) {
    // TODO: implement addVectors
    throw UnimplementedError();
  }

  @override
  Future<void> delete({required List<String> ids}) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<List<(Document, double)>> similaritySearchByVectorWithScores({required List<double> embedding, VectorStoreSimilaritySearch config = const VectorStoreSimilaritySearch()}) {
    // TODO: implement similaritySearchByVectorWithScores
    throw UnimplementedError();
  }
  
}

