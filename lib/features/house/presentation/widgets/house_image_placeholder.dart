import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';

// class HouseImagePlaceholder extends StatelessWidget {
//   const HouseImagePlaceholder({
//     super.key,
//     this.imageUrl,
//     this.height,
//     this.borderRadius,
//   });

//   final String? imageUrl;
//   final double? height;
//   final BorderRadius? borderRadius;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: height,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(AppRadius.xl),
//           topRight: Radius.circular(AppRadius.xl),
//         ),
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFFF3E7D8), Color(0xFFEAF4FF)],
//         ),
//       ),
//       child: Image.asset(
//         'assets/images/house_placeholder.png',
//         fit: BoxFit.cover,
//       ),
//     );
//   }
// }
class HouseImagePlaceholder extends StatelessWidget {
  const HouseImagePlaceholder({
    super.key,
    this.coverImage,
    this.height,
    this.borderRadius,
  });
  final String? coverImage;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = coverImage;
    final radius =
        borderRadius ??
        BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        );

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E7D8), Color(0xFFEAF4FF)],
        ),
      ),
      child: imageUrl == null || imageUrl.isEmpty
          ? const _ImageFallback()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: height,
              width: double.infinity,
              cacheWidth: 480,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const _ImageFallback(),
            ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.apartment_rounded, color: Color(0xFF9CA3AF), size: 42),
    );
  }
}
