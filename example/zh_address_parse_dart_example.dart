import 'package:zh_address_parse_dart/zh_address_parse_dart.dart';

void main() {
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

  /// 淘宝复制地址
  result = ZhAddressParse.parse('''
收件人: 宋哈娜
手机号码: 13812345678
所在地区: 四川成都市武侯区
详细地址: 吉庆四路188号1幢1单元1层1号
''');

  print('收货人: ${result.name}');
  print('手机号: ${result.phone}');
  print('省份:   ${result.province}');
  print('城市:   ${result.city}');
  print('区县:   ${result.area}');
  print('详细地址: ${result.detail}');

  /// 拼夕夕复制地址
  result = ZhAddressParse.parse('宋哈娜 13812345678 四川省成都市武侯区 吉庆四路188号1幢1单元1层1号');

  print('收货人: ${result.name}');
  print('手机号: ${result.phone}');
  print('省份:   ${result.province}');
  print('城市:   ${result.city}');
  print('区县:   ${result.area}');
  print('详细地址: ${result.detail}');
}
