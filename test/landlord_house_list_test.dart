import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/landlord/data/models/landlord_house.dart';
import 'package:zhuxiang_app/features/landlord/data/providers/landlord_providers.dart';
import 'package:zhuxiang_app/features/landlord/data/services/landlord_house_service.dart';
import 'package:zhuxiang_app/features/landlord/presentation/pages/house_list_page.dart';

void main() {
  testWidgets('publish and offline actions call service and refresh status', (
    tester,
  ) async {
    final service = _FakeLandlordHouseService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [landlordHouseServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: LandlordHouseListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('上架'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.publishCalls, 1);
    expect(find.text('下架'), findsOneWidget);

    await tester.tap(find.text('下架'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.offlineCalls, 1);
    expect(find.text('上架'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}

class _FakeLandlordHouseService implements LandlordHouseService {
  var _status = 'draft';
  var publishCalls = 0;
  var offlineCalls = 0;

  LandlordHouseItem get _house => LandlordHouseItem.fromJson({
    'id': 'house-1',
    'title': '测试房源',
    'location': '南岸区',
    'price': 120000,
    'status': _status,
  });

  @override
  Future<List<LandlordHouseItem>> getMyHouses({String? status}) async {
    return status == null || status == _status ? [_house] : const [];
  }

  @override
  Future<LandlordHouseItem> publishHouse(String houseId) async {
    publishCalls++;
    _status = 'available';
    return _house;
  }

  @override
  Future<LandlordHouseItem> offlineHouse(String houseId) async {
    offlineCalls++;
    _status = 'offline';
    return _house;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
