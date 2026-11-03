## 致谢与开源声明 (Acknowledgments & License)

本项目在开发过程中参考并移植了优秀的前端开源地址解析库 [ldwonday/zh-address-parse](https://github.com/ldwonday/zh-address-parse)（作者：Christoph von Gellhorn）。

- **原版项目**：[ldwonday/zh-address-parse](https://github.com/ldwonday/zh-address-parse) (MIT License)
- **Dart 移植版**：通过 AI 辅助重构与移植，实现了全平台纯 Dart 离线支持，并对齐了全部基准测试用例。

本项目遵循 **MIT License** 开源协议发布，详见 [LICENSE](LICENSE) 文件。

## Features

- 纯 Dart 实现，**同步调用、无平台通道、离线可用**
- 识别省 / 市 / 区县名称与 6 位行政区划代码（直辖市自动补齐同名市级）
- 识别详细地址（自动剔除其中的省市区名并去重）
- 识别收货人姓名：优先从「收货人：/收件人：/联系人：/姓名：」标签直接提取；
  无标签时回退到百家姓 + 称呼关键字（`先生` / `小姐` / `同志` …）启发式
- 详细地址原样保留：带「详细地址：」等标签时从原文切片，括号、标点、
  「别打电话」等托付语均不清除，仅剔除混入的电话/邮编/省市区/姓名
- 识别手机号：支持 `13812345678`、`+8613812345678`、`138-1234-5678`、`138 1234 5678` 等格式
- 识别邮政编码
- 两种解析模式：正则匹配（`ParseType.regexp`，默认）与树查找（`ParseType.tree`）
- 地址清洗：自动去除 `收货人` / `电话` / `地址` 等关键字、中英文标点、多余空白，合并 `北京北京` → `北京`
- 支持自定义清洗关键字 `textFilter`、姓名最大长度 `nameMaxLength`、补充行政区划 `extraGovData`
- 内置省 (34) / 市 (370) / 区县 (2813) 数据，可直接用于构建省市区选择器
  （数据已更新至 2026 年 4 月，含和安县、和康县、两江新区、新星市、白杨市、
  草湖市、岑岭县等新设区划）

## Getting started

```yaml
dependencies:
  zh_address_parse_dart: ^0.4.0
```

## Usage

```dart
import 'package:zh_address_parse_dart/zh_address_parse_dart.dart';

 /// 京东复制地址
var result = ZhAddressParse.parse('''
收货人：宋哈娜
手机号：13812345678
所在地区：四川成都市武侯区
详细地址：吉庆四路188号1幢1单元1层1号
''');
  print('收货人: ${result.name}');
  print('手机号: ${result.phone}');
  print('省份:   ${result.province}');
  print('城市:   ${result.city}');
  print('区县:   ${result.area}');
  print('详细地址: ${result.detail}');
```

带邮编、标签的完整收货信息也能解析：

```dart
final result = ZhAddressParse.parse(
  '收货人：李四 联系电话：+8613812345678 '
  '收货地址：黑龙江省哈尔滨市道里区友谊路500号 邮编：150000',
);
// name: 李四 / phone: 13812345678 / postalCode: 150000
// province: 黑龙江省 / city: 哈尔滨市 / area: 道里区 / detail: 友谊路500号
```

在输入框监听中实时解析（推荐防抖）：

````dart
TextField(
  onChanged: (text) {
    final r = ZhAddressParse.parse(text);
    setState(() {
      provinceController.text = r.province;
      cityController.text = r.city;
      areaController.text = r.area;
      detailController.text = r.detail;
      nameController.text = r.name;
      phoneController.text = r.phone;
    });
  },
)
;

### API

```dart
static AddressParseResult parse(
  String address, {
  ParseType type = ParseType.regexp,   // 解析模式，对应 js 版 type 0/1
  List<String> textFilter = const [],  // 额外清洗关键字，如繁体「電話」
  int nameMaxLength = 4,               // 姓名识别的最大长度
  ExtraGovData? extraGovData,          // 补充自定义省市区数据
})
````

`AddressParseResult` 字段：`phone`、`postalCode`、`province` / `city` / `area`（名称）、
`provinceCode` / `cityCode` / `areaCode`（6 位行政区划代码）、`detail`、`name`。
传入空地址返回全空字段的结果（`isEmpty == true`，对应 js 版返回 `{}`）。

### 构建省市区选择器

```dart
final provinces = ZhAddressParse.provinces; // 34 个
final citiesOfGuangdong = ZhAddressParse.cities
    .where((c) => c.provinceCode == '440000');
final areasOfShenzhen = ZhAddressParse.areas
    .where((a) => a.cityCode == '440300');
```

## 与 js 版的对应关系

| js 版                                | Flutter 版                                            |
| ------------------------------------ | ----------------------------------------------------- |
| `AddressParse(address, { type: 0 })` | `ZhAddressParse.parse(address)`                       |
| `AddressParse(address, { type: 1 })` | `ZhAddressParse.parse(address, type: ParseType.tree)` |
| `options.textFilter`                 | `parse(..., textFilter: [...])`                       |
| `options.nameMaxLength`              | `parse(..., nameMaxLength: ...)`                      |
| `options.extraGovData`               | `parse(..., extraGovData: ExtraGovData(...))`         |

差异说明：js 版 `setExtraGovData` 会把额外数据**永久**追加到全局数据中；Dart 版改为
按次合并（`RegionData.merge`），不污染全局状态，行为等价且线程安全。

## 数据说明

- 省市区数据来自上游项目的 `js/lib/provinceList.json`（6 位行政区划代码），
  以 Dart 常量形式内置于 `lib/src/data/province_list_data.dart`（脚本自动生成）；
- 数据已于 2026-11 对照民政部全国行政区划信息查询平台
  （[xzqh.mca.gov.cn](https://xzqh.mca.gov.cn/)）更新至 2026 年 4 月，
  覆盖 2020 年中以来的全部县级以上变更（详见 CHANGELOG 0.4.0）；
- 百家姓来自 `js/lib/names.json`，内置于 `lib/src/data/surname_data.dart`；
- 「省直辖县级行政区划」等虚拟市级节点会被其子节点替换提升（与 js 版一致）。

更新数据时，替换 `js/lib/provinceList.json` 后重新生成对应 Dart 数据文件即可。

## Testing

```sh
flutter test
```

测试中的期望值全部来自 js 版（Node 运行 `js/lib/address-parse.js`）的真实输出，
保证两个实现行为一致。

## 测试结果

运行 `flutter test`（2026-11-03，Flutter 3.47.1 / Dart 3.13），**31 个用例全部通过**：

- 与 js 版基准输出对齐（12 组基准地址，两种解析模式）
  - 广东省深圳市南山区科技园南路6号科技园南区7栋 13812345678 张三
  - 张三 138-1234-5678 北京市朝阳区望京街道望京SOHO塔1座
  - 收货人：李四 联系电话：+8613812345678 收货地址：黑龙江省哈尔滨市道里区友谊路500号 邮编：150000
  - 王小姐 15912345678 上海上海市浦东新区张江路58号
  - 内蒙古呼和浩特市新城区成吉思汗大街22号 13155556666 高原
  - 新疆乌鲁木齐市天山区人民路123号
  - 重庆市渝中区解放碑步行街88号 138 1234 5678 刘德华
  - 宁夏回族自治区银川市金凤区北京中路160号 18900001111 马云
  - 西藏拉萨市城关区北京东路1号 13599998888 扎西
  - 广东省珠海市香洲区拱北街道迎宾南路1088号 12234567 李同志
  - 河北省石家庄市桥西区中山西路450号
  - 广西南宁市青秀区民族大道126号 15677778888 韦小宝
- 边界与扩展能力（5 项）：空地址、`textFilter`、`extraGovData`、
  内置省市区选择器数据、`nameMaxLength`
- 姓名识别优化（5 项）：标签姓名优先、常见电话托付语变体、
  无分隔符姓名标签、标签后跟其他字段、弱信号标签姓名校验
- 2020-2026 新设区划覆盖（5 项）：两江新区、和安县 / 和康县、
  新星市 / 白杨市 / 草湖市、岑岭县、撤县(市)设区/设市更名区划
- 标签详细地址原样保留（4 项）：电话与邮编剔除、标签内混入电话、
  逗号分隔格式截断、无标签时清洗拼接
