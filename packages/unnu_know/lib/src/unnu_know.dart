part of '../unnu_know.dart';

class DocumentMapping {
  final String id;
  final String uri;
  DocumentMapping({
    required this.id,
    required this.uri,
  });

  DocumentMapping copyWith({
    String? id,
    String? uri,
  }) {
    return DocumentMapping(
      id: id ?? this.id,
      uri: uri ?? this.uri,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'uri': uri});

    return result;
  }

  factory DocumentMapping.fromMap(Map<String, dynamic> map) {
    return DocumentMapping(
      id: (map['id'] ?? '') as String,
      uri: (map['uri'] ?? '') as String,
    );
  }

  @override
  String toString() => 'DocumentMapping(id: $id, uri: $uri)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DocumentMapping && other.id == id && other.uri == uri;
  }

  @override
  int get hashCode => id.hashCode ^ uri.hashCode;
}

final class UnnuKnow {
  final UnnuCorpusController corpusController = June.getState(
    UnnuCorpusController.new,
  );

  final ChatSettingsController settingsController = June.getState(
    ChatSettingsController.new,
  );

  int limit = 4;

  StreamSubscription<AttachmentUpdate>? subscription;

  UnnuKnow._();

  static final UnnuKnow _singleton = UnnuKnow._();

  static UnnuKnow get instance => _singleton;

  final StreamController<AttachmentUpdate> listener =
      StreamController<AttachmentUpdate>(sync: true);

  void init() {
    subscription ??= listener.stream.listen(
      (event) async {
        if (event.status == AttachmentStatus.NEW) {
          await addDocument(event);
        } else if (event.status == AttachmentStatus.REMOVE) {
          delete(event);
        }
      },
    );
  }

  Future<void> addDocument(AttachmentUpdate update) async {
    if (!corpusController.settings.uri.contains(update.attachment.uri)) {
      final filePath = update.attachment.uri.toFilePath(windows: Platform.isWindows);
      final result = await corpusController.load(
        File(filePath),
      );
      // RagLite.instance.enableParagraphChunking(p.extension(filePath) == '.docx');
      AttachmentsMonitor.sendStatus((
        status: AttachmentStatus.PARSE,
        attachment: ChatAttachmentView(
          uri: update.attachment.uri,
          sessionId: update.attachment.sessionId,
          id: {ChatSettingsController.uuid.v7()},
        ),
      ));

      final listOfEmbeddings = <List<double>>[];
      final listOfDocs = <Document>[];
      final listIds = <String>[];
      final mappings = <DocumentMapping>[];

      final embeddings =  result.where((element) => element.pageContent.isNotEmpty);

      for(final element in embeddings) {
        final ragVectors =
            await RagLite.instance.embed(element.pageContent).toList();
        final listOfRagVectors = ragVectors.where(
          (element) => element.type == RagEmbeddingVectorType.EMBEDDING,
        );
        final docIds = ragVectors
            .where(
              (element) => element.type == RagEmbeddingVectorType.ID,
            )
            .map(
              (e) => e.documentId,
            );
        listIds.addAll(docIds);
        for (final embd in listOfRagVectors) {
          mappings.add(
            DocumentMapping(
              id: embd.documentId,
              uri: update.attachment.uri.toString(),
            ),
          );
          listOfEmbeddings.add(embd.embeddings);
          final metadata = {...element.metadata};
          listOfDocs.add(
            Document(
              pageContent: embd.document,
              id: embd.documentId,
              metadata: metadata,
            ),
          );
        }
      }

      for (final m in mappings.toSet()) {
        RagLite.instance.addMapping(m.uri, m.id);
      }
      await corpusController.settings.vectorStore.addVectors(
        vectors: listOfEmbeddings,
        documents: listOfDocs,
      );

      corpusController.settings = corpusController.settings.copyWith(
        uri: { ...corpusController.settings.uri, update.attachment.uri}
      );
      corpusController.setState();

      AttachmentsMonitor.sendStatus((
        status: AttachmentStatus.PROCESSED,
        attachment: ChatAttachmentView(
          uri: update.attachment.uri,
          sessionId: update.attachment.sessionId,
          id: listIds.toSet(),
        ),
      ));
    } else {
      AttachmentsMonitor.sendStatus((
      status: AttachmentStatus.COMPLETED,
      attachment: update.attachment,
      ));
    }
  }

  Future<List<Document>> search(String query) async {
    return corpusController.doQuery(
      query,
      config: VectorStoreSimilaritySearch(k: limit)
    );
  }

  static void delete(AttachmentUpdate update) {
    final uri = update.attachment.uri.toString();
    for (final id in update.attachment.id) {
      RagLite.instance.deleteEmbedding(uri, id);
    }
    AttachmentsMonitor.sendStatus((
      status: AttachmentStatus.COMPLETED,
      attachment: ChatAttachmentView(
        uri: update.attachment.uri,
        sessionId: update.attachment.sessionId,
        id: update.attachment.id,
      ),
    ));
  }
}
