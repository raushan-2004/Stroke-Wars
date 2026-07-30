import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';
import 'package:stroke_wars/features/match/domain/repositories/word_repository.dart';

/// In-memory [WordRepository] backed by a curated default word list.
///
/// This is the seed data source for Practice Mode and offline matches.
/// Swap it for a server-backed implementation for online ranked modes.
class DefaultWordList implements WordRepository {
  /// Creates a [DefaultWordList] with the built-in word set.
  const DefaultWordList();

  @override
  Future<List<Word>> getWords({
    WordDifficulty? difficulty,
    WordCategory? category,
    int count = 3,
  }) async {
    var filtered = _words.where((w) {
      final diffMatch = difficulty == null || w.difficulty == difficulty;
      final catMatch = category == null ||
          category == WordCategory.random ||
          w.category == category;
      return diffMatch && catMatch;
    }).toList();

    if (filtered.isEmpty) filtered = List.from(_words);
    return filtered.take(count).toList();
  }

  @override
  Future<List<Word>> getWordsByIds(List<String> ids) async =>
      _words.where((w) => ids.contains(w.id)).toList();

  @override
  Future<List<WordCategory>> getAvailableCategories() async =>
      WordCategory.values.toList();

  @override
  Future<List<WordDifficulty>> getAvailableDifficulties() async =>
      WordDifficulty.values.toList();

  /// The complete built-in word list.
  static const List<Word> words = _words;

  static const List<Word> _words = [
    // ─── ANIMALS — Easy ──────────────────────────────────────────────────────
    Word(id: 'a_easy_01', text: 'Cat', difficulty: WordDifficulty.easy, category: WordCategory.animals, hints: ['It purrs', 'Has whiskers']),
    Word(id: 'a_easy_02', text: 'Dog', difficulty: WordDifficulty.easy, category: WordCategory.animals, hints: ['Man\'s best friend', 'Barks']),
    Word(id: 'a_easy_03', text: 'Fish', difficulty: WordDifficulty.easy, category: WordCategory.animals, hints: ['Lives in water', 'Has fins']),
    Word(id: 'a_easy_04', text: 'Bird', difficulty: WordDifficulty.easy, category: WordCategory.animals, hints: ['Has feathers', 'Can fly']),
    Word(id: 'a_easy_05', text: 'Cow', difficulty: WordDifficulty.easy, category: WordCategory.animals, hints: ['Gives milk', 'Moos']),
    // ─── ANIMALS — Medium ────────────────────────────────────────────────────
    Word(id: 'a_med_01', text: 'Penguin', difficulty: WordDifficulty.medium, category: WordCategory.animals, hints: ['Lives in Antarctica', 'Waddles']),
    Word(id: 'a_med_02', text: 'Kangaroo', difficulty: WordDifficulty.medium, category: WordCategory.animals, hints: ['Has a pouch', 'From Australia']),
    Word(id: 'a_med_03', text: 'Giraffe', difficulty: WordDifficulty.medium, category: WordCategory.animals, hints: ['Long neck', 'Tallest animal']),
    Word(id: 'a_med_04', text: 'Dolphin', difficulty: WordDifficulty.medium, category: WordCategory.animals, hints: ['Lives in the ocean', 'Very smart']),
    // ─── ANIMALS — Hard ──────────────────────────────────────────────────────
    Word(id: 'a_hard_01', text: 'Platypus', difficulty: WordDifficulty.hard, category: WordCategory.animals, hints: ['Lays eggs', 'Has a duck bill']),
    Word(id: 'a_hard_02', text: 'Axolotl', difficulty: WordDifficulty.hard, category: WordCategory.animals, hints: ['Mexican salamander', 'Can regenerate limbs']),
    Word(id: 'a_hard_03', text: 'Narwhal', difficulty: WordDifficulty.hard, category: WordCategory.animals, hints: ['Has a tusk', 'Lives in Arctic waters']),
    // ─── FOOD — Easy ─────────────────────────────────────────────────────────
    Word(id: 'f_easy_01', text: 'Pizza', difficulty: WordDifficulty.easy, category: WordCategory.food, hints: ['Round', 'Has cheese']),
    Word(id: 'f_easy_02', text: 'Apple', difficulty: WordDifficulty.easy, category: WordCategory.food, hints: ['Red or green', 'A fruit']),
    Word(id: 'f_easy_03', text: 'Cake', difficulty: WordDifficulty.easy, category: WordCategory.food, hints: ['Birthday staple', 'Sweet']),
    Word(id: 'f_easy_04', text: 'Bread', difficulty: WordDifficulty.easy, category: WordCategory.food, hints: ['Baked', 'Goes with butter']),
    Word(id: 'f_easy_05', text: 'Egg', difficulty: WordDifficulty.easy, category: WordCategory.food, hints: ['Oval shape', 'Laid by chickens']),
    // ─── FOOD — Medium ───────────────────────────────────────────────────────
    Word(id: 'f_med_01', text: 'Sushi', difficulty: WordDifficulty.medium, category: WordCategory.food, hints: ['Japanese dish', 'Contains rice']),
    Word(id: 'f_med_02', text: 'Burrito', difficulty: WordDifficulty.medium, category: WordCategory.food, hints: ['Wrapped in a tortilla', 'Mexican food']),
    Word(id: 'f_med_03', text: 'Waffle', difficulty: WordDifficulty.medium, category: WordCategory.food, hints: ['Has a grid pattern', 'Breakfast food']),
    Word(id: 'f_med_04', text: 'Avocado', difficulty: WordDifficulty.medium, category: WordCategory.food, hints: ['Green inside', 'Makes guacamole']),
    // ─── FOOD — Hard ─────────────────────────────────────────────────────────
    Word(id: 'f_hard_01', text: 'Quiche', difficulty: WordDifficulty.hard, category: WordCategory.food, hints: ['French dish', 'A savory tart']),
    Word(id: 'f_hard_02', text: 'Croissant', difficulty: WordDifficulty.hard, category: WordCategory.food, hints: ['Crescent shaped', 'French pastry']),
    // ─── OBJECTS — Easy ──────────────────────────────────────────────────────
    Word(id: 'o_easy_01', text: 'Chair', difficulty: WordDifficulty.easy, category: WordCategory.objects, hints: ['You sit on it', 'Has legs']),
    Word(id: 'o_easy_02', text: 'Clock', difficulty: WordDifficulty.easy, category: WordCategory.objects, hints: ['Tells the time', 'Has hands']),
    Word(id: 'o_easy_03', text: 'Book', difficulty: WordDifficulty.easy, category: WordCategory.objects, hints: ['You read it', 'Has pages']),
    Word(id: 'o_easy_04', text: 'Lamp', difficulty: WordDifficulty.easy, category: WordCategory.objects, hints: ['Gives light', 'Plugs in']),
    // ─── OBJECTS — Medium ────────────────────────────────────────────────────
    Word(id: 'o_med_01', text: 'Telescope', difficulty: WordDifficulty.medium, category: WordCategory.objects, hints: ['Used to see far', 'Points at stars']),
    Word(id: 'o_med_02', text: 'Compass', difficulty: WordDifficulty.medium, category: WordCategory.objects, hints: ['Helps you navigate', 'Points north']),
    Word(id: 'o_med_03', text: 'Hourglass', difficulty: WordDifficulty.medium, category: WordCategory.objects, hints: ['Measures time', 'Uses sand']),
    // ─── OBJECTS — Hard ──────────────────────────────────────────────────────
    Word(id: 'o_hard_01', text: 'Periscope', difficulty: WordDifficulty.hard, category: WordCategory.objects, hints: ['Used in submarines', 'Uses mirrors']),
    Word(id: 'o_hard_02', text: 'Abacus', difficulty: WordDifficulty.hard, category: WordCategory.objects, hints: ['Ancient calculator', 'Uses beads']),
    // ─── SPORTS — Easy ───────────────────────────────────────────────────────
    Word(id: 's_easy_01', text: 'Soccer', difficulty: WordDifficulty.easy, category: WordCategory.sports, hints: ['Round ball', 'Most popular sport']),
    Word(id: 's_easy_02', text: 'Tennis', difficulty: WordDifficulty.easy, category: WordCategory.sports, hints: ['Uses a racket', 'Ball goes over a net']),
    Word(id: 's_easy_03', text: 'Swimming', difficulty: WordDifficulty.easy, category: WordCategory.sports, hints: ['Done in water', 'Use your arms and legs']),
    // ─── SPORTS — Medium ─────────────────────────────────────────────────────
    Word(id: 's_med_01', text: 'Archery', difficulty: WordDifficulty.medium, category: WordCategory.sports, hints: ['Uses a bow', 'Aim at a target']),
    Word(id: 's_med_02', text: 'Fencing', difficulty: WordDifficulty.medium, category: WordCategory.sports, hints: ['Uses a sword', 'Olympic sport']),
    Word(id: 's_med_03', text: 'Bobsled', difficulty: WordDifficulty.medium, category: WordCategory.sports, hints: ['Winter sport', 'Slides down ice']),
    // ─── SPORTS — Hard ───────────────────────────────────────────────────────
    Word(id: 's_hard_01', text: 'Curling', difficulty: WordDifficulty.hard, category: WordCategory.sports, hints: ['Played on ice', 'Uses a broom']),
    Word(id: 's_hard_02', text: 'Dressage', difficulty: WordDifficulty.hard, category: WordCategory.sports, hints: ['Involves a horse', 'Precision riding']),
    // ─── NATURE — Easy ───────────────────────────────────────────────────────
    Word(id: 'n_easy_01', text: 'Tree', difficulty: WordDifficulty.easy, category: WordCategory.nature, hints: ['Has leaves', 'Grows in soil']),
    Word(id: 'n_easy_02', text: 'Cloud', difficulty: WordDifficulty.easy, category: WordCategory.nature, hints: ['In the sky', 'Holds rain']),
    Word(id: 'n_easy_03', text: 'Rain', difficulty: WordDifficulty.easy, category: WordCategory.nature, hints: ['Falls from clouds', 'Wet']),
    Word(id: 'n_easy_04', text: 'Mountain', difficulty: WordDifficulty.easy, category: WordCategory.nature, hints: ['Very tall', 'Has a peak']),
    // ─── NATURE — Medium ─────────────────────────────────────────────────────
    Word(id: 'n_med_01', text: 'Volcano', difficulty: WordDifficulty.medium, category: WordCategory.nature, hints: ['Erupts lava', 'Cone-shaped mountain']),
    Word(id: 'n_med_02', text: 'Glacier', difficulty: WordDifficulty.medium, category: WordCategory.nature, hints: ['Huge ice mass', 'Moves slowly']),
    Word(id: 'n_med_03', text: 'Aurora', difficulty: WordDifficulty.medium, category: WordCategory.nature, hints: ['Northern lights', 'Colorful sky display']),
    // ─── NATURE — Hard ───────────────────────────────────────────────────────
    Word(id: 'n_hard_01', text: 'Stalactite', difficulty: WordDifficulty.hard, category: WordCategory.nature, hints: ['Hangs from cave ceiling', 'Made of limestone']),
    Word(id: 'n_hard_02', text: 'Sinkhole', difficulty: WordDifficulty.hard, category: WordCategory.nature, hints: ['Ground collapses', 'Circular hole']),
    // ─── TECHNOLOGY — Easy ───────────────────────────────────────────────────
    Word(id: 't_easy_01', text: 'Phone', difficulty: WordDifficulty.easy, category: WordCategory.technology, hints: ['You call people', 'Has a screen']),
    Word(id: 't_easy_02', text: 'Robot', difficulty: WordDifficulty.easy, category: WordCategory.technology, hints: ['Machine that moves', 'Often metallic']),
    Word(id: 't_easy_03', text: 'Laptop', difficulty: WordDifficulty.easy, category: WordCategory.technology, hints: ['Portable computer', 'Has a keyboard']),
    // ─── TECHNOLOGY — Medium ─────────────────────────────────────────────────
    Word(id: 't_med_01', text: 'Satellite', difficulty: WordDifficulty.medium, category: WordCategory.technology, hints: ['Orbits Earth', 'Used for GPS']),
    Word(id: 't_med_02', text: 'Microchip', difficulty: WordDifficulty.medium, category: WordCategory.technology, hints: ['Tiny circuit', 'Inside computers']),
    Word(id: 't_med_03', text: 'Submarine', difficulty: WordDifficulty.medium, category: WordCategory.technology, hints: ['Travels underwater', 'Military vessel']),
    // ─── TECHNOLOGY — Hard ───────────────────────────────────────────────────
    Word(id: 't_hard_01', text: 'Transistor', difficulty: WordDifficulty.hard, category: WordCategory.technology, hints: ['Electronic component', 'Amplifies signals']),
    Word(id: 't_hard_02', text: 'Hologram', difficulty: WordDifficulty.hard, category: WordCategory.technology, hints: ['3D light projection', 'No solid form']),
    // ─── MOVIES — Easy ───────────────────────────────────────────────────────
    Word(id: 'm_easy_01', text: 'Superhero', difficulty: WordDifficulty.easy, category: WordCategory.movies, hints: ['Wears a cape', 'Saves the world']),
    Word(id: 'm_easy_02', text: 'Dragon', difficulty: WordDifficulty.easy, category: WordCategory.movies, hints: ['Breathes fire', 'Has wings']),
    Word(id: 'm_easy_03', text: 'Pirate', difficulty: WordDifficulty.easy, category: WordCategory.movies, hints: ['Sails the seas', 'Has an eyepatch']),
    // ─── MOVIES — Medium ─────────────────────────────────────────────────────
    Word(id: 'm_med_01', text: 'Spaceship', difficulty: WordDifficulty.medium, category: WordCategory.movies, hints: ['Travels in space', 'Science fiction']),
    Word(id: 'm_med_02', text: 'Vampire', difficulty: WordDifficulty.medium, category: WordCategory.movies, hints: ['Avoids sunlight', 'Drinks blood']),
    Word(id: 'm_med_03', text: 'Wizard', difficulty: WordDifficulty.medium, category: WordCategory.movies, hints: ['Casts spells', 'Carries a wand']),
    // ─── MOVIES — Hard ───────────────────────────────────────────────────────
    Word(id: 'm_hard_01', text: 'Cliffhanger', difficulty: WordDifficulty.hard, category: WordCategory.movies, hints: ['Suspenseful scene', 'Leaves you waiting']),
    Word(id: 'm_hard_02', text: 'MacGuffin', difficulty: WordDifficulty.hard, category: WordCategory.movies, hints: ['Plot device object', 'Drives the story']),
  ];
}
