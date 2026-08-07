import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_client_provider.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/landlord/data/models/community.dart';
import 'package:zhuxiang_app/features/landlord/data/models/landlord_house.dart';
import 'package:zhuxiang_app/features/landlord/data/providers/landlord_providers.dart';
import 'package:zhuxiang_app/features/landlord/presentation/pages/house_form_page.dart';

void main() {
  test('community parses backend aliases and coordinates', () {
    final community = Community.fromJson({
      'communityId': 'community-1',
      'communityName': '龙湖春森彼岸',
      'formattedAddress': '北滨一路',
      'province': '重庆市',
      'city': '重庆市',
      'district': '江北区',
      'location': '106.56,29.58',
    });

    expect(community.id, 'community-1');
    expect(community.name, '龙湖春森彼岸');
    expect(community.longitude, 106.56);
    expect(community.latitude, 29.58);
  });

  test('map poi only submits provider and poi id to from-map endpoint', () {
    const poi = MapPoi(
      externalPoiId: 'B001',
      name: '龙湖春森彼岸',
      address: '北滨一路',
      province: '重庆市',
      city: '重庆市',
      district: '江北区',
      longitude: 106.56,
      latitude: 29.58,
    );

    expect(poi.toSelectionJson(), {
      'mapProvider': 'amap',
      'externalPoiId': 'B001',
    });
  });

  test('map poi parses normalized backend proxy response', () {
    final poi = MapPoi.fromJson({
      'mapProvider': 'amap',
      'externalPoiId': 'B001',
      'name': '龙湖春森彼岸',
      'address': '北滨一路',
      'district': '江北区',
      'longitude': 106.56,
      'latitude': 29.58,
    });

    expect(poi.externalPoiId, 'B001');
    expect(poi.name, '龙湖春森彼岸');
    expect(poi.locationLabel, '江北区 · 北滨一路');
  });

  test('house request serializes publishing fields', () {
    const request = CreateHouseRequest(
      title: '两居室',
      coverImage: '',
      imageUrls: [],
      location: '重庆市 江北区',
      communityId: 'community-1',
      price: 300000,
      rentMode: 'WHOLE_RENT',
      rentType: 'LONG_RENT',
      facilityIds: ['facility-1'],
      tagIds: ['tag-1'],
      address: '北滨一路',
      area: 45.5,
      isSelfViewingSupported: true,
    );

    final json = request.toJson();
    expect(json['communityId'], 'community-1');
    expect(json.containsKey('landlordId'), isFalse);
    expect(json['address'], '北滨一路');
    expect(json['area'], 45.5);
    expect(json['rentMode'], 'WHOLE_RENT');
    expect(json['rentType'], 'LONG_RENT');
    expect(json['facilityIds'], ['facility-1']);
    expect(json['tagIds'], ['tag-1']);
    expect(json['isSelfViewingSupported'], isTrue);
    expect(json.containsKey('longitude'), isFalse);
    expect(json.containsKey('latitude'), isFalse);
  });

  test('edit detail maps facility and tag object aliases', () {
    final house = LandlordHouseItem.fromJson({
      'id': 'house-1',
      'facilities': [
        {'facilityId': 'facility-1', 'facilityName': '空调'},
      ],
      'tags': [
        {'tagId': 'tag-1', 'tagName': '近地铁'},
      ],
    });
    final facility = HouseDictionaryItem.fromJson({
      'facilityId': 'facility-1',
      'facilityName': '空调',
    });
    final tag = HouseDictionaryItem.fromJson({
      'tagId': 'tag-1',
      'tagName': '近地铁',
    });

    expect(house.facilityIds, ['facility-1']);
    expect(house.tagIds, ['tag-1']);
    expect(facility.id, 'facility-1');
    expect(facility.name, '空调');
    expect(tag.id, 'tag-1');
    expect(tag.name, '近地铁');
  });

  testWidgets('house form content is visible above fixed submit bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          houseFacilitiesProvider.overrideWith(
            (ref) async => const [
              HouseDictionaryItem(id: 'facility-1', name: '空调'),
            ],
          ),
          houseTagsProvider.overrideWith(
            (ref) async => const [
              HouseDictionaryItem(id: 'tag-1', name: '近地铁'),
            ],
          ),
        ],
        child: const MaterialApp(home: LandlordHouseFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('基本信息').hitTestable(), findsOneWidget);
    expect(find.text('保存草稿').hitTestable(), findsOneWidget);

    for (var index = 0; index < 4; index++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(find.text('空调'), findsOneWidget);
    expect(find.text('近地铁'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(find.text('点击上传封面图').hitTestable(), findsOneWidget);
    expect(find.text('添加房源图片').hitTestable(), findsOneWidget);
  });

  testWidgets('edit form calculates deposit immediately after loading rent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_HouseFormApiClient())],
        child: const MaterialApp(
          home: LandlordHouseFormPage(houseId: 'house-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('¥3000'), findsOneWidget);
    final rentField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, '月租金（元）'),
    );
    expect(rentField.controller?.text, '3000');
  });
}

class _HouseFormApiClient extends ApiClient {
  @override
  Future<ApiResult<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final data = switch (path) {
      '/landlord/houses/house-1' => <String, dynamic>{
        'id': 'house-1',
        'title': '测试房源',
        'price': 300000,
        'paymentMethod': '押一付一',
        'status': 'offline',
      },
      '/landlord/house-facilities' => <dynamic>[],
      '/landlord/house-tags' => <dynamic>[],
      _ => <dynamic>[],
    };
    return ApiSuccess(
      Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        data: {'code': 200, 'message': 'success', 'data': data},
      ),
    );
  }
}
