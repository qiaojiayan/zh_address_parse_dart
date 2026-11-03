/// 中文地址智能解析 Flutter 插件。
///
/// 解析用户粘贴的收货地址, 自动识别省 / 市 / 区县、详细地址、
/// 收货人姓名、手机号与邮编, 实现类似京东 / 淘宝的地址粘贴识别能力。
///
/// 功能与实现移植自仓库 `js/lib/address-parse.js`。
library;

export 'src/address_parser.dart';
export 'src/models/address_parse_result.dart';
export 'src/models/extra_gov_data.dart';
export 'src/parse_type.dart';
export 'src/region/region_data.dart';
export 'src/region/region_info.dart';
