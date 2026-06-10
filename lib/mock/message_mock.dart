import 'package:flutter/material.dart';

class MockMessage {
  const MockMessage({
    required this.title,
    required this.content,
    required this.time,
    required this.icon,
    required this.color,
    required this.category,
    this.unreadCount = 0,
  });

  final String title;
  final String content;
  final String time;
  final IconData icon;
  final Color color;
  final String category;
  final int unreadCount;
}

const messageMock = [
  MockMessage(
    title: '开门成功通知',
    content: '您已成功打开【我的家】大门',
    time: '今天 09:32',
    icon: Icons.door_front_door,
    color: Color(0xFF2F7AF6),
    category: '开锁通知',
    unreadCount: 1,
  ),
  MockMessage(
    title: '租金缴纳提醒',
    content: '您本月的租金尚未缴纳，请及时完成',
    time: '今天 08:30',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF2F7AF6),
    category: '账单消息',
    unreadCount: 2,
  ),
  MockMessage(
    title: '看房预约已确认',
    content: '您预约的看房已确认，请按时前往',
    time: '昨天 16:45',
    icon: Icons.event_available,
    color: Color(0xFF22C7A5),
    category: '预约消息',
    unreadCount: 1,
  ),
  MockMessage(
    title: '报修已受理',
    content: '您的报修工单已受理，维修人员将尽快联系您',
    time: '昨天 11:20',
    icon: Icons.build,
    color: Color(0xFFF59E0B),
    category: '报修消息',
  ),
  MockMessage(
    title: '系统通知',
    content: '平台服务将在 05 月 20 日 02:00-04:00 进行升级',
    time: '05-17 18:00',
    icon: Icons.campaign,
    color: Color(0xFF2F7AF6),
    category: '系统通知',
  ),
  MockMessage(
    title: '远程开锁通知',
    content: '您的门锁已被远程开锁',
    time: '05-16 14:22',
    icon: Icons.lock_open,
    color: Color(0xFF22C7A5),
    category: '开锁通知',
  ),
  MockMessage(
    title: '电子合同已签署',
    content: '您的租赁合同已完成签署',
    time: '05-15 10:05',
    icon: Icons.description,
    color: Color(0xFF2F7AF6),
    category: '租约消息',
  ),
  MockMessage(
    title: '活动优惠提醒',
    content: '您有一张租金优惠券即将过期',
    time: '05-14 09:30',
    icon: Icons.stars,
    color: Color(0xFFF59E0B),
    category: '系统通知',
  ),
];
