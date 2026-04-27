import 'chess_logic.dart';

/// A handcrafted puzzle position. The board is built from a compact
/// list of (algebraic-square, piece) pairs to keep the data declarative.
class ChessPuzzle {
  const ChessPuzzle({
    required this.id,
    required this.title,
    required this.objective,
    required this.toMove,
    required this.solutionFrom,
    required this.solutionTo,
    required this.pieces,
    this.difficulty = 'Easy',
  });

  final String id;
  final String title;
  final String objective;
  final PieceColor toMove;
  final String solutionFrom; // e.g. 'd1'
  final String solutionTo;   // e.g. 'h5'
  final String difficulty;
  final List<_PieceAt> pieces;

  /// Builds the 8x8 board for this puzzle.
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
}

class _PieceAt {
  const _PieceAt(this.square, this.color, this.type);
  final String square;
  final PieceColor color;
  final PieceType type;
}

Position _algebraic(String s) {
  final file = s.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(s[1]);
  return Position(8 - rank, file);
}

/// Five sample puzzles ranging from beginner to advanced. The first
/// three are unlocked for free users (one per day, up to the daily
/// limit); the rest require Premium.
const List<ChessPuzzle> kPuzzles = [
  ChessPuzzle(
    id: 'p1',
    title: 'Scholar\'s Mate',
    objective: 'White to play. Mate in 1.',
    difficulty: 'Easy',
    toMove: PieceColor.white,
    solutionFrom: 'h5',
    solutionTo: 'f7',
    pieces: [
      _PieceAt('e1', PieceColor.white, PieceType.king),
      _PieceAt('h5', PieceColor.white, PieceType.queen),
      _PieceAt('c4', PieceColor.white, PieceType.bishop),
      _PieceAt('e4', PieceColor.white, PieceType.pawn),
      _PieceAt('e8', PieceColor.black, PieceType.king),
      _PieceAt('f8', PieceColor.black, PieceType.bishop),
      _PieceAt('d8', PieceColor.black, PieceType.queen),
      _PieceAt('g8', PieceColor.black, PieceType.knight),
      _PieceAt('b8', PieceColor.black, PieceType.knight),
      _PieceAt('a8', PieceColor.black, PieceType.rook),
      _PieceAt('h8', PieceColor.black, PieceType.rook),
      _PieceAt('e5', PieceColor.black, PieceType.pawn),
      _PieceAt('f7', PieceColor.black, PieceType.pawn),
    ],
  ),
  ChessPuzzle(
    id: 'p2',
    title: 'Back-Rank Finish',
    objective: 'White to play. Mate in 1.',
    difficulty: 'Easy',
    toMove: PieceColor.white,
    solutionFrom: 'a1',
    solutionTo: 'a8',
    pieces: [
      _PieceAt('g1', PieceColor.white, PieceType.king),
      _PieceAt('a1', PieceColor.white, PieceType.rook),
      _PieceAt('f2', PieceColor.white, PieceType.pawn),
      _PieceAt('g2', PieceColor.white, PieceType.pawn),
      _PieceAt('h2', PieceColor.white, PieceType.pawn),
      _PieceAt('g8', PieceColor.black, PieceType.king),
      _PieceAt('f7', PieceColor.black, PieceType.pawn),
      _PieceAt('g7', PieceColor.black, PieceType.pawn),
      _PieceAt('h7', PieceColor.black, PieceType.pawn),
    ],
  ),
  ChessPuzzle(
    id: 'p3',
    title: 'Knight Fork',
    objective: 'White to play. Win the queen.',
    difficulty: 'Medium',
    toMove: PieceColor.white,
    solutionFrom: 'e5',
    solutionTo: 'c6',
    pieces: [
      _PieceAt('e1', PieceColor.white, PieceType.king),
      _PieceAt('e5', PieceColor.white, PieceType.knight),
      _PieceAt('e8', PieceColor.black, PieceType.king),
      _PieceAt('a7', PieceColor.black, PieceType.queen),
      _PieceAt('a8', PieceColor.black, PieceType.rook),
    ],
  ),
  ChessPuzzle(
    id: 'p4',
    title: 'Smothered Mate',
    objective: 'White to play. Mate in 1.',
    difficulty: 'Hard',
    toMove: PieceColor.white,
    solutionFrom: 'e6',
    solutionTo: 'f7',
    pieces: [
      _PieceAt('e1', PieceColor.white, PieceType.king),
      _PieceAt('e6', PieceColor.white, PieceType.knight),
      _PieceAt('h8', PieceColor.black, PieceType.king),
      _PieceAt('g8', PieceColor.black, PieceType.rook),
      _PieceAt('h7', PieceColor.black, PieceType.pawn),
      _PieceAt('g7', PieceColor.black, PieceType.pawn),
    ],
  ),
  ChessPuzzle(
    id: 'p5',
    title: 'Queen Sacrifice',
    objective: 'White to play. Mate in 2.',
    difficulty: 'Hard',
    toMove: PieceColor.white,
    solutionFrom: 'd1',
    solutionTo: 'd8',
    pieces: [
      _PieceAt('e1', PieceColor.white, PieceType.king),
      _PieceAt('d1', PieceColor.white, PieceType.queen),
      _PieceAt('a1', PieceColor.white, PieceType.rook),
      _PieceAt('e8', PieceColor.black, PieceType.king),
      _PieceAt('d8', PieceColor.black, PieceType.rook),
      _PieceAt('a7', PieceColor.black, PieceType.pawn),
    ],
  ),
];
