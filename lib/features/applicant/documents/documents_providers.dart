import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_model.dart';
import 'documents_repository.dart';

class DocumentsQueryNotifier extends Notifier<DocumentsQuery> {
  @override
  DocumentsQuery build() => const DocumentsQuery();
  void update(DocumentsQuery query) => state = query;
}

final documentsQueryProvider =
    NotifierProvider.autoDispose<DocumentsQueryNotifier, DocumentsQuery>(
      DocumentsQueryNotifier.new,
    );

class DocumentsList {
  const DocumentsList(this.result, {this.loadingMore = false, this.moreError});
  final DocumentsPage result;
  final bool loadingMore;
  final Object? moreError;
}

class DocumentFilterCounts {
  const DocumentFilterCounts({
    required this.all,
    required this.cv,
    required this.coverLetter,
  });

  final int all;
  final int cv;
  final int coverLetter;

  int forType(DocumentType? type) => switch (type) {
    null => all,
    DocumentType.cv => cv,
    DocumentType.coverLetter => coverLetter,
  };
}

final documentFilterCountsProvider = FutureProvider.autoDispose
    .family<DocumentFilterCounts, String>((ref, search) async {
      final repository = ref.watch(documentsRepositoryProvider);
      final counts = await Future.wait([
        repository.count(DocumentsQuery(search: search)),
        repository.count(DocumentsQuery(type: DocumentType.cv, search: search)),
        repository.count(
          DocumentsQuery(type: DocumentType.coverLetter, search: search),
        ),
      ]);
      return DocumentFilterCounts(
        all: counts[0],
        cv: counts[1],
        coverLetter: counts[2],
      );
    }, retry: (_, _) => null);

class DocumentsNotifier extends AsyncNotifier<DocumentsList> {
  int _generation = 0;
  @override
  Future<DocumentsList> build() async {
    _generation++;
    final query = ref.watch(documentsQueryProvider);
    return DocumentsList(
      await ref.watch(documentsRepositoryProvider).list(query, 1),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (state.isLoading ||
        current == null ||
        current.loadingMore ||
        current.result.page >= current.result.totalPages) {
      return;
    }
    final generation = _generation;
    final query = ref.read(documentsQueryProvider);
    state = AsyncData(DocumentsList(current.result, loadingMore: true));
    try {
      final next = await ref
          .read(documentsRepositoryProvider)
          .list(query, current.result.page + 1);
      if (!ref.mounted ||
          generation != _generation ||
          !identical(query, ref.read(documentsQueryProvider))) {
        return;
      }
      final ids = current.result.items.map((e) => e.id).toSet();
      state = AsyncData(
        DocumentsList(
          DocumentsPage(
            items: [
              ...current.result.items,
              ...next.items.where((e) => ids.add(e.id)),
            ],
            page: next.page,
            limit: next.limit,
            total: next.total,
            totalPages: next.totalPages,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted &&
          generation == _generation &&
          identical(query, ref.read(documentsQueryProvider))) {
        state = AsyncData(DocumentsList(current.result, moreError: error));
      }
    }
  }
}

final documentsProvider =
    AsyncNotifierProvider.autoDispose<DocumentsNotifier, DocumentsList>(
      DocumentsNotifier.new,
      retry: (_, _) => null,
    );
