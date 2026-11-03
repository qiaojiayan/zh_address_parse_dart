/// 字段标签提取: 从原始地址中按标签切出「详细地址」原文。
///
/// 清洗管线会把标点替换为空格、剥离关键字, 这会破坏详细地址的
/// 原始内容 (如括号、逗号、「别打电话」等托付语)。当地址带有
/// `详细地址：` / `收货地址：` / `地址：` 标签时, 直接从原文切片,
/// 仅剔除其中混入的电话 / 邮编 / 省市区名 / 姓名。
library;

/// 详细地址标签 (长词优先匹配)。
const List<String> _detailLabels = <String>[
  '详细地址',
  '收货地址',
  '收件地址',
  '地址',
];

/// 其他字段标签, 用于确定详细地址内容的结束边界 (长词优先)。
const List<String> _otherFieldLabels = <String>[
  '联系电话',
  '联系人手机号码',
  '手机号码',
  '手机号',
  '手机',
  '电话',
  '邮政编码',
  '邮编',
  '所在地区',
  '详细地址',
  '收货地址',
  '收件地址',
  '地址',
  '收货人',
  '收件人',
  '联系人',
  '姓名',
];

final RegExp _detailLabelRegExp =
    RegExp('(?:${_detailLabels.join('|')})[：:]');

final RegExp _nextFieldLabelRegExp =
    RegExp('(?:${_otherFieldLabels.join('|')})[：:]');

/// 详细地址内容的首尾可剔除的分隔符。
const String _separatorChars = ' \t，,、;；:：-';

/// 从原始地址中提取「详细地址：」等标签后的内容, 原样保留。
///
/// - 标签必须带 `：` / `:` 分隔符 (强信号);
/// - 内容到「行尾」或同一行内「下一个字段标签」为止
///   (注意 `别打电话)` 中的 `电话` 后面没有冒号, 不会被误当作标签边界);
/// - 逐行查找, 返回第一个非空内容; 找不到返回 `null`。
String? extractLabelledDetail(String address) {
  final lines = address.split(RegExp(r'[\r\n]'));
  for (final line in lines) {
    final labelMatch = _detailLabelRegExp.firstMatch(line);
    if (labelMatch == null) {
      continue;
    }
    var content = line.substring(labelMatch.end);
    final next = _nextFieldLabelRegExp.firstMatch(content);
    if (next != null) {
      content = content.substring(0, next.start);
    }
    content = trimSeparators(content);
    if (content.isNotEmpty) {
      return content;
    }
  }
  return null;
}

/// 去掉首尾的空白与常见分隔符 (逗号 / 顿号 / 冒号 / 横线等)。
String trimSeparators(String text) {
  var start = 0;
  var end = text.length;
  while (start < end && _separatorChars.contains(text[start])) {
    start++;
  }
  while (end > start && _separatorChars.contains(text[end - 1])) {
    end--;
  }
  return text.substring(start, end);
}

/// 从详细地址原文中剔除电话 (兼容 `+86` / `86-` 前缀与 `138-1234-5678`
/// 这类数字间带分隔符的写法)。
String stripPhoneFromDetail(String detail, String phone) {
  if (phone.isEmpty || detail.isEmpty) {
    return detail;
  }
  // 数字之间允许穿插空格 / 中划线
  final flexible = phone.split('').join('[ -]*');
  detail = detail.replaceAll(RegExp(r'(?:\+?86|17951)?[ -]*' + flexible), '');
  return detail;
}

/// 从详细地址原文中剔除省市区名。
///
/// 原文中行政区划可能是简称 (如 `四川` 而非 `四川省`、`北京` 而非
/// `北京市`), 因此对每个区划名按「最长前缀优先」尝试剔除。
String stripRegionNamePrefixes(String detail, List<String> regionNames) {
  for (final name in regionNames) {
    for (var len = name.length; len >= 2; len--) {
      final prefix = name.substring(0, len);
      if (detail.contains(prefix)) {
        detail = detail.replaceAll(prefix, '');
        break;
      }
    }
  }
  return detail;
}
