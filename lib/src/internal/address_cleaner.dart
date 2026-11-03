/// 地址清洗、手机号 / 邮编提取、分割排序等工具。
///
/// 内部实现, 移植自 js 版 `cleanAddress` / `filterPhone` /
/// `filterPostalCode` / `sortAddress`。
library;

/// 纯数字正则。
final RegExp pureDigitsRegExp = RegExp(r'^\d+$');

final RegExp _multiSpaceRegExp = RegExp(r' {2,}');

/// 标点符号清洗正则 (中英文), 与 js 版字符集一致。
final RegExp _punctuationRegExp = RegExp(
  r'''[`~!@#$^&*()=|{}':;',\[\]\.<>/?~！@#￥……&*（）——|{}【】‘；：”“’。，、？]''',
);

/// 默认清洗关键字, 与 js 版保持一致。
const List<String> _defaultCleanKeywords = <String>[
  '详细地址',
  '收货地址',
  '收件地址',
  '地址',
  '所在地区',
  '姓名',
  '收货人',
  '收件人',
  '联系人',
  '收',
  '邮编',
  '联系电话',
  '电话',
  '联系人手机号码',
  '手机号码',
  '手机号',
  '自治区直辖县级行政区划',
  '省直辖县级行政区划',
];

/// 常见电话托付语, 在通用关键字清洗前整句剔除,
/// 避免残片 (如 `勿打`) 被误拼进详细地址或误判为姓名。
/// 注意: 带有「详细地址：」等标签时详细地址从原文切片,
/// 不经过此清洗, 托付语仍会原样保留。
final List<String> _phoneCommissionPhrases = <String>[
  '不方便接听电话',
  '不便接听电话',
  '拒绝接听电话',
  '不要打电话',
  '请勿打电话',
  '先别打电话',
  '勿打电话',
  '别打电话',
  '不方便接听',
  '拒接电话',
  '拒接来电',
  '请勿来电',
  '勿来电',
  '请勿打扰',
]..sort((a, b) => b.length.compareTo(a.length));

/// 直辖市列表, 用于合并 `北京北京` -> `北京` 这类重复粘贴。
const List<String> _municipalities = <String>['北京', '上海', '天津', '重庆'];

/// 地址清洗: 去换行 / 制表符、关键字、标点、多余空格, 合并直辖市区。
String cleanAddress(String address, List<String> textFilter) {
  // 去换行等
  address = address
      .replaceAll('\r\n', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\t', ' ');

  // 先整句剔除电话托付语, 再走通用关键字清洗
  for (final phrase in _phoneCommissionPhrases) {
    address = address.replaceAll(phrase, ' ');
  }

  // 内置 + 自定义关键字
  for (final keyword in [..._defaultCleanKeywords, ...textFilter]) {
    address = address.replaceAll(keyword, ' ');
  }

  // 标点替换为空格
  address = address.replaceAll(_punctuationRegExp, ' ');

  // 多个空格 replace 为一个
  address = address.replaceAll(_multiSpaceRegExp, ' ');

  // 适配直辖市区: `北京北京` -> `北京` (仅第一处, 与 js 版一致)
  for (final municipality in _municipalities) {
    address = address.replaceFirst(municipality + municipality, municipality);
  }
  return address;
}

final RegExp _phoneDashRegExp = RegExp(r'(\d{3})-(\d{4})-(\d{4})');
final RegExp _phoneSpace3RegExp = RegExp(r'(\d{3}) (\d{4}) (\d{4})');
final RegExp _phoneSpace4RegExp = RegExp(r'(\d{4}) (\d{4}) (\d{4})');

/// 手机号识别正则, 与 js 版一致。
final RegExp _mobileRegExp = RegExp(
  r'(0|\+?86-?|17951|)?1[3456789]\d{9}(-\d{4})?',
);

/// `+86` / `86-` 前缀剥离正则。
final RegExp _phonePrefixRegExp = RegExp(r'^\+?86-?');

/// 匹配电话, 返回 `(清洗后的地址, 手机号)`。
(String, String) filterPhone(String address) {
  // 整理电话格式 (注: js 版第 3 条替换存在 `$2/$3` 未分组的笔误,
  // 此处按其本意实现为直接拼接)
  address = address.replaceAllMapped(
    _phoneDashRegExp,
    (Match m) => '${m[1]}${m[2]}${m[3]}',
  );
  address = address.replaceAllMapped(
    _phoneSpace3RegExp,
    (Match m) => '${m[1]}${m[2]}${m[3]}',
  );
  address = address.replaceAllMapped(
    _phoneSpace4RegExp,
    (Match m) => '${m[1]}${m[2]}${m[3]}',
  );

  var phone = '';
  final match = _mobileRegExp.firstMatch(address);
  if (match != null) {
    phone = match.group(0)!;
    address = address.replaceFirst(phone, ' ');
  }
  return (address, phone.replaceFirst(_phonePrefixRegExp, ''));
}

/// 邮编识别正则, 与 js 版一致。
final RegExp _postalCodeRegExp = RegExp(r'[1-9]\d{5}(?!\d)');

/// 匹配邮编, 返回 `(邮编, 清洗后的地址)`。
(String, String) filterPostalCode(String address) {
  final match = _postalCodeRegExp.firstMatch(address);
  if (match == null) {
    return ('', address);
  }
  final postalCode = match.group(0)!;
  return (postalCode, address.replaceFirst(postalCode, ' '));
}

/// 按照省市区县镇排序, 与 js 版 `sortAddress` 一致。
List<String> sortAddress(List<String> splitAddress) {
  final rest = [...splitAddress];
  final result = <String>[];
  for (final keyword in const <String>['省', '市', '区', '县', '镇']) {
    final index = rest.indexWhere((e) => e.contains(keyword));
    if (index >= 0) {
      result.add(rest.removeAt(index));
    }
  }
  return [...result, ...rest];
}

/// 去重并保持原始顺序。
List<String> deduplicate(List<String> list) {
  final seen = <String>{};
  final result = <String>[];
  for (final item in list) {
    if (seen.add(item)) {
      result.add(item);
    }
  }
  return result;
}
