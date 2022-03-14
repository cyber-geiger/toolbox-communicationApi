library geiger_api;

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

final Map<String, GeigerApi> instances = {};

void flushGeigerApiCache() {
  instances.clear();
}

/// Creates or gets an instance.
///
/// Will only create one [GeigerApi] instance per plugin id without guarantee
/// that this is the only instance since the [GeigerApi] constructor cant be
/// private.
///
/// To stay compatible with the old Java API this is two methods in one.
///
/// - Provide an executor ([executorOrId]), [id], and [declaration] to
/// create a new instance in case none existing yet.
/// - Provide only an id ([executorOrId]) return
/// the corresponding instance if it exists.
///
/// Throws [DeclarationMismatchException] if the plugin has been registered previously and the
/// declaration does not match and [StorageException] if registration failed.
Future<GeigerApi?> getGeigerApi(String executorOrId,
    [String? id, Declaration declaration = Declaration.doShareData]) async {
  if (id == null) {
    id = executorOrId;
    executorOrId = '';
  }
  if (!instances.containsKey(id)) {
    await StorageMapper.initDatabaseExpander();
    CommunicationApi api = CommunicationApi(
        executorOrId, id, GeigerApi.masterId == id, declaration);
    instances[id] = api;
    await api.initialize();
  }
  GeigerApi l = instances[id]!;
  if (l.declaration != declaration) {
    throw DeclarationMismatchException();
  }
  return l;
}
