import 'dart:math';

/// Service implementing ranked matchmaking contracts, MMR computations, and tiers.
class RankedService {
  /// Standard Elo calculation determining MMR changes after a match.
  int calculateMmrChange(int playerMmr, int opponentMmr, bool won) {
    const kFactor = 32;
    final expectedScore =
        1.0 / (1.0 + pow(10, (opponentMmr - playerMmr) / 400.0));
    final actualScore = won ? 1.0 : 0.0;
    return (kFactor * (actualScore - expectedScore)).round();
  }

  /// Determines rank placement status (needs 5 games to unlock initial tier).
  String evaluatePlacement(int gamesPlayed, int wins) {
    if (gamesPlayed < 5) {
      return 'Unranked (${5 - gamesPlayed} placements left)';
    }
    final mmrEstimate = 1000 + (wins * 100);
    return evaluateRankTier(mmrEstimate);
  }

  /// Maps numerical MMR values to competitive tiers.
  String evaluateRankTier(int mmr) {
    if (mmr < 800) return 'Bronze I';
    if (mmr < 1000) return 'Bronze II';
    if (mmr < 1200) return 'Silver I';
    if (mmr < 1400) return 'Silver II';
    if (mmr < 1600) return 'Gold I';
    if (mmr < 1800) return 'Gold II';
    if (mmr < 2000) return 'Platinum I';
    if (mmr < 2200) return 'Platinum II';
    return 'Grandmaster';
  }

  /// Applies decay for inactive players (e.g. lose 10 MMR per day of inactivity above Gold).
  int applyDecay(int mmr, int daysInactive) {
    if (mmr < 1200 || daysInactive < 7) return mmr;
    final decayAmount = (daysInactive - 7) * 15;
    return max(1200, mmr - decayAmount);
  }

  /// Resets MMR towards the median (1200) at the start of a new season.
  int applySeasonReset(int previousMmr) {
    // Soft reset: (MMR + 1200) / 2
    return ((previousMmr + 1200) / 2).round();
  }
}
