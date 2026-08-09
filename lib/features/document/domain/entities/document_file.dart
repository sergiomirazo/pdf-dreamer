enum DocumentKind { pdf, markdown }

class DocumentFile {
  const DocumentFile({
    required this.path,
    required this.name,
    required this.kind,
    this.markdownContent,
  });

  final String path;
  final String name;
  final DocumentKind kind;
  final String? markdownContent;

  bool get isPdf => kind == DocumentKind.pdf;
  bool get isMarkdown => kind == DocumentKind.markdown;
}
