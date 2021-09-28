import 'dart:collection';

import 'Declaration.dart';
import 'DeclarationMismatchException.dart';
import 'LocalApi.dart';

/// <p>Implements a singleton pattern for local API.</p>
class LocalApiFactory {
  static final Map<String, LocalApi> instances = HashMap();

  /// <p>Creates one instance only per id, but cannot guarantee it since LocalApi constructor cant be
  /// private.</p>
  /// @param executor    the executor string required to run the plugin (may be platform dependant) or id the id to be retrieved
  /// @param id          the id of the API to be retrieved
  /// @param declaration the privacy declaration
  /// @return the instance requested
  /// @throws DeclarationMismatchException if the plugin has been registered previously and the
  /// declaration does not match
  /// @throws StorageException             if registration failed
  static LocalApi? getLocalApi(String executorOrId,
      [String? id, Declaration? declaration]) {
    if (id == null) {
      return instances[id];
    }
    // synchronized(instances, {
    if (!instances.containsKey(id)) {
      if (LocalApi.MASTER == id) {
        instances[id] = LocalApi(executorOrId, id, true, declaration);
      } else {
        instances[id] = LocalApi(executorOrId, id, false, declaration);
      }
    }
    // });
    var l = instances[id]!;
    if ((declaration != null) && (l.getDeclaration() != declaration)) {
      throw DeclarationMismatchException();
    }
    return l;
  }
}
