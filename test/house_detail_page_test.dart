import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/models/house_facility_item.dart';
import 'package:zhuxiang_app/features/house/data/models/house_source_type.dart';
import 'package:zhuxiang_app/features/house/data/models/immersive_tour.dart';
import 'package:zhuxiang_app/features/house/data/providers/house_providers.dart';
import 'package:zhuxiang_app/features/house/presentation/pages/house_detail_page.dart';

void main() {
  test('房源详情解析服务端配置的设施图标', () {
    final house = HouseDetail.fromJson({
      'facilityItems': [
        {'id': 'facility-wifi', 'name': '高速网络', 'iconKey': 'wifi'},
      ],
    });

    expect(house.facilities, ['高速网络']);
    expect(house.facilityItems.single.id, 'facility-wifi');
    expect(house.facilityItems.single.iconKey, 'wifi');
  });

  testWidgets('房源详情使用大图、悬浮信息卡和固定双操作栏', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final floatingCard = find.byKey(
      const Key('house-detail-floating-info-card'),
    );
    expect(floatingCard, findsOneWidget);
    expect(tester.getTopLeft(floatingCard).dy, lessThan(320));

    expect(find.text('整租'), findsOneWidget);
    expect(find.text('平台自营'), findsOneWidget);
    expect(find.text('预约看房'), findsOneWidget);
    expect(find.text('立即申请'), findsOneWidget);
    expect(find.text('房屋设施'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
    expect(find.text('沉浸式看房'), findsOneWidget);
    expect(find.text('房东信息'), findsOneWidget);
    expect(find.text('智能生活'), findsOneWidget);
    expect(find.text('房源描述'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏详情页滚动后不出现布局溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1100));
    await tester.pumpAndSettle();

    expect(find.text('预约看房'), findsOneWidget);
    expect(find.text('立即申请'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('顶部房源图片支持左右滑动切换', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('2/2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp() {
  return ProviderScope(
    overrides: [
      houseDetailProvider.overrideWith(
        (ref, houseId) async => const ApiSuccess(_house),
      ),
      immersiveTourAvailabilityProvider.overrideWith(
        (ref, houseId) async =>
            const ApiSuccess(ImmersiveTourAvailability(available: true)),
      ),
    ],
    child: const MaterialApp(home: HouseDetailPage(houseId: 'house-1')),
  );
}

const _house = HouseDetail(
  id: 'house-1',
  title: '云栖澜庭 · 朝南精装两居',
  coverImage: '',
  images: [
    'https://example.invalid/house-1.jpg',
    'https://example.invalid/house-2.jpg',
  ],
  location: '杭州市 · 余杭区',
  community: '云栖澜庭',
  address: '文一西路',
  price: 368000,
  paymentMethod: '押一付三',
  rentType: '整租',
  roomType: '2室1厅1卫',
  area: 89,
  floor: '12/26层',
  orientation: '南北通透',
  tags: ['近地铁', '精装修', '可养宠'],
  facilities: ['空调', '洗衣机', '冰箱', '高速网络', '热水器', '双人床', '电视', '智能门锁'],
  facilityItems: [
    HouseFacilityItem(id: 'facility-ac', name: '空调', iconKey: 'ac_unit'),
    HouseFacilityItem(
      id: 'facility-washer',
      name: '洗衣机',
      iconKey: 'local_laundry_service',
    ),
    HouseFacilityItem(id: 'facility-fridge', name: '冰箱', iconKey: 'kitchen'),
    HouseFacilityItem(id: 'facility-wifi', name: '高速网络', iconKey: 'wifi'),
    HouseFacilityItem(id: 'facility-shower', name: '热水器', iconKey: 'shower'),
    HouseFacilityItem(id: 'facility-bed', name: '双人床', iconKey: 'bed'),
    HouseFacilityItem(id: 'facility-tv', name: '电视', iconKey: 'tv'),
    HouseFacilityItem(id: 'facility-lock', name: '智能门锁', iconKey: 'smart_lock'),
  ],
  description: '全屋采光通透，配套完善，步行可达地铁站。',
  isSmartLockSupported: true,
  isFavorite: false,
  metro: '距地铁站约500米',
  decoration: '精装修',
  availableDate: '随时入住',
  landlordName: '勿忧管家',
  sourceType: HouseSourceType.platform,
  isVerified: true,
  rating: 4.9,
  rentedCount: 128,
);
