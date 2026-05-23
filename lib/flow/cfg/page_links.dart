import '../../core/byte_mask.dart';

// Privacy and support URLs encoded with DropBall seed.
// Run tool/encode_keys.dart to regenerate if URLs change.
const List<int> _privacyMask = <int>[]; // TODO: encode privacy URL
const List<int> _supportMask = <int>[]; // TODO: encode support URL

// Fallback plaintext URLs used when byte arrays are empty (dev builds).
const _privacyFallback = 'https://dropballneonedition.com/privacy-policy.html';
const _supportFallback  = 'https://dropballneonedition.com/support.html';

String get brandPrivacyUrl =>
    _privacyMask.isEmpty ? _privacyFallback : decode(_privacyMask);

String get brandSupportUrl =>
    _supportMask.isEmpty ? _supportFallback : decode(_supportMask);
