import 'package:dio/dio.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/page_result.dart';
import '../models/hot_community.dart';
import '../models/house.dart';

/// 房源数据服务。
///
class HouseService {
  final ApiClient apiClient;
  HouseService(this.apiClient);

  //返回搜索页热门小区。
  List<HotCommunity> getHotCommunities() {
    // final result=apiClient.get(path)
    return const [];
  }

  //按查询参数筛选、排序并分页。
  Future<PageResult<House>> fetchHouses(Map<String, dynamic> query) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    var houses = _mockHouses.toList(growable: true);
    final keyword = (query['keyword'] as String? ?? '').trim().toLowerCase();
    final region = query['region'] as String? ?? '';
    final roomType = query['roomType'] as String? ?? '';
    final category = query['category'] as String? ?? '';
    final minPrice = query['minPrice'] as int? ?? 0;
    final maxPrice = query['maxPrice'] as int? ?? 0;
    final sort = query['sort'] as String? ?? 'default';

    if (keyword.isNotEmpty) {
      houses = houses
          .where((house) {
            final searchable = [
              house.title,
              house.location,
              house.community,
              house.metro,
              house.roomType,
              ...house.tags,
            ].join(' ').toLowerCase();
            return searchable.contains(keyword);
          })
          .toList(growable: true);
    }

    if (region.isNotEmpty) {
      final regionName = _regionNames[region] ?? region;
      houses = houses
          .where((house) => house.location.contains(regionName))
          .toList(growable: true);
    }
    if (roomType.isNotEmpty) {
      houses = houses
          .where((house) => house.roomType == roomType)
          .toList(growable: true);
    }
    if (minPrice > 0) {
      houses = houses
          .where((house) => house.price >= minPrice)
          .toList(growable: true);
    }
    if (maxPrice > 0) {
      houses = houses
          .where((house) => house.price <= maxPrice)
          .toList(growable: true);
    }
    if (category == 'short_rent') {
      houses = houses
          .where((house) => house.tags.contains('可月付'))
          .toList(growable: true);
    } else if (category == 'long_rent') {
      houses = houses
          .where((house) => house.tags.contains('整租'))
          .toList(growable: true);
    }

    switch (sort) {
      case 'price_asc':
        houses.sort((a, b) => a.price.compareTo(b.price));
      case 'price_desc':
        houses.sort((a, b) => b.price.compareTo(a.price));
      case 'smart_lock':
        houses.sort((a, b) {
          final aScore = a.isSmartLockSupported ? 1 : 0;
          final bScore = b.isSmartLockSupported ? 1 : 0;
          return bScore.compareTo(aScore);
        });
      case 'latest':
        houses = houses.reversed.toList(growable: true);
      case 'default':
      case 'distance':
        break;
    }

    final page = query['page'] as int? ?? 1;
    final pageSize = query['pageSize'] as int? ?? 20;
    final start = (page - 1) * pageSize;
    final items = start >= houses.length
        ? const <House>[]
        : houses.skip(start).take(pageSize).toList(growable: false);

    return PageResult(
      items: items,
      page: page,
      pageSize: pageSize,
      total: houses.length,
      hasMore: start + items.length < houses.length,
    );
  }

  // 根据 ID 返回房源详情。
  Future<ApiResult<HouseDetail>> getHouseDetail(String houseId) async {
    final result = await apiClient.get('/houses/$houseId');

    if (result is ApiSuccess<Response<dynamic>>) {
      final response = result.data;
      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        return ApiFailure(message: '房源详情数据格式错误');
      }

      if (responseData['code'] != 200) {
        return ApiFailure(
          message: responseData['message'] as String? ?? '获取房源详情失败',
        );
      }

      final data = responseData['data'];
      if (data is! Map<String, dynamic>) {
        return ApiFailure(message: '房源详情数据结构错误');
      }

      return ApiSuccess(HouseDetail.fromJson(data));
    }

    if (result is ApiFailure<Response<dynamic>>) {
      return ApiFailure(message: result.message, error: result.error);
    }

    return ApiFailure(message: '获取房源详情失败');
  }
}

const _regionNames = <String, String>{
  'yubei': '渝北区',
  'jiangbei': '江北区',
  'yuzhong': '渝中区',
};

/// 模拟数据，后续替换为真实接口返回的房源列表。
const _mockHouses = <House>[
  House(
    id: 'mock-house-1',
    title: '温馨一居 · 阳光充足',
    coverImage: '',
    location: '渝北区',
    community: '中央公园',
    address: '光电园附近',
    price: 268000,
    deposit: 268000,
    paymentMethod: '月付',
    roomType: '1室1厅1卫',
    area: 42,
    floor: '12/28层',
    orientation: '朝南',
    tags: ['近地铁', '可月付', '智能门锁', '拎包入住'],
    facilities: ['空调', '冰箱', '洗衣机', '智能门锁'],
    description: '采光充足，家具家电齐全，步行可达轨道交通站。',
    isSmartLockSupported: true,
    isFavorite: false,
    metro: '中央公园站 300m',
    decoration: '精装修',
    availableDate: '2026-07-01',
    isVerified: true,
  ),
  House(
    id: 'mock-house-2',
    title: '精致单间 · 配套齐全',
    coverImage: '',
    location: '渝北区',
    community: '中央公园',
    address: '幸福广场附近',
    price: 198000,
    deposit: 198000,
    paymentMethod: '月付',
    roomType: '1室0厅1卫',
    area: 28,
    floor: '8/18层',
    orientation: '朝南',
    tags: ['近地铁', '整租', '可月付', '拎包入住'],
    facilities: ['空调', '热水器', '衣柜'],
    description: '独立卫浴，社区生活配套成熟，适合单人居住。',
    isSmartLockSupported: false,
    isFavorite: false,
    metro: '中央公园站 450m',
    decoration: '精装修',
    availableDate: '2026-06-28',
    isVerified: true,
  ),
  House(
    id: 'mock-house-3',
    title: '高层景观 · 视野开阔',
    coverImage: '',
    location: '渝北区',
    community: '中央公园',
    address: '嘉州路附近',
    price: 298000,
    deposit: 298000,
    paymentMethod: '月付',
    roomType: '1室1厅1卫',
    area: 55,
    floor: '25/32层',
    orientation: '朝南',
    tags: ['近地铁', '可月付', '智能门锁', '电梯房'],
    facilities: ['中央空调', '冰箱', '洗衣机', '智能门锁'],
    description: '高楼层无遮挡，视野开阔，现代简约装修。',
    isSmartLockSupported: true,
    isFavorite: false,
    metro: '中央公园站 600m',
    decoration: '品质装修',
    availableDate: '2026-07-05',
    isVerified: true,
  ),
  House(
    id: 'mock-house-4',
    title: '品质整租 · 家电齐全',
    coverImage: '',
    location: '江北区',
    community: '中央公园',
    address: '观音桥商圈',
    price: 328000,
    deposit: 328000,
    paymentMethod: '押一付一',
    roomType: '2室1厅1卫',
    area: 68,
    floor: '10/26层',
    orientation: '南北通透',
    tags: ['整租', '智能门锁', '家电齐全', '拎包入住'],
    facilities: ['空调', '电视', '冰箱', '智能门锁'],
    description: '独立整租，双卧布局合理，商圈生活便利。',
    isSmartLockSupported: true,
    isFavorite: false,
    metro: '中央公园站 500m',
    decoration: '精装修',
    availableDate: '2026-07-08',
    isVerified: true,
  ),
  House(
    id: 'mock-house-5',
    title: '近轨两居 · 通勤便利',
    coverImage: '',
    location: '渝中区',
    community: '重庆天地',
    address: '化龙桥附近',
    price: 358000,
    deposit: 358000,
    paymentMethod: '月付',
    roomType: '2室1厅1卫',
    area: 72,
    floor: '16/30层',
    orientation: '朝东南',
    tags: ['近地铁', '整租', '可月付', '电梯房'],
    facilities: ['空调', '冰箱', '洗衣机', '燃气灶'],
    description: '轨道站旁两居室，适合情侣或朋友合住。',
    isSmartLockSupported: false,
    isFavorite: false,
    metro: '9号线 · 化龙桥',
    decoration: '现代装修',
    availableDate: '2026-07-10',
    isVerified: true,
  ),
  House(
    id: 'mock-house-6',
    title: '智能门锁房 · 拎包入住',
    coverImage: '',
    location: '江北区',
    community: '寰宇天下',
    address: '江北嘴附近',
    price: 388000,
    deposit: 388000,
    paymentMethod: '押一付一',
    roomType: '2室1厅1卫',
    area: 76,
    floor: '20/33层',
    orientation: '朝南',
    tags: ['整租', '可月付', '智能门锁', '拎包入住'],
    facilities: ['中央空调', '洗烘一体机', '智能门锁', '新风'],
    description: '全屋智能配置，品牌家电，入住手续便捷。',
    isSmartLockSupported: true,
    isFavorite: true,
    metro: '6号线 · 江北城',
    decoration: '高品质装修',
    availableDate: '2026-06-25',
    isVerified: true,
  ),
];
