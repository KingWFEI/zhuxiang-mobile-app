import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/house/data/models/house.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/models/house_source_type.dart';
import 'package:zhuxiang_app/features/house/presentation/widgets/house_card.dart';

void main() {
  test('house models parse the server-controlled source type', () {
    final landlordHouse = House.fromJson({
      ..._houseJson,
      'sourceType': 'LANDLORD',
    });
    final platformDetail = HouseDetail.fromJson({
      ..._houseJson,
      'sourceType': 'PLATFORM',
    });

    expect(landlordHouse.sourceType, HouseSourceType.landlord);
    expect(landlordHouse.sourceLabel, '房东直租');
    expect(platformDetail.sourceType, HouseSourceType.platform);
    expect(platformDetail.sourceLabel, '平台自营');
  });

  test('house detail parses the landlord public profile', () {
    final detail = HouseDetail.fromJson({
      ..._houseJson,
      'landlordProfile': {
        'userId': 'landlord-user-1',
        'name': '林先生',
        'slogan': '在杭州安心找房',
        'introduction': '熟悉余杭区房源。',
        'rating': 4.9,
        'rentedCount': 18,
        'serviceYears': 6,
        'profileTags': ['响应及时', '可养宠'],
        'showPhone': false,
        'showWechat': true,
        'showEmail': false,
        'wechat': 'wuyou-home',
      },
    });

    expect(detail.landlordProfile?.userId, 'landlord-user-1');
    expect(detail.landlordProfile?.profileTags, ['响应及时', '可养宠']);
    expect(detail.landlordProfile?.phone, isNull);
    expect(detail.landlordProfile?.wechat, 'wuyou-home');
  });

  testWidgets('house card displays platform and landlord source badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HouseCard(house: House.fromJson(_houseJson)),
              HouseCard(
                house: House.fromJson({
                  ..._houseJson,
                  'id': 'house-2',
                  'sourceType': 'LANDLORD',
                }),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('平台自营'), findsOneWidget);
    expect(find.text('房东直租'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _houseJson = <String, dynamic>{
  'id': 'house-1',
  'title': '测试房源',
  'coverImage': '',
  'location': '渝北区',
  'community': '中央公园',
  'price': 280000,
  'roomType': '2室1厅1卫',
  'area': 72,
  'floor': '8/18层',
  'orientation': '南',
  'tags': <String>[],
  'facilities': <String>[],
  'description': '',
  'isSmartLockSupported': false,
  'isFavorite': false,
  'metro': '',
  'decoration': '精装',
  'availableDate': '',
  'sourceType': 'PLATFORM',
};
