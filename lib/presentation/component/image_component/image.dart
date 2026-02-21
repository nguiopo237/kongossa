 import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart'; // Optionnel

class CustomImage extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageType type;
  final Color? color;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool fadeInDuration;
  final Duration? fadeOutDuration;
  final bool useOldImageOnUrlChange;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? placeholderColor;
  final void Function()? onpress;
  final List<BoxShadow>? boxShadow;

  const CustomImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.type = ImageType.network,
    this.color,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = true,
    this.fadeOutDuration,
    this.useOldImageOnUrlChange = false,
    this.borderRadius = 0,
    this.backgroundColor,
    this.onpress,
    this.placeholderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }

  Widget _buildImage() {
    switch (type) {
      case ImageType.network:
        return _buildNetworkImage();

      case ImageType.cachedNetwork:
        return _buildCachedNetworkImage();

      case ImageType.asset:
        return Image.asset(
          source,
          width: width,
          height: height,
          fit: fit,
          color: color,
          alignment: alignment,
        );

      case ImageType.file:
        return Image.file(
          File(source),
          width: width,
          height: height,
          fit: fit,
          color: color,
          alignment: alignment,
        );

      case ImageType.circle:
        return ClipOval(
          child: _buildCachedNetworkImage(),
        );

      case ImageType.rounded:
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 12),
          child: _buildCachedNetworkImage(),
        );

      case ImageType.avatar:
        return CircleAvatar(
          radius: width != null ? width! / 2 : 24,
          backgroundColor: backgroundColor ?? Colors.grey.shade300,
          child: ClipOval(
            child: _buildCachedNetworkImage(),
          ),
        );

      case ImageType.icon:
        return Container(
          width: width ?? 40,
          height: height ?? 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 8),
            color: backgroundColor ?? Colors.grey.shade100,
          ),
          child: Center(
            child: _buildCachedNetworkImage(customFit: BoxFit.contain),
          ),
        );

      case ImageType.banner:
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 16),
          child: SizedBox(
            width: width ?? double.infinity,
            height: height ?? 200,
            child: _buildCachedNetworkImage(),
          ),
        );

      case ImageType.thumbnail:
        return Container(
          width: width ?? 80,
          height: height ?? 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: boxShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 7),
            child: _buildCachedNetworkImage(),
          ),
        );

      case ImageType.hero:
        return Hero(
          tag: source,
          child: _buildCachedNetworkImage(),
        );

      case ImageType.withShadow:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 12),
            boxShadow: boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius > 0 ? borderRadius : 12),
            child: _buildCachedNetworkImage(),
          ),
        );

      case ImageType.placeholder:
        return Container(
          width: width,
          height: height,
          color: placeholderColor ?? Colors.grey.shade200,
          child: placeholder ??
              const Icon(
                Icons.image,
                color: Colors.grey,
                size: 40,
              ),
        );

      case ImageType.shimmer:
        return _buildShimmerPlaceholder();
    }
  }

  Widget _buildNetworkImage({BoxFit? customFit}) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: customFit ?? fit,
      color: color,
      alignment: alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildDefaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildCachedNetworkImage({BoxFit? customFit}) {
    return InkWell(
      onTap: onpress,
      child: CachedNetworkImage(
        imageUrl: source,
        width: width,
        height: height,
        fit: customFit ?? fit,
        color: color,
        alignment: alignment,
        placeholder: (context, url) {
          return placeholder ?? _buildDefaultPlaceholder();
        },
        errorWidget: (context, url, error) {
          return errorWidget ?? _buildErrorPlaceholder();
        },
        fadeInDuration: fadeInDuration ? const Duration(milliseconds: 300) : Duration.zero,
        fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 300),
        fadeInCurve: Curves.easeIn,
        fadeOutCurve: Curves.easeOut,
        useOldImageOnUrlChange: useOldImageOnUrlChange,
        imageBuilder: borderRadius > 0 && type == ImageType.network
            ? (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            image: DecorationImage(
              image: imageProvider,
              fit: customFit ?? fit,
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child:  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

enum ImageType {
  network,          // Image.network standard
  cachedNetwork,    // CachedNetworkImage optimisé
  asset,            // Asset image
  file,             // File image
  circle,           // Image circulaire
  rounded,          // Coins arrondis
  avatar,           // Avatar utilisateur
  icon,             // Icône
  banner,           // Bannière
  thumbnail,        // Miniature
  hero,             // Avec animation Hero
  withShadow,       // Avec ombre portée
  placeholder,      // Placeholder
  shimmer,          // Placeholder animé (shimmer)
}