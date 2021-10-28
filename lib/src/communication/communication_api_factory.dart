library geiger_api;

import 'communication_api.dart';
import 'declaration.dart';
import 'declaration_mismatch_exception.dart';
import 'geiger_api.dart';

const String MASTER_EXECUTOR = 'FIXME';

const Map<String, GeigerApi> instances = <String, GeigerApi>{};

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
GeigerApi? getGeigerApi(String executorOrId,
    [String? id, Declaration declaration=Declaration.DO_SHARE_DATA]) {
  if (id == null) {
    return instances[id];
  }
  // synchronized(instances, {
  if (!instances.containsKey(id)) {
    instances[id] =
        CommunicationApi(executorOrId, id, GeigerApi.MASTER == id, declaration);
  }
  // });
  GeigerApi l = instances[id]!;
  if ((declaration != null) && (l.declaration != declaration)) {
    throw DeclarationMismatchException();
  }
  return l;
}
