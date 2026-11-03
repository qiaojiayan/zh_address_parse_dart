import 'internal/address_cleaner.dart';
import 'internal/label_extractor.dart';
import 'internal/name_detector.dart';
import 'internal/region_parser.dart';
import 'models/address_parse_result.dart';
import 'models/extra_gov_data.dart';
import 'parse_type.dart';
import 'region/region_data.dart';
import 'region/region_info.dart';

/// 中文地址智能解析器。
///
/// 移植自仓库 `js/lib/address-parse.js`, 用于解析用户粘贴的收货地址,
/// 实现类似京东 / 淘宝收货地址粘贴识别的能力:
///
/// ```dart
/// final result = ZhAddressParse.parse(
///   '张三 13812345678 广东省深圳市南山区科技园南路6号',
/// );
/// print(result.name);     // 张三
/// print(result.phone);    // 13812345678
/// print(result.province); // 广东省
/// print(result.city);     // 深圳市
/// print(result.area);     // 南山区
/// print(result.detail);   // 科技园南路6号
/// ```
class ZhAddressParse {
  ZhAddressParse._();

  /// 解析地址字符串。
  ///
  /// - [address]: 用户粘贴的原始地址, 可包含姓名、手机号、邮编、
  ///   省市区与详细地址的任意顺序组合;
  /// - [type]: 解析方式, 默认 [ParseType.regexp] (js 版 `type = 0`),
  ///   可选 [ParseType.tree] 树查找模式 (js 版 `type = 1`);
  /// - [textFilter]: 额外需要清洗掉的关键字 (例如繁体 `電話` 等);
  /// - [nameMaxLength]: 姓名识别的最大长度, 默认 4;
  /// - [extraGovData]: 额外补充的省市区数据。
  ///
  /// [address] 为空时返回全空字段的 [AddressParseResult]
  /// (对应 js 版返回 `{}`)。
  static AddressParseResult parse(
    String address, {
    ParseType type = ParseType.regexp,
    List<String> textFilter = const <String>[],
    int nameMaxLength = 4,
    ExtraGovData? extraGovData,
  }) {
    if (address.isEmpty) {
      return const AddressParseResult();
    }

    final data = extraGovData == null || extraGovData.isEmpty
        ? RegionData.base
        : RegionData.base.merge(extraGovData);

    // 0. 优先从「收货人：/姓名：」等标签中提取姓名 (强信号,
    //    避免详细地址中的碎片被启发式误判为姓名);
    //    带有「详细地址：」标签时, 详细地址也从原文切片原样保留
    final labelledName = extractLabelledName(address, nameMaxLength);
    final labelledDetail = extractLabelledDetail(address);

    // 1. 地址清洗
    var rest = cleanAddress(address, textFilter);

    // 2. 识别手机号
    final phoneResult = filterPhone(rest);
    rest = phoneResult.$1;

    // 3. 识别邮编
    final postalResult = filterPostalCode(rest);
    rest = postalResult.$2;

    // 4. 按空格分割, 去掉空段与纯数字段
    var splitAddress = rest
        .split(' ')
        .where((String item) =>
            item.isNotEmpty && !pureDigitsRegExp.hasMatch(item))
        .map((String item) => item.trim())
        .toList();

    // 5. 按省市区县镇排序
    splitAddress = sortAddress(splitAddress);

    // 6. 找省市区和详细地址
    RegionInfo? province;
    RegionInfo? city;
    RegionInfo? area;
    final details = <String>[];

    for (final item in splitAddress) {
      if (province != null && city != null && area != null) {
        details.add(item);
        continue;
      }
      if (type == ParseType.tree) {
        final parsed = parseRegionWithTree(item, province, city, data);
        province = parsed.province ?? province;
        city = parsed.city ?? city;
        area = parsed.area;
        details.addAll(parsed.detail);
      } else {
        final parsed =
            parseRegionWithRegexp(item, province, city, area, data);
        province = parsed.province ?? province;
        city = parsed.city ?? city;
        area = parsed.area ?? area;
        details.addAll(parsed.detail);
      }
    }

    return _buildResult(
      province: province,
      city: city,
      area: area,
      details: details,
      phone: phoneResult.$2,
      postalCode: postalResult.$1,
      nameMaxLength: nameMaxLength,
      labelledName: labelledName,
      labelledDetail: labelledDetail,
    );
  }

  /// 组装最终结果: 剔除详细地址中的省市区名、识别姓名等。
  static AddressParseResult _buildResult({
    required RegionInfo? province,
    required RegionInfo? city,
    required RegionInfo? area,
    required List<String> details,
    required String phone,
    required String postalCode,
    required int nameMaxLength,
    String? labelledName,
    String? labelledDetail,
  }) {
    // 从详细地址中剔除省市区名称
    final regionNames = <String>[
      if (province != null) province.name,
      if (city != null) city.name,
      if (area != null) area.name,
    ];
    var detailList = details.map((String item) {
      for (final name in regionNames) {
        item = item.replaceAll(name, '');
      }
      return item;
    }).toList();
    detailList = deduplicate(detailList);

    // 地址都解析完了, 姓名应该是在详细地址里面;
    // 标签里提取到的姓名 (收货人：xxx) 是更强的信号, 优先使用
    final name = labelledName ?? extractName(detailList, nameMaxLength);

    // 带标签的详细地址: 从原文切片原样保留 (括号 / 标点 / 托付语等
    // 均不清洗), 仅剔除其中混入的电话 / 邮编 / 省市区名 / 姓名
    final String detail;
    if (labelledDetail != null) {
      var preserved = labelledDetail;
      preserved = stripPhoneFromDetail(preserved, phone);
      if (postalCode.isNotEmpty) {
        preserved = preserved.replaceAll(postalCode, '');
      }
      preserved = stripRegionNamePrefixes(preserved, regionNames);
      if (name != null && name.isNotEmpty) {
        preserved = preserved.replaceAll(name, '');
      }
      detail = trimSeparators(preserved);
    } else {
      if (name != null) {
        final detailIndex = detailList.indexOf(name);
        if (detailIndex >= 0) {
          detailList.removeAt(detailIndex);
        }
      }
      detail = detailList.join();
    }

    final provinceName = province?.name ?? '';
    var cityName = city?.name ?? '';
    if (const <String>['市辖区', '区', '县', '镇'].contains(cityName)) {
      cityName = provinceName;
    }

    return AddressParseResult(
      phone: phone,
      postalCode: postalCode,
      province: provinceName,
      city: cityName,
      area: area?.name ?? '',
      detail: detail,
      name: name ?? '',
      provinceCode: province?.code ?? '',
      cityCode: city?.code ?? '',
      areaCode: area?.code ?? '',
    );
  }

  /// 内置省级数据 (34 个), 可用于构建省市区选择器。
  static List<RegionInfo> get provinces => RegionData.base.provinces;

  /// 内置市级数据, 可用于构建省市区选择器。
  static List<RegionInfo> get cities => RegionData.base.cities;

  /// 内置区县级数据, 可用于构建省市区选择器。
  static List<RegionInfo> get areas => RegionData.base.areas;
}
