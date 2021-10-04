import 'dart:collection';

import 'Declaration.dart';
import 'DeclarationMismatchException.dart';
import 'LocalApi.dart';

/// Implements a singleton pattern for local API.
class LocalApiFactory {
  static final String MASTER_EXECUTOR = 'FIXME';

  static final Map<String, LocalApi> instances = HashMap();

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
  static LocalApi? getLocalApi(String executorOrId,
      [String? id, Declaration? declaration]) {
    if (id == null) {
      return instances[id];
    }
    // synchronized(instances, {
    if (!instances.containsKey(id)) {
      instances[id] =
          LocalApi(executorOrId, id, LocalApi.MASTER == id, declaration);
    }
    // });
    var l = instances[id]!;
    if ((declaration != null) && (l.getDeclaration() != declaration)) {
      throw DeclarationMismatchException();
    }
    return l;
  }
}
