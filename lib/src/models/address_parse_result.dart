/// 地址解析结果, 与 js 版 `AddressParse` 返回结构保持一致。
class AddressParseResult {
  /// 手机号 (已去掉 `+86` / `86-` 等前缀), 未识别时为空字符串。
  final String phone;

  /// 邮政编码, 未识别时为空字符串。
  final String postalCode;

  /// 省级名称, 例如 `广东省`。
  final String province;

  /// 市级名称, 例如 `深圳市`; 直辖市与 js 版一致返回省市同名。
  final String city;

  /// 区县名称, 例如 `南山区`。
  final String area;

  /// 详细地址 (多段会拼接在一起)。
  final String detail;

  /// 收货人姓名, 未识别时为空字符串。
  final String name;

  /// 省级行政区划代码, 例如 `440000`。
  final String provinceCode;

  /// 市级行政区划代码, 例如 `440300`。
  final String cityCode;

  /// 区县级行政区划代码, 例如 `440305`。
  final String areaCode;

  /// 创建解析结果。
  const AddressParseResult({
    this.phone = '',
    this.postalCode = '',
    this.province = '',
    this.city = '',
    this.area = '',
    this.detail = '',
    this.name = '',
    this.provinceCode = '',
    this.cityCode = '',
    this.areaCode = '',
  });

  /// 所有字段均为空 (对应 js 版传入空地址时返回 `{}`)。
  bool get isEmpty =>
      phone.isEmpty &&
      postalCode.isEmpty &&
      province.isEmpty &&
      city.isEmpty &&
      area.isEmpty &&
      detail.isEmpty &&
      name.isEmpty &&
      provinceCode.isEmpty &&
      cityCode.isEmpty &&
      areaCode.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressParseResult &&
          other.phone == phone &&
          other.postalCode == postalCode &&
          other.province == province &&
          other.city == city &&
          other.area == area &&
          other.detail == detail &&
          other.name == name &&
          other.provinceCode == provinceCode &&
          other.cityCode == cityCode &&
          other.areaCode == areaCode;

  @override
  int get hashCode => Object.hash(
        phone,
        postalCode,
        province,
        city,
        area,
        detail,
        name,
        provinceCode,
        cityCode,
        areaCode,
      );

  @override
  String toString() =>
      'AddressParseResult(phone: $phone, postalCode: $postalCode, '
      'province: $province, city: $city, area: $area, '
      'detail: $detail, name: $name, '
      'provinceCode: $provinceCode, cityCode: $cityCode, areaCode: $areaCode)';
}
