import '../data/surname_data.dart';

/// 姓名识别, 移植自 js 版 `judgeFragmentIsName` 及主流程中的姓名提取逻辑。

final RegExp _chineseRegExp = RegExp('[\u4E00-\u9FA5]');

/// 认为是姓名的称呼关键字, 可自行添加。
const List<String> _nameCallList = <String>[
  '先生',
  '小姐',
  '同志',
  '哥哥',
  '姐姐',
  '妹妹',
  '弟弟',
  '妈妈',
  '爸爸',
  '爷爷',
  '奶奶',
  '姑姑',
  '舅舅',
];

/// 排除是姓名的关键字。
const List<String> _townFilterList = <String>[
  '街道',
  '乡镇',
  '镇',
  '乡',
];

/// 判断片段是否是姓名 (对应 js 版 `judgeFragmentIsName`)。
bool judgeFragmentIsName(String fragment, int nameMaxLength) {
  if (fragment.isEmpty || !_chineseRegExp.hasMatch(fragment)) {
    return false;
  }

  // 如果包含称呼关键字, 则认为是名字
  if (_nameCallList.any(fragment.contains)) {
    return true;
  }

  // 包含乡镇街道等关键字则不是名字
  if (_townFilterList.any(fragment.contains)) {
    return false;
  }

  // 百家姓里面能找到这个姓, 并且长度在 2 ~ nameMaxLength 之间
  final nameFirst = fragment.substring(0, 1);
  if (fragment.length <= nameMaxLength &&
      fragment.length > 1 &&
      kSurnames.contains(nameFirst)) {
    return true;
  }
  return false;
}

/// 从详细地址列表中识别收货人姓名。
///
/// 按长度升序排列后从最短的开始找名字;
/// 没找到的话就看第一个片段是不是 (长度 <= [nameMaxLength] 且包含中文)。
/// 返回识别出的姓名, 未识别返回 `null`。
String? extractName(List<String> detailList, int nameMaxLength) {
  if (detailList.isEmpty) {
    return null;
  }

  final copyDetail =
      detailList.where((String item) => item.isNotEmpty).toList();
  if (copyDetail.isEmpty) {
    return null;
  }

  // 按长度稳定升序 (js 版 Array.sort 在现代引擎中为稳定排序)
  final sortedEntries = copyDetail.asMap().entries.toList()
    ..sort((a, b) {
      final compare = a.value.length.compareTo(b.value.length);
      return compare != 0 ? compare : a.key.compareTo(b.key);
    });
  final sortedCopy = sortedEntries.map((e) => e.value).toList();

  // 排序后从最短的开始找名字, 没找到的话就看第一个是不是咯
  final index = sortedCopy
      .indexWhere((String item) => judgeFragmentIsName(item, nameMaxLength));
  if (index >= 0) {
    return sortedCopy[index];
  }
  if (sortedCopy.first.length <= nameMaxLength &&
      _chineseRegExp.hasMatch(sortedCopy.first)) {
    return sortedCopy.first;
  }
  return null;
}

/// 姓名标签, 例如 `收货人：张三`。
const List<String> _nameLabels = <String>[
  '收货人',
  '收件人',
  '联系人',
  '姓名',
];

/// 标签后捕获到的内容包含这些词时, 认为不是姓名而是别的字段。
const List<String> _labelNameBlacklist = <String>[
  '电话',
  '手机',
  '号码',
  '地址',
  '邮编',
  '地区',
  '姓名',
  '收货',
  '收件',
  '签收',
  '代收',
  '驿站',
  '菜鸟',
  '丰巢',
  '快递',
];

/// 优先从「收货人：/收件人：/联系人：/姓名：」标签中直接提取姓名。
///
/// 这是比启发式猜测更强的信号 (京东 / 淘宝复制的地址通常都带标签),
/// 提取失败时回退到 [extractName] 的启发式逻辑。
///
/// - 带 `：` / `:` 分隔符的标签视为强信号, 捕获后面的中文姓名
///   (长度 2 ~ [nameMaxLength], 且后面不能紧跟其他中文字符);
/// - 不带分隔符的标签视为弱信号, 捕获结果还需通过
///   [judgeFragmentIsName] 校验 (避免把 `联系人驿站` 之类的下一字段当成姓名);
/// - 捕获内容命中 [_labelNameBlacklist] (如 `联系人：手机号码...`) 时跳过。
String? extractLabelledName(String address, int nameMaxLength) {
  if (nameMaxLength < 2) {
    return null;
  }
  final raw = address.replaceAll(RegExp(r'[\r\n\t]'), ' ');

  // 1) 强信号: 标签后带分隔符
  final labelled = RegExp(
    '(?:${_nameLabels.join('|')})[：:]\\s*'
    '([\\u4E00-\\u9FA5]{2,$nameMaxLength})(?![\\u4E00-\\u9FA5])',
  ).firstMatch(raw);
  if (labelled != null) {
    final candidate = labelled.group(1)!;
    if (!_labelNameBlacklist.any(candidate.contains)) {
      return candidate;
    }
  }

  // 2) 弱信号: 标签后不带分隔符, 需通过姓名校验
  final glued = RegExp(
    '(?:${_nameLabels.join('|')})'
    '([\\u4E00-\\u9FA5]{2,$nameMaxLength})(?![\\u4E00-\\u9FA5])',
  ).firstMatch(raw);
  if (glued != null) {
    final candidate = glued.group(1)!;
    if (!_labelNameBlacklist.any(candidate.contains) &&
        judgeFragmentIsName(candidate, nameMaxLength)) {
      return candidate;
    }
  }
  return null;
}
