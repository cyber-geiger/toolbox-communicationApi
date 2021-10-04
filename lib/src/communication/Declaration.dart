/// The self declaration of the plugin.
enum Declaration {
  /// No data sharing is done and thus no implications on GDPR
  DO_NOT_SHARE_DATA,

  /// Data sharing is done. As a result only access to own objects (any TLP) is granted and to all
  /// objects of TLP:WHITE
  DO_SHARE_DATA
}

extension DeclarationExtension on Declaration {
  String getDeclaration() {
    switch (this) {
      case Declaration.DO_NOT_SHARE_DATA:
        return 'This plugin does not share any device, company, or user related '
            'data with or without consent to any party within or outside this device.';
      case Declaration.DO_SHARE_DATA:
        return 'This plugin does share device, company, or user related '
            'data with consent a other apps or parties within or outside this device.';
    }
  }
}
