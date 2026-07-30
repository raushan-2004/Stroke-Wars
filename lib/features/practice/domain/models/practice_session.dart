import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart' as bs;
import 'package:flutter/material.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_configuration.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_statistics.dart';

/// Immutable representation of the complete active Practice session state.
class PracticeSession {
  /// Creates a [PracticeSession].
  const PracticeSession({
    required this.currentMatch,
    this.currentRound,
    this.currentWord,
    required this.canvasState,
    required this.timerState,
    required this.score,
    required this.practiceStatistics,
    required this.configuration,
    this.replayMetadata = '',
  });

  /// The active match aggregate root driving this practice run.
  final Match currentMatch;

  /// The active round state details.
  final Round? currentRound;

  /// The word chosen by the player to draw in this round.
  final Word? currentWord;

  /// Snapshotted state of the canvas strokes.
  final CanvasState canvasState;

  /// Snapshotted state of the round clock.
  final TimerState timerState;

  /// Accumulated player scoreboard score.
  final int score;

  /// Real-time statistics tracked during this practice run.
  final PracticeStatistics practiceStatistics;

  /// The settings used to initialize this session.
  final PracticeConfiguration configuration;

  /// Metadata information about recorded replays.
  final String replayMetadata;

  /// Creates a copy of this session with updated properties.
  PracticeSession copyWith({
    Match? currentMatch,
    Round? Function()? currentRound,
    Word? Function()? currentWord,
    CanvasState? canvasState,
    TimerState? timerState,
    int? score,
    PracticeStatistics? practiceStatistics,
    PracticeConfiguration? configuration,
    String? replayMetadata,
  }) {
    return PracticeSession(
      currentMatch: currentMatch ?? this.currentMatch,
      currentRound: currentRound != null ? currentRound() : this.currentRound,
      currentWord: currentWord != null ? currentWord() : this.currentWord,
      canvasState: canvasState ?? this.canvasState,
      timerState: timerState ?? this.timerState,
      score: score ?? this.score,
      practiceStatistics: practiceStatistics ?? this.practiceStatistics,
      configuration: configuration ?? this.configuration,
      replayMetadata: replayMetadata ?? this.replayMetadata,
    );
  }

  /// Converts this session to a JSON Map.
  Map<String, dynamic> toJson() => {
        'currentMatch': currentMatch.toJson(),
        'currentRound': currentRound?.toJson(),
        'currentWord': currentWord?.toJson(),
        'canvasState': _canvasStateToJson(canvasState),
        'timerState': timerState.toJson(),
        'score': score,
        'practiceStatistics': practiceStatistics.toJson(),
        'configuration': configuration.toJson(),
        'replayMetadata': replayMetadata,
      };

  /// Restores a session from a JSON Map.
  factory PracticeSession.fromJson(Map<String, dynamic> json) =>
      PracticeSession(
        currentMatch: Match.fromJson(json['currentMatch'] as Map<String, dynamic>),
        currentRound: json['currentRound'] != null
            ? Round.fromJson(json['currentRound'] as Map<String, dynamic>)
            : null,
        currentWord: json['currentWord'] != null
            ? Word.fromJson(json['currentWord'] as Map<String, dynamic>)
            : null,
        canvasState: _canvasStateFromJson(json['canvasState'] as Map<String, dynamic>),
        timerState: TimerState.fromJson(json['timerState'] as Map<String, dynamic>),
        score: json['score'] as int? ?? 0,
        practiceStatistics: PracticeStatistics.fromJson(
            json['practiceStatistics'] as Map<String, dynamic>),
        configuration: PracticeConfiguration.fromJson(
            json['configuration'] as Map<String, dynamic>),
        replayMetadata: json['replayMetadata'] as String? ?? '',
      );

  static Map<String, dynamic> _canvasStateToJson(CanvasState state) {
    return {
      'strokes': state.strokes.map((s) => s.toJson()).toList(),
      'canUndo': state.canUndo,
      'canRedo': state.canRedo,
      'selectedBrush': {
        'type': state.selectedBrush.type.name,
        'size': state.selectedBrush.size,
        'opacity': state.selectedBrush.opacity,
        'color': state.selectedBrush.color.value,
      }
    };
  }

  static CanvasState _canvasStateFromJson(Map<String, dynamic> json) {
    final brushJson = json['selectedBrush'] as Map<String, dynamic>?;
    final selectedBrush = brushJson != null
        ? BrushSettings(
            type: bs.BrushType.values.firstWhere((e) => e.name == brushJson['type']),
            size: (brushJson['size'] as num).toDouble(),
            opacity: (brushJson['opacity'] as num).toDouble(),
            color: Color(brushJson['color'] as int),
          )
        : CanvasState.initial().selectedBrush;

    return CanvasState(
      strokes: (json['strokes'] as List<dynamic>)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      transform: Matrix4.identity(),
      selectedBrush: selectedBrush,
      canUndo: json['canUndo'] as bool? ?? false,
      canRedo: json['canRedo'] as bool? ?? false,
    );
  }
}
