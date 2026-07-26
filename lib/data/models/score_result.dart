enum ScoreReasonType { positive, negative, neutral }

enum ConfidenceLevel { low, medium, high }

enum ScoreAvailability { available, limited, unavailable }

class ScoreReason {
  const ScoreReason({
    required this.title,
    required this.shortDescription,
    required this.impact,
    required this.type,
    required this.severity,
  });

  final String title;
  final String shortDescription;
  final int impact;
  final ScoreReasonType type;
  final int severity;
}

class ScoreResult {
  const ScoreResult({
    required this.score,
    required this.rating,
    required this.availability,
    required this.confidence,
    required this.reasons,
    required this.hasReliableScore,
  });

  final double? score;
  final String rating;
  final ScoreAvailability availability;
  final ConfidenceLevel confidence;
  final List<ScoreReason> reasons;
  final bool hasReliableScore;

  String get confidenceLabel => switch (confidence) {
    ConfidenceLevel.high => 'High data confidence',
    ConfidenceLevel.medium => 'Medium data confidence',
    ConfidenceLevel.low => 'Limited product data',
  };

  String get availabilityLabel => switch (availability) {
    ScoreAvailability.available => 'Based on available product data.',
    ScoreAvailability.limited => 'Insufficient product data.',
    ScoreAvailability.unavailable => 'Not enough data',
  };
}
