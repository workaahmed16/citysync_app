/// Service for searching and filtering locations
class LocationSearchService {
  /// Check if a location matches the search query
  /// Searches in name, description, and address fields
  static bool matchesSearch(
      Map<String, dynamic> locationData,
      String searchQuery,
      ) {
    if (searchQuery.isEmpty) return true;

    final query = searchQuery.toLowerCase();
    final name = (locationData['name'] ?? '').toString().toLowerCase();
    final description = (locationData['description'] ?? '').toString().toLowerCase();
    final address = (locationData['address'] ?? '').toString().toLowerCase();

    return name.contains(query) ||
        description.contains(query) ||
        address.contains(query);
  }

  /// Filter multiple locations by search query
  static List<Map<String, dynamic>> filterBySearch(
      List<Map<String, dynamic>> locations,
      String searchQuery,
      ) {
    return locations
        .where((location) => matchesSearch(location, searchQuery))
        .toList();
  }

  /// Get search result count information
  static String getSearchSummary(
      int totalResults,
      int displayedResults,
      String searchQuery,
      ) {
    if (searchQuery.isEmpty) {
      return 'Showing $displayedResults locations';
    }
    return 'Found $totalResults results for "$searchQuery" (showing $displayedResults)';
  }
}