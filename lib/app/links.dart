import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The privacy policy also linked from the Play Store listing.
const privacyPolicyUrl =
    'https://docs.google.com/document/d/e/2PACX-1vThShJcW6Cd5rL2D4YjGwHtiOAOQaGpEQj0L2Um1Sfuaxfkcstuh8BcbPoe9Aau8vN7ybogQe26SrUu/pub';

const _channel = MethodChannel('alarmin/system');

/// Opens [url] in the browser. Returns false if nothing could open it.
Future<bool> openUrl(String url) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await _channel.invokeMethod<bool>('openUrl', url) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
