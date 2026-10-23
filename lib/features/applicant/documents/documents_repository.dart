import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'document_model.dart';
import 'documents_constants.dart';

class DocumentsRepository {
  DocumentsRepository(this.client);
  final ApiClient client;
  Future<DocumentsPage> list(DocumentsQuery query, int page) async {
    final response = await client.get<Map<String, Object?>>(
      DocumentConstants.path,
      queryParameters: query.parameters(page),
    );
    return DocumentsPage.fromJson(response.data!);
  }
}

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(apiClientProvider)),
);
