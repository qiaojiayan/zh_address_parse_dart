import '../region/region_data.dart';
import '../region/region_info.dart';

/// 省市区匹配, 移植自 js 版 `parseRegionWithRegexp` 与 `parseRegion`。
///
/// 内部实现, 不对外导出。

/// 单个地址片段解析出的省市区与详细地址。
class RegionParseResult {
  const RegionParseResult(
    this.province,
    this.city,
    this.area,
    this.detail,
  );

  /// 识别出的省级节点, 未识别为 `null`。
  final RegionInfo? province;

  /// 识别出的市级节点, 未识别为 `null`。
  final RegionInfo? city;

  /// 识别出的区县级节点, 未识别为 `null`。
  final RegionInfo? area;

  /// 剩余的详细地址片段。
  final List<String> detail;
}

/// 利用「前缀唯一匹配」解析省市区 (js 版 `type = 0`)。
///
/// js 中通过在 JSON 字符串上做正则实现, 此处等价改为在扁平列表上筛选:
/// 取地址片段逐级增长的前缀, 在对应层级列表中查找唯一匹配项。
RegionParseResult parseRegionWithRegexp(
  String fragment,
  RegionInfo? province,
  RegionInfo? city,
  RegionInfo? area,
  RegionData data,
) {
  final detail = <String>[];
  var matchStr = '';

  if (province == null) {
    for (var len = 2; len <= fragment.length; len++) {
      final prefix = fragment.substring(0, len);
      final candidates = data.provinces
          .where((e) => e.name.startsWith(prefix))
          .toList();
      if (candidates.isEmpty) break;
      if (candidates.length == 1) {
        province = candidates.first;
        matchStr = prefix;
      }
    }
    if (province != null) {
      fragment = fragment.replaceAll(matchStr, '');
    }
  }

  if (city == null) {
    for (var len = 2; len <= fragment.length; len++) {
      final prefix = fragment.substring(0, len);
      final candidates = data.cities
          .where((e) =>
              e.name.startsWith(prefix) &&
              (province == null || e.provinceCode == province.code))
          .toList();
      if (candidates.isEmpty) break;
      if (candidates.length == 1) {
        city = candidates.first;
        matchStr = prefix;
      }
    }
    if (city != null) {
      fragment = fragment.replaceAll(matchStr, '');
      province ??= findByCode(data.provinces, city.provinceCode);
    }
  }

  if (area == null) {
    for (var len = 2; len <= fragment.length; len++) {
      final prefix = fragment.substring(0, len);
      final candidates = data.areas
          .where((e) =>
              e.name.startsWith(prefix) &&
              (city == null || e.cityCode == city.code) &&
              (province == null || e.provinceCode == province.code))
          .toList();
      if (candidates.isEmpty) break;
      if (candidates.length == 1) {
        area = candidates.first;
        matchStr = prefix;
      }
    }
    if (area != null) {
      // js 版此处为单次替换 (非全局), 保持一致
      fragment = fragment.replaceFirst(matchStr, '');
      province ??= findByCode(data.provinces, area.provinceCode);
      city ??= findByCode(data.cities, area.cityCode);
    }
  }

  // 解析完省市区如果还存在地址, 则默认为详细地址
  if (fragment.isNotEmpty) {
    detail.add(fragment);
  }
  return RegionParseResult(province, city, area, detail);
}

/// 利用行政区划名称前缀向下查找解析 (js 版 `type = 1`)。
RegionParseResult parseRegionWithTree(
  String fragment,
  RegionInfo? hasProvince,
  RegionInfo? hasCity,
  RegionData data,
) {
  RegionInfo? province = hasProvince;
  RegionInfo? city = hasCity;
  RegionInfo? area;
  // js 版树查找不会继承已解析的区县结果, 保持一致
  final detail = <String>[];

  // 从省开始查找
  if (province == null) {
    for (final tempProvince in data.provinces) {
      final replaceName = longestNamePrefix(tempProvince.name, fragment);
      if (replaceName != null) {
        province = tempProvince;
        fragment = fragment.replaceAll(replaceName, '');
        break;
      }
    }
  }

  // 从市区开始查找
  if (city == null) {
    for (final tempCity in data.cities) {
      if (province != null && tempCity.provinceCode != province.code) {
        continue;
      }
      final replaceName = longestNamePrefix(tempCity.name, fragment);
      if (replaceName != null) {
        city = tempCity;
        if (province == null) {
          // 没有省, 顺带补齐省 (js 版此处为单次替换, 保持一致)
          province = findByCode(data.provinces, tempCity.provinceCode);
          fragment = fragment.replaceFirst(replaceName, '');
        } else {
          fragment = fragment.replaceAll(replaceName, '');
        }
        break;
      }
    }
  }

  // 从区市县开始查找
  for (final tempArea in data.areas) {
    if (province != null || city != null) {
      // 有省或者市, 只在其下辖区域中查找
      final provinceMatch =
          province != null && tempArea.provinceCode == province.code;
      final cityMatch = city != null && tempArea.cityCode == city.code;
      if (!provinceMatch && !cityMatch) {
        continue;
      }
      final replaceName = longestNamePrefix(tempArea.name, fragment);
      if (replaceName != null) {
        area = tempArea;
        city ??= findByCode(data.cities, tempArea.cityCode);
        province ??= findByCode(data.provinces, tempArea.provinceCode);
        fragment = fragment.replaceFirst(replaceName, '');
        break;
      }
    } else {
      // 没有省市, 区县市有可能重名, 这里暂时不处理,
      // 因为概率极低, 可以根据添加市解决
      final replaceName = longestNamePrefix(tempArea.name, fragment);
      if (replaceName != null) {
        area = tempArea;
        city = findByCode(data.cities, tempArea.cityCode);
        province = findByCode(data.provinces, tempArea.provinceCode);
        fragment = fragment.replaceFirst(replaceName, '');
        break;
      }
    }
  }

  // 解析完省市区如果还存在地址, 则默认为详细地址
  if (fragment.isNotEmpty) {
    detail.add(fragment);
  }
  return RegionParseResult(province, city, area, detail);
}

/// 在 [fragment] 开头寻找 [name] 的最长前缀 (至少 2 个字)。
String? longestNamePrefix(String name, String fragment) {
  for (var i = name.length; i > 1; i--) {
    final temp = name.substring(0, i);
    if (fragment.startsWith(temp)) {
      return temp;
    }
  }
  return null;
}

/// 按行政区划代码查找节点。
RegionInfo? findByCode(List<RegionInfo> list, String? code) {
  if (code == null) {
    return null;
  }
  for (final info in list) {
    if (info.code == code) {
      return info;
    }
  }
  return null;
}
