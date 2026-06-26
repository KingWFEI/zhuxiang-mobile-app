import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_client_provider.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/home/data/models/home_data.dart';
import 'package:zhuxiang_app/features/home/data/providers/home_providers.dart';
import 'package:zhuxiang_app/features/home/data/services/home_service.dart';

void main() {
  test('home service parses the standard API envelope', () async {
    final apiClient = _FakeApiClient(
      ApiSuccess(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/home/data'),
          data: {
            'code': 200,
            'message': 'success',
            'data': {
              'header': {
                'cityName': '重庆',
                'greeting': '晚上好',
                'subtitle': '找到属于你的安心居住空间',
                'searchPlaceholder': '搜索房源',
                'backgroundImageUrl': '',
              },
              'serviceEntries': <dynamic>[],
              'tabs': <dynamic>[],
              'houseGroups': <String, dynamic>{},
            },
          },
        ),
      ),
    );

    final result = await HomeService(apiClient).fetchHomeData();

    expect(result, isA<ApiSuccess<HomeData>>());
    final data = (result as ApiSuccess<HomeData>).data;
    expect(data.header.cityName, '重庆');
    expect(data.header.greeting, '晚上好');
  });

  test('home data filters rented houses from feed groups', () {
    final data = HomeData.fromJson({
      'header': {
        'cityName': '重庆',
        'greeting': '晚上好',
        'subtitle': '找到安心居住空间',
        'searchPlaceholder': '搜索房源',
        'backgroundImageUrl': '',
      },
      'serviceEntries': <dynamic>[],
      'tabs': <dynamic>[],
      'houseGroups': {
        'recommended': {
          'items': [
            {
              'type': 'house',
              'house': {'id': 'available-house', 'title': '可租房源'},
            },
            {
              'type': 'house',
              'house': {
                'id': 'rented-house',
                'title': '已租房源',
                'isRented': true,
              },
            },
            {
              'type': 'house',
              'house': {
                'id': 'active-lease-house',
                'title': '履约中房源',
                'leaseStatus': 'active',
              },
            },
            {
              'type': 'house',
              'house': {
                'id': 'lease-id-house',
                'title': '已有租约房源',
                'currentLeaseId': 'lease-1',
              },
            },
            {
              'type': 'advertisement',
              'advertisement': {
                'id': 'ad-1',
                'title': '推荐专题',
                'description': '品质房源',
                'imageUrl': '',
                'targetType': 'route',
                'targetValue': '',
              },
            },
          ],
        },
      },
    });

    final items = data.houseGroups['recommended']!.items;

    expect(items, hasLength(2));
    expect(
      items.where((item) => item.type == 'house').single.house!.id,
      'available-house',
    );
    expect(items.where((item) => item.type == 'advertisement'), hasLength(1));
  });

  test('home service provider receives apiClientProvider instance', () {
    final apiClient = _FakeApiClient(
      const ApiFailure(message: 'not requested'),
    );
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
    );
    addTearDown(container.dispose);

    expect(container.read(homeServiceProvider).apiClient, same(apiClient));
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.result);

  final ApiResult<Response<dynamic>> result;

  @override
  Future<ApiResult<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return result;
  }
}
