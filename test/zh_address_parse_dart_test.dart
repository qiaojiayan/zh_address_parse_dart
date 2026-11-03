import 'package:flutter_test/flutter_test.dart';

import 'package:zh_address_parse_dart/zh_address_parse_dart.dart';

/// 期望值全部来自 js 版 (js/lib/address-parse.js) 的真实运行输出,
/// 用于保证 Flutter 版与 js 版行为一致。
void main() {
  group('与 js 版基准输出对齐', () {
    const textFilter = <String>['电話', '電話', '聯系人'];

    const cases = <String, Object>{
      '广东省深圳市南山区科技园南路6号科技园南区7栋 13812345678 张三': (
        ParseType.regexp,
        AddressParseResult(
          phone: '13812345678',
          province: '广东省',
          city: '深圳市',
          area: '南山区',
          detail: '科技园南路6号科技园南区7栋',
          name: '张三',
          provinceCode: '440000',
          cityCode: '440300',
          areaCode: '440305',
        ),
      ),
      '张三 138-1234-5678 北京市朝阳区望京街道望京SOHO塔1座': (
        ParseType.regexp,
        AddressParseResult(
          phone: '13812345678',
          province: '北京市',
          city: '北京市',
          area: '朝阳区',
          detail: '望京街道望京SOHO塔1座',
          name: '张三',
          provinceCode: '110000',
          cityCode: '110000',
          areaCode: '110105',
        ),
      ),
      '收货人：李四 联系电话：+8613812345678 收货地址：黑龙江省哈尔滨市道里区友谊路500号 邮编：150000': (
        ParseType.regexp,
        AddressParseResult(
          phone: '13812345678',
          postalCode: '150000',
          province: '黑龙江省',
          city: '哈尔滨市',
          area: '道里区',
          detail: '友谊路500号',
          name: '李四',
          provinceCode: '230000',
          cityCode: '230100',
          areaCode: '230102',
        ),
      ),
      '王小姐 15912345678 上海上海市浦东新区张江路58号': (
        ParseType.regexp,
        AddressParseResult(
          phone: '15912345678',
          province: '上海市',
          city: '上海市',
          area: '浦东新区',
          detail: '张江路58号',
          name: '王小姐',
          provinceCode: '310000',
          cityCode: '310000',
          areaCode: '310115',
        ),
      ),
      '内蒙古呼和浩特市新城区成吉思汗大街22号 13155556666 高原': (
        ParseType.regexp,
        AddressParseResult(
          phone: '13155556666',
          province: '内蒙古自治区',
          city: '呼和浩特市',
          area: '新城区',
          detail: '成吉思汗大街22号',
          name: '高原',
          provinceCode: '150000',
          cityCode: '150100',
          areaCode: '150102',
        ),
      ),
      '新疆乌鲁木齐市天山区人民路123号': (
        ParseType.regexp,
        AddressParseResult(
          province: '新疆维吾尔自治区',
          city: '乌鲁木齐市',
          area: '天山区',
          detail: '人民路123号',
          provinceCode: '650000',
          cityCode: '650100',
          areaCode: '650102',
        ),
      ),
      '重庆市渝中区解放碑步行街88号 138 1234 5678 刘德华': (
        ParseType.regexp,
        AddressParseResult(
          phone: '13812345678',
          province: '重庆市',
          city: '重庆市',
          area: '渝中区',
          detail: '解放碑步行街88号',
          name: '刘德华',
          provinceCode: '500000',
          cityCode: '500000',
          areaCode: '500103',
        ),
      ),
      '宁夏回族自治区银川市金凤区北京中路160号 18900001111 马云': (
        ParseType.tree,
        AddressParseResult(
          phone: '18900001111',
          province: '宁夏回族自治区',
          city: '银川市',
          area: '金凤区',
          detail: '北京中路160号',
          name: '马云',
          provinceCode: '640000',
          cityCode: '640100',
          areaCode: '640106',
        ),
      ),
      '西藏拉萨市城关区北京东路1号 13599998888 扎西': (
        ParseType.tree,
        AddressParseResult(
          phone: '13599998888',
          province: '西藏自治区',
          city: '拉萨市',
          area: '城关区',
          detail: '北京东路1号',
          name: '扎西',
          provinceCode: '540000',
          cityCode: '540100',
          areaCode: '540102',
        ),
      ),
      '广东省珠海市香洲区拱北街道迎宾南路1088号 12234567 李同志': (
        ParseType.tree,
        AddressParseResult(
          postalCode: '234567',
          province: '广东省',
          city: '珠海市',
          area: '香洲区',
          detail: '拱北街道迎宾南路1088号',
          name: '李同志',
          provinceCode: '440000',
          cityCode: '440400',
          areaCode: '440402',
        ),
      ),
      '河北省石家庄市桥西区中山西路450号': (
        ParseType.regexp,
        AddressParseResult(
          province: '河北省',
          city: '石家庄市',
          area: '桥西区',
          detail: '中山西路450号',
          provinceCode: '130000',
          cityCode: '130100',
          areaCode: '130104',
        ),
      ),
      '广西南宁市青秀区民族大道126号 15677778888 韦小宝': (
        ParseType.regexp,
        AddressParseResult(
          phone: '15677778888',
          province: '广西壮族自治区',
          city: '南宁市',
          area: '青秀区',
          detail: '民族大道126号',
          name: '韦小宝',
          provinceCode: '450000',
          cityCode: '450100',
          areaCode: '450103',
        ),
      ),
    };

    for (final entry in cases.entries) {
      test(entry.key, () {
        final (type, expected) = entry.value as (ParseType, AddressParseResult);
        final result = ZhAddressParse.parse(
          entry.key,
          type: type,
          textFilter: textFilter,
        );
        expect(result, expected, reason: '$result');
      });
    }
  });

  group('边界与扩展能力', () {
    test('空地址返回空结果', () {
      expect(ZhAddressParse.parse('').isEmpty, isTrue);
    });

    test('textFilter 清洗自定义关键字后可识别姓名', () {
      final result = ZhAddressParse.parse(
        '寄件人小美 13812345678 广东省深圳市南山区科苑路15号',
        textFilter: const ['寄件人'],
      );
      expect(result.name, '小美');
      expect(result.province, '广东省');
      expect(result.city, '深圳市');
      expect(result.area, '南山区');
      expect(result.detail, '科苑路15号');
      expect(result.phone, '13812345678');
    });

    test('extraGovData 可补充自定义区县', () {
      const extra = ExtraGovData(
        area: <RegionInfo>[
          RegionInfo(
            code: '440399',
            name: '测试新区',
            provinceCode: '440000',
            cityCode: '440300',
          ),
        ],
      );
      final result = ZhAddressParse.parse(
        '广东省深圳市测试新区测试路1号',
        extraGovData: extra,
      );
      expect(result.area, '测试新区');
      expect(result.areaCode, '440399');
      expect(result.detail, '测试路1号');

      // 不传 extraGovData 时无法识别该区县
      final plain = ZhAddressParse.parse('广东省深圳市测试新区测试路1号');
      expect(plain.area, '');
      expect(plain.detail, '测试新区测试路1号');
    });

    test('内置省市区数据可供建选择器使用', () {
      expect(ZhAddressParse.provinces.length, 34);
      expect(ZhAddressParse.provinces.first.name, '北京市');
      expect(ZhAddressParse.provinces.first.code, '110000');
      expect(ZhAddressParse.cities.length, 370);
      expect(ZhAddressParse.areas.length, 2813);
      expect(
        ZhAddressParse.cities.where((c) => c.provinceCode == '440000').length,
        greaterThanOrEqualTo(21),
      );
    });

    test('nameMaxLength 影响姓名识别', () {
      const address = '欧阳锋 13812345678 北京市朝阳区幸福路8号';
      // 默认 4: 「欧阳锋」可识别 (长度 3)
      expect(ZhAddressParse.parse(address).name, '欧阳锋');
      // 限制为 2: 「欧阳锋」超长, 不再识别为姓名
      expect(ZhAddressParse.parse(address, nameMaxLength: 2).name, '');
    });
  });

  group('姓名识别优化', () {
    test('标签姓名优先于启发式 (用户反馈用例)', () {
      const address =
          '收货人：宋哈娜\n'
          '手机号：17712345678\n'
          '所在地区：四川成都市武侯区\n'
          '详细地址：恒大花园(放北苑菜鸟，别打电话)';
      final result = ZhAddressParse.parse(address);
      expect(result.name, '宋哈娜'); // 标签姓名优先, 而不是启发式猜出的「别打」
      expect(result.phone, '17712345678');
      expect(result.province, '四川省');
      expect(result.city, '成都市');
      expect(result.area, '武侯区');
      // 详细地址从原文切片, 括号 / 逗号 / 托付语原样保留
      expect(result.detail, '恒大花园(放北苑菜鸟，别打电话)');
    });

    test('常见电话托付语变体', () {
      const base = '湖南省长沙市岳麓区麓山南路2号 15573123456 宋祖英 ';
      for (final instruction in const [
        '勿打电话',
        '不要打电话',
        '不方便接听电话',
        '拒接电话',
        '请勿来电',
        '先别打电话',
      ]) {
        final result = ZhAddressParse.parse(base + instruction);
        expect(result.name, '宋祖英', reason: instruction);
        expect(result.detail, '麓山南路2号', reason: instruction);
      }
    });

    test('无分隔符的姓名标签也能提取', () {
      final result = ZhAddressParse.parse('收货人张三 13812345678 北京市朝阳区幸福路8号');
      expect(result.name, '张三');
      expect(result.detail, '幸福路8号');
    });

    test('姓名标签后跟其他字段时不会被误判', () {
      // 标签后是手机号字段: 不应把「手机号码」当姓名
      final result = ZhAddressParse.parse('联系人：手机号码13812345678 广东省深圳市南山区科技园1号');
      expect(result.name, '');
      expect(result.province, '广东省');
      expect(result.detail, '科技园1号');
    });

    test('无分隔符弱信号标签需通过姓名校验', () {
      // 「联系人驿站放门口」不是姓名 (驿站非姓氏),
      // 不应通过标签提取出姓名
      final result = ZhAddressParse.parse(
        '广东省深圳市南山区科苑路15号 联系人驿站放门口 13812345678',
      );
      expect(result.name, '');
      expect(result.detail, contains('驿站'));
    });
  });

  group('2020-2026 新设区划覆盖', () {
    test('重庆两江新区 (2025.11 撤江北区/渝北区设立)', () {
      final result = ZhAddressParse.parse('重庆市两江新区金渝大道66号 13812345678 张三');
      expect(result.province, '重庆市');
      expect(result.city, '重庆市');
      expect(result.area, '两江新区');
      expect(result.areaCode, '500157');
      expect(result.detail, '金渝大道66号');
    });

    test('新疆和田地区和安县 / 和康县 (2024.12 新设)', () {
      final r1 = ZhAddressParse.parse('新疆和田地区和安县红柳镇');
      expect(r1.area, '和安县');
      expect(r1.areaCode, '653229');
      // 注: 「红柳镇」长度 <= 4 会被 js 版继承的姓名兜底逻辑当作姓名
      final r2 = ZhAddressParse.parse('新疆和田地区和康县昆岭镇');
      expect(r2.area, '和康县');
      expect(r2.areaCode, '653228');
    });

    test('新疆兵团新星市 / 白杨市 / 草湖市 (2021/2023/2026 新设)', () {
      final r1 = ZhAddressParse.parse('新疆维吾尔自治区新星市黄田镇');
      expect(r1.city, '新星市');
      expect(r1.cityCode, '659011');
      final r2 = ZhAddressParse.parse('新疆维吾尔自治区白杨市光明路1号');
      expect(r2.city, '白杨市');
      expect(r2.cityCode, '659012');
      final r3 = ZhAddressParse.parse('新疆维吾尔自治区草湖市草湖镇');
      expect(r3.city, '草湖市');
      expect(r3.cityCode, '659013');
    });

    test('新疆喀什地区岑岭县 (2026.3 新设)', () {
      final result = ZhAddressParse.parse('新疆喀什地区岑岭县新华镇');
      expect(result.area, '岑岭县');
      expect(result.areaCode, '653132');
    });

    test('撤县(市)设区/设市的更名区划', () {
      expect(
        ZhAddressParse.parse('湖南长沙岳麓区麓山南路2号').area,
        '岳麓区',
      );
      final r1 = ZhAddressParse.parse('新疆塔城地区沙湾市三道河子镇');
      expect(r1.area, '沙湾市');
      expect(r1.areaCode, '654203');
      final r2 = ZhAddressParse.parse('福建漳州市龙海区石码镇');
      expect(r2.area, '龙海区');
      expect(r2.areaCode, '350604');
      final r3 = ZhAddressParse.parse('河南洛阳市孟津区城关镇');
      expect(r3.area, '孟津区');
      expect(r3.areaCode, '410308');
      final r4 = ZhAddressParse.parse('安徽芜湖市湾沚区湾沚镇');
      expect(r4.area, '湾沚区');
      expect(r4.areaCode, '340210');
      final r5 = ZhAddressParse.parse('江苏南通市海门区解放中路');
      expect(r5.area, '海门区');
      expect(r5.areaCode, '320614');
      final r6 = ZhAddressParse.parse('湖北荆州市监利市容城镇');
      expect(r6.area, '监利市');
      expect(r6.areaCode, '421088');
      final r7 = ZhAddressParse.parse('浙江杭州市临平区西大街');
      expect(r7.area, '临平区');
      expect(r7.areaCode, '330113');
      final r8 = ZhAddressParse.parse('四川省凉山彝族自治州会理市城北街道');
      expect(r8.area, '会理市');
      expect(r8.areaCode, '513402');
    });
  });

  group('标签详细地址原样保留', () {
    test('内容中的电话与邮编被剔除, 其余原样保留', () {
      final result = ZhAddressParse.parse(
        '收货人：张三\n'
        '电话：138-1234-5678\n'
        '收货地址：黑龙江哈尔滨市道里区友谊路500号 邮编：150000\n'
        '备注：周一送',
      );
      expect(result.name, '张三');
      expect(result.phone, '13812345678');
      expect(result.postalCode, '150000');
      expect(result.province, '黑龙江省');
      expect(result.city, '哈尔滨市');
      expect(result.area, '道里区');
      // 省市区名 (含简称「黑龙江」) 被剔除, 其余原样保留
      expect(result.detail, '友谊路500号');
    });

    test('详细地址标签内混入电话时剔除电话保留其余', () {
      final result = ZhAddressParse.parse(
        '姓名：李四 地址：四川省成都市武侯区天府大道1700号 13812345678 放丰巢',
      );
      expect(result.name, '李四');
      expect(result.phone, '13812345678');
      expect(result.detail, '天府大道1700号 放丰巢');
    });

    test('单行逗号分隔格式到下一个标签截断', () {
      final result = ZhAddressParse.parse(
        '电话:13812345678,收件人:王小明,地址:湖北武汉市洪山区珞瑜路129号',
      );
      expect(result.name, '王小明');
      expect(result.province, '湖北省');
      expect(result.city, '武汉市');
      expect(result.area, '洪山区');
      expect(result.detail, '珞瑜路129号');
    });

    test('无详细地址标签时维持原有清洗拼接逻辑', () {
      final result = ZhAddressParse.parse('张三 13812345678 广东省深圳市南山区科技园南路6号');
      expect(result.name, '张三');
      expect(result.detail, '科技园南路6号');
    });
  });
}
