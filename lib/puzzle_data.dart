import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'chess_logic.dart';

/// A single, hand-rendered puzzle position. The board is built from a
/// compact list of (algebraic-square, piece) tuples.
class ChessPuzzle {
  const ChessPuzzle({
    required this.id,
    required this.title,
    required this.objective,
    required this.difficulty,
    required this.theme,
    required this.toMove,
    required this.solutionFrom,
    required this.solutionTo,
    required this.pieces,
  });

  final String id;
  final String title;
  final String objective;
  final String difficulty;
  final String theme;
  final PieceColor toMove;
  final String solutionFrom;
  final String solutionTo;
  final List<PuzzlePiece> pieces;

  List<List<ChessPiece?>> buildBoard() {
    final board = List.generate(
      8,
      (_) => List<ChessPiece?>.filled(8, null, growable: false),
      growable: false,
    );
    for (final p in pieces) {
      final pos = _algebraic(p.square);
      board[pos.row][pos.col] = ChessPiece(color: p.color, type: p.type);
    }
    return board;
  }

  Position get solutionFromPos => _algebraic(solutionFrom);
  Position get solutionToPos => _algebraic(solutionTo);

  factory ChessPuzzle.fromJson(Map<String, dynamic> json) {
    return ChessPuzzle(
      id: json['id'] as String,
      title: json['title'] as String,
      objective: json['objective'] as String,
      difficulty: json['difficulty'] as String? ?? 'Easy',
      theme: json['theme'] as String? ?? 'tactic',
      toMove: _color(json['toMove'] as String),
      solutionFrom: json['solutionFrom'] as String,
      solutionTo: json['solutionTo'] as String,
      pieces: (json['pieces'] as List)
          .map((e) => PuzzlePiece.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class PuzzlePiece {
  const PuzzlePiece({
    required this.square,
    required this.color,
    required this.type,
  });

  final String square;
  final PieceColor color;
  final PieceType type;

  factory PuzzlePiece.fromJson(Map<String, dynamic> json) {
    return PuzzlePiece(
      square: json['square'] as String,
      color: _color(json['color'] as String),
      type: _type(json['type'] as String),
    );
  }
}

PieceColor _color(String s) =>
    s == 'white' ? PieceColor.white : PieceColor.black;

PieceType _type(String s) {
  switch (s) {
    case 'king':   return PieceType.king;
    case 'queen':  return PieceType.queen;
    case 'rook':   return PieceType.rook;
    case 'bishop': return PieceType.bishop;
    case 'knight': return PieceType.knight;
    case 'pawn':   return PieceType.pawn;
  }
  throw ArgumentError('Unknown piece type: $s');
}

Position _algebraic(String s) {
  final file = s.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(s[1]);
  return Position(8 - rank, file);
}

/// Loads the bundled 365-puzzle archive lazily and exposes the
/// "today's puzzle" lookup used by the free tier.
class PuzzleRepository {
  PuzzleRepository._();
  static final PuzzleRepository instance = PuzzleRepository._();

  static const String _assetPath = 'assets/puzzles.json';

  List<ChessPuzzle>? _cached;
  Future<List<ChessPuzzle>>? _loading;

  /// All puzzles in the archive, in deterministic order. The list has
  /// exactly 365 entries (or whatever the bundled JSON contains).
  Future<List<ChessPuzzle>> all() {
    if (_cached != null) return Future.value(_cached);
    return _loading ??= _load();
  }

  Future<List<ChessPuzzle>> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = (json.decode(raw) as List)
        .map((e) => ChessPuzzle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _cached = list;
    return list;
  }

  /// Today's puzzle, deterministically indexed by day-of-year so every
  /// install on the same calendar day sees the same one.
  Future<ChessPuzzle> todays() async {
    final all0 = await all();
    return all0[_dayOfYearIndex(all0.length)];
  }

  /// Index into [all] for [date] (defaults to today).
  int _dayOfYearIndex(int length, [DateTime? date]) {
    final d = date ?? DateTime.now();
    final start = DateTime(d.year, 1, 1);
    final dayOfYear = d.difference(start).inDays; // 0-based
    return dayOfYear % length;
  }

  /// Public helper — useful for the archive view to mark which entry
  /// is "today".
  Future<int> todaysIndex() async {
    final all0 = await all();
    return _dayOfYearIndex(all0.length);
  }
}
