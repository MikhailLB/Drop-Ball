import '../../core/byte_mask.dart';

const List<int> _privacyMask = [122, 187, 254, 186, 71, 239, 134, 192, 31, 194, 142, 110, 133, 138, 91, 57, 139, 222, 168, 227, 20, 224, 186, 152, 126, 239, 78, 153, 196, 23, 58, 225, 195, 66, 14, 78, 82, 25, 19, 63, 227, 73, 103];
const List<int> _supportMask  = [122, 187, 254, 186, 71, 239, 134, 192, 31, 194, 142, 110, 133, 138, 91, 57, 139, 222, 168, 227, 20, 224, 186, 152, 125, 232, 87, 159, 202, 6, 55, 226, 219, 89, 15, 75];

String get brandPrivacyUrl => decode(_privacyMask);
String get brandSupportUrl  => decode(_supportMask);
