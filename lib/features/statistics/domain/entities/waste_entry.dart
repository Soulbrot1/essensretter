class WasteEntry {
  final String id;
  final String name;
  final String? category;
  final DateTime deletedDate;

  const WasteEntry({
    required this.id,
    required this.name,
    this.category,
    required this.deletedDate,
  });
}
