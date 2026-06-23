import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ==================== 主题主色 ====================
  /// 主色（品牌色）- 用于主要按钮、导航栏、强调元素
  static const primary = Color(0xFF1E88E5);

  /// 主色深色 - 用于按压状态、深色主题下的主色
  static const primaryDark = Color(0xFF1565C0);

  /// 主色浅色 - 用于标签背景、卡片头部、轻量高亮
  static const primaryLight = Color(0xFFEAF4FF);

  /// 主色柔和 - 用于悬浮状态、hover 背景、次要高亮
  static const primarySoft = Color(0xFFD8E9FF);

  // ==================== 辅助色 ====================
  /// 辅助色（青绿色）- 用于成功状态、已完成标记、辅助按钮
  static const secondary = Color.fromARGB(255, 7, 153, 138);

  // ==================== 背景色 ====================
  /// 页面背景色（纯白）- 用于绝大多数页面背景
  static const background = Color.fromARGB(255, 255, 255, 255);

  /// 认证页面背景色 - 用于登录/注册页面的专属背景，略偏蓝白
  static const authBackground = Color(0xFFF3F8FF);

  /// 卡片/面板表面色（纯白）- 用于卡片、弹窗、底部抽屉等表面
  static const surface = Color(0xFFFFFFFF);

  // ==================== 文本色 ====================
  /// 主要文本色（深灰）- 用于标题、正文等主要文字
  static const textPrimary = Color(0xFF1F2937);

  /// 次要文本色（中灰）- 用于辅助文字、描述、提示
  static const textSecondary = Color.fromARGB(255, 122, 124, 128);

  /// 禁用/占位文本色（浅灰）- 用于占位符、禁用状态的文字
  static const textMuted = Color(0xFF9CA3AF);

  // ==================== 图标色 ====================
  /// 图标默认色（哑光灰）- 用于普通图标、未激活状态
  static const iconMuted = Color(0xFF7B8088);

  // ==================== 边框与分割线 ====================
  /// 通用边框色 - 用于卡片边框、列表分割线
  static const border = Color(0xFFE5E7EB);

  /// 输入框边框色 - 用于表单输入框的边框
  static const inputBorder = Color(0xFFD5DAE1);

  // ==================== 状态反馈色 ====================
  /// 错误/警告红 - 用于错误提示、必填标记、危险操作
  static const error = Color(0xFFD32F2F);

  /// 成功绿 - 用于操作成功反馈、已完成状态
  static const success = Color(0xFF2E7D32);

  /// 警告黄 - 用于警示、待处理状态、等级提醒
  static const warning = Color(0xFFF59E0B);
}
