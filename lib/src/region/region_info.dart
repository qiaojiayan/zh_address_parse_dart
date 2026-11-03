/// 行政区划节点信息。
///
/// 对应 js 版数据结构: `{ code, name, provinceCode?, cityCode? }`。
/// [code] 为 6 位行政区划代码; 市级节点带 [provinceCode],
/// 区县级节点带 [provinceCode] 与 [cityCode]。
class RegionInfo {
  /// 行政区划代码。
  final String code;

  /// 行政区划名称。
  final String name;

  /// 所属省级代码 (省级行点为 `null`)。
  final String? provinceCode;

  /// 所属市级代码 (省级、市级节点为 `null`)。
  final String? cityCode;

  /// 创建行政区划节点。
  const RegionInfo({
    required this.code,
    required this.name,
    this.provinceCode,
    this.cityCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionInfo &&
          other.code == code &&
          other.name == name &&
          other.provinceCode == provinceCode &&
          other.cityCode == cityCode;

  @override
  int get hashCode =>
      Object.hash(code, name, provinceCode, cityCode);

  @override
  String toString() {
    final suffix = <String>[
      if (provinceCode != null) 'provinceCode: $provinceCode',
      if (cityCode != null) 'cityCode: $cityCode',
    ].join(', ');
    return 'RegionInfo(code: $code, name: $name${suffix.isEmpty ? '' : ', $suffix'})';
  }
}
