class AppLegalDocument {
  const AppLegalDocument({
    required this.documentType,
    required this.title,
    required this.contentMarkdown,
    required this.updatedAt,
  });

  final String documentType;
  final String title;
  final String contentMarkdown;
  final String updatedAt;

  factory AppLegalDocument.fromJson(Map<String, dynamic> json) {
    return AppLegalDocument(
      documentType: json['documentType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contentMarkdown: json['contentMarkdown'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
