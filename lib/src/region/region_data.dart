import 'dart:convert';

import '../data/province_list_data.dart';
import '../models/extra_gov_data.dart';
import 'region_info.dart';

/// 省市区扁平数据仓库。
///
/// 首次访问时懒加载内置的 [kProvinceListJson] 树形数据并拍平为
/// 省 / 市 / 区县 三张列表, 与 js 版模块加载时的预处理保持一致:
///
/// - 名字包含 `行政区划` 的虚拟市级节点 (如 `省直辖县级行政区划`)
///   会被其子节点替换提升为市级;
/// - 市级节点附带 [RegionInfo.provinceCode];
/// - 区县节点附带 [RegionInfo.provinceCode] 与 [RegionInfo.cityCode]。
class RegionData {
  RegionData._(this.provinces, this.cities, this.areas);

  /// 省级列表 (含直辖市、自治区、特别行政区, 共 34 个)。
  final List<RegionInfo> provinces;

  /// 市级列表。
  final List<RegionInfo> cities;

  /// 区县级列表。
  final List<RegionInfo> areas;

  static RegionData? _baseInstance;

  /// 内置基础数据 (单例, 懒加载)。
  static RegionData get base => _baseInstance ??= _build();

  /// 需要被提升为市级的虚拟节点关键字, 与 js 版 `filterCity` 一致。
  static const List<String> _virtualCityFilters = <String>['行政区划'];

  static RegionData _build() {
    final List<dynamic> rawTree =
        jsonDecode(kProvinceListJson) as List<dynamic>;

    final provinces = <RegionInfo>[];
    final cities = <RegionInfo>[];
    final areas = <RegionInfo>[];

    for (final dynamic provinceNode in rawTree) {
      final provinceCode = provinceNode['code'] as String;
      final provinceName = provinceNode['name'] as String;
      provinces.add(
        RegionInfo(code: provinceCode, name: provinceName),
      );

      final rawCities =
          (provinceNode['children'] as List<dynamic>?) ?? <dynamic>[];
      // 「省直辖县级行政区划」等虚拟市级节点: 用其子节点替换自身。
      final cityLevelNodes = <dynamic>[...rawCities.where(
        (dynamic city) => !_virtualCityFilters
            .any((String filter) => (city['name'] as String).contains(filter)),
      )];
      for (final dynamic city in rawCities) {
        final cityName = city['name'] as String;
        if (_virtualCityFilters.any(cityName.contains)) {
          cityLevelNodes.addAll(
            (city['children'] as List<dynamic>?) ?? <dynamic>[],
          );
        }
      }

      for (final dynamic cityNode in cityLevelNodes) {
        final cityCode = cityNode['code'] as String;
        final cityName = cityNode['name'] as String;
        cities.add(
          RegionInfo(
            code: cityCode,
            name: cityName,
            provinceCode: provinceCode,
          ),
        );

        final rawAreas =
            (cityNode['children'] as List<dynamic>?) ?? <dynamic>[];
        for (final dynamic areaNode in rawAreas) {
          areas.add(
            RegionInfo(
              code: areaNode['code'] as String,
              name: areaNode['name'] as String,
              cityCode: cityCode,
              provinceCode: provinceCode,
            ),
          );
        }
      }
    }

    return RegionData._(
      List.unmodifiable(provinces),
      List.unmodifiable(cities),
      List.unmodifiable(areas),
    );
  }

  /// 合并额外的自定义行政区划数据, 返回新的 [RegionData]。
  RegionData merge(ExtraGovData extra) => RegionData._(
        List.unmodifiable([...provinces, ...extra.province]),
        List.unmodifiable([...cities, ...extra.city]),
        List.unmodifiable([...areas, ...extra.area]),
      );
}
