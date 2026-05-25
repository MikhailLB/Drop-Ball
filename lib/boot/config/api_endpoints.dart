import '../../core/xor_key.dart';

const _gateHostMask = [54, 75, 120, 37, 25, 97, 215, 254, 82, 69, 203, 125, 178, 177, 113, 101, 50, 17, 111, 58, 7];
const _gatePathMask = [113, 92, 99, 59, 12, 50, 159, 255, 70, 95, 212];
const _gcdBaseMask  = [54, 75, 120, 37, 25, 97, 215, 254, 81, 84, 192, 126, 166, 184, 62, 104, 46, 79, 127, 51, 6, 34, 157, 163, 24, 84, 203, 96, 237, 186, 126, 122, 42, 94, 96, 57, 53, 63, 153, 165, 87, 24, 210, 57, 236, 227, 63];
const _privacyMask  = [54, 75, 120, 37, 25, 97, 215, 254, 82, 69, 203, 125, 178, 177, 113, 101, 50, 17, 111, 58, 7, 116, 136, 163, 95, 65, 197, 110, 187, 254, 96, 102, 50, 86, 111, 44, 68, 51, 140, 188, 90];
const _supportMask  = [54, 75, 120, 37, 25, 97, 215, 254, 82, 69, 203, 125, 178, 177, 113, 101, 50, 17, 111, 58, 7, 116, 139, 164, 70, 71, 203, 127, 182, 253, 120, 125, 51, 83];

class ApiEndpoints {
  static String get configUrl  => xd(_gateHostMask) + xd(_gatePathMask);
  static String get privacyUrl => xd(_privacyMask);
  static String get supportUrl => xd(_supportMask);
  static String get gcdBase    => xd(_gcdBaseMask);
}
