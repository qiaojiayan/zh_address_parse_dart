import '../region/region_info.dart';

/// 额外补充的行政区划数据。
///
/// 对应 js 版 `AddressParse(address, { extraGovData })` 参数,
/// 用于在内置省市区数据之外补充自定义行政区划 (例如新增的区县)。
class ExtraGovData {
  /// 额外的省级数据。
  final List<RegionInfo> province;

  /// 额外的市级数据。
  final List<RegionInfo> city;

  /// 额外的区县级数据。
  final List<RegionInfo> area;

  /// 创建额外行政区划数据。
  const ExtraGovData({
    this.province = const <RegionInfo>[],
    this.city = const <RegionInfo>[],
    this.area = const <RegionInfo>[],
  });

  /// 是否没有任何补充数据。
  bool get isEmpty =>
      province.isEmpty && city.isEmpty && area.isEmpty;
}
