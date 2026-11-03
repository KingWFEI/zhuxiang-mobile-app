import '../../app/config/app_config.dart';

/// 将后端返回的图片路径解析成手机可访问的完整地址。
///
/// 完整的 HTTP(S) 地址保持不变；相对路径则根据当前 API 主机补齐。
String resolveImageUrl(String? imageUrl) {
  final value = imageUrl?.trim() ?? '';
  if (value.isEmpty) return value;

  final imageUri = Uri.tryParse(value);
  final apiBaseUri = Uri.tryParse(AppConfig.baseUrl);
  if (imageUri == null || apiBaseUri == null || !apiBaseUri.hasAuthority) {
    return value;
  }

  if (imageUri.hasScheme) return value;
  if (value.startsWith('//')) return '${apiBaseUri.scheme}:$value';

  final apiPath = apiBaseUri.path.replaceFirst(RegExp(r'/+$'), '');
  final originUri = apiBaseUri.replace(path: '', query: null, fragment: null);
  final imagePath = imageUri.path.startsWith('/')
      ? imageUri.path
      : '/${imageUri.path}';
  final normalizedImageUri = imageUri.replace(path: imagePath);

  // 服务端返回 /api/uploads/... 时，API 前缀已经包含在图片路径中。
  if (apiPath.isNotEmpty &&
      (imagePath == apiPath || imagePath.startsWith('$apiPath/'))) {
    return originUri.resolveUri(normalizedImageUri).toString();
  }

  // 兼容只返回 /uploads/... 的服务端配置，补上应用 API 前缀。
  if (apiPath.isNotEmpty && imagePath.startsWith('/uploads/')) {
    return originUri
        .resolveUri(normalizedImageUri.replace(path: '$apiPath$imagePath'))
        .toString();
  }

  if (value.startsWith('/')) {
    return originUri.resolveUri(imageUri).toString();
  }

  final basePath = apiPath.isEmpty ? '/' : '$apiPath/';
  return apiBaseUri.replace(path: basePath).resolveUri(imageUri).toString();
}
