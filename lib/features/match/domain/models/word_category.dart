/// Thematic category for a [Word].
///
/// Difficulty and category are completely independent — a word may be
/// [WordCategory.animals] at [WordDifficulty.easy] or [WordDifficulty.extreme].
enum WordCategory {
  /// Fauna: mammals, birds, fish, insects, etc.
  animals,

  /// Cuisine: ingredients, dishes, utensils, etc.
  food,

  /// Physical objects, tools, household items.
  objects,

  /// Athletic activities and sporting equipment.
  sports,

  /// Natural phenomena, landscapes, plants.
  nature,

  /// Devices, software, programming concepts.
  technology,

  /// Film titles, characters, genres.
  movies,

  /// Pulls from all categories randomly.
  random,
}

/// Extension providing human-readable labels for [WordCategory].
extension WordCategoryLabel on WordCategory {
  /// Returns the display name for this category.
  String get label => switch (this) {
    WordCategory.animals => 'Animals',
    WordCategory.food => 'Food',
    WordCategory.objects => 'Objects',
    WordCategory.sports => 'Sports',
    WordCategory.nature => 'Nature',
    WordCategory.technology => 'Technology',
    WordCategory.movies => 'Movies',
    WordCategory.random => 'Random',
  };
}
