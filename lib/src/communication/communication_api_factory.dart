library geiger_api;

import 'package:communicationapi/geiger_api.dart';

import 'communication_api.dart';
import 'declaration.dart';
import 'declaration_mismatch_exception.dart';
import 'geiger_api.dart';

final Map<String, GeigerApi> instances = {};

/// Creates or gets an instance.
///
/// Will only create one [LocalApi] instance per plugin id without guarantee
/// that this is the only instance since the [LocalApi] constructor cant be
/// private.
///
/// To stay compatible with the old Java API this is two methods in one.
///
/// - Provide an executor ([executorOrId]), [id], and [declaration] is provided
/// which creates a new instance in case none existing yet.
/// - Provide only an id ([executorOrId]) is provided and it just returns
/// the corresponding instance if it exists.
///
/// Throws [DeclarationMismatchException] if the plugin has been registered previously and the
/// declaration does not match and [StorageException] if registration failed.
Future<GeigerApi?> getGeigerApi(String executorOrId,
    [String? id, Declaration declaration = Declaration.doShareData]) async {
  if (id == null) {
    return instances[GeigerApi.MASTER_ID];
  }
  // synchronized(instances, {
  if (!instances.containsKey(id)) {
    CommunicationApi api = CommunicationApi(
        executorOrId, id, GeigerApi.MASTER_ID == id, declaration);
    instances[id] = api;
    await api.initialize();
  }
  // });
  GeigerApi l = instances[id]!;
  if (l.declaration != declaration) {
    throw DeclarationMismatchException();
  }
  return l;
}
