// ─── Chess Logic ───────────────────────────────────────────────────────────

enum PieceColor { white, black }
enum PieceType { king, queen, rook, bishop, knight, pawn }

class ChessPiece {
  final PieceColor color;
  final PieceType type;

  const ChessPiece({required this.color, required this.type});

  String get symbol {
    const symbols = {
      PieceType.king:   ['♔', '♚'],
      PieceType.queen:  ['♕', '♛'],
      PieceType.rook:   ['♖', '♜'],
      PieceType.bishop: ['♗', '♝'],
      PieceType.knight: ['♘', '♞'],
      PieceType.pawn:   ['♙', '♟'],
    };
    return symbols[type]![color == PieceColor.white ? 0 : 1];
  }

  ChessPiece copyWith({PieceColor? color, PieceType? type}) =>
      ChessPiece(color: color ?? this.color, type: type ?? this.type);
}

class Position {
  final int row;
  final int col;
  const Position(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;
  @override
  int get hashCode => row * 8 + col;

  @override
  String toString() => '${'abcdefgh'[col]}${8 - row}';
}

class Move {
  final Position from;
  final Position to;
  final ChessPiece? captured;
  final bool isCastling;
  final bool isEnPassant;
  final PieceType? promotionType;
  final String notation;

  const Move({
    required this.from,
    required this.to,
    this.captured,
    this.isCastling = false,
    this.isEnPassant = false,
    this.promotionType,
    this.notation = '',
  });
}

class ChessLogic {
  static List<List<ChessPiece?>> initialBoard() {
    final board = List.generate(
        8, (_) => List<ChessPiece?>.filled(8, null, growable: false),
        growable: false);
    const backRank = [
      PieceType.rook, PieceType.knight, PieceType.bishop, PieceType.queen,
      PieceType.king, PieceType.bishop, PieceType.knight, PieceType.rook,
    ];
    for (int c = 0; c < 8; c++) {
      board[0][c] = ChessPiece(color: PieceColor.black, type: backRank[c]);
      board[1][c] = ChessPiece(color: PieceColor.black, type: PieceType.pawn);
      board[6][c] = ChessPiece(color: PieceColor.white, type: PieceType.pawn);
      board[7][c] = ChessPiece(color: PieceColor.white, type: backRank[c]);
    }
    return board;
  }

  static Map<String, bool> initialCastlingRights() =>
      {'wK': true, 'wQ': true, 'bK': true, 'bQ': true};

  static List<Position> getRawMoves(
      List<List<ChessPiece?>> board, Position pos, Position? enPassantTarget) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    final moves = <Position>[];
    final color = piece.color;
    final enemy = color == PieceColor.white ? PieceColor.black : PieceColor.white;

    bool addIfValid(int r, int c) {
      final p = Position(r, c);
      if (!p.isValid) return false;
      final t = board[r][c];
      if (t == null) { moves.add(p); return true; }
      if (t.color == enemy) { moves.add(p); return false; }
      return false;
    }

    void slide(List<List<int>> dirs) {
      for (final d in dirs) {
        int r = pos.row + d[0], c = pos.col + d[1];
        while (addIfValid(r, c)) { r += d[0]; c += d[1]; }
      }
    }

    switch (piece.type) {
      case PieceType.rook:   slide([[1,0],[-1,0],[0,1],[0,-1]]); break;
      case PieceType.bishop: slide([[1,1],[1,-1],[-1,1],[-1,-1]]); break;
      case PieceType.queen:  slide([[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]); break;
      case PieceType.knight:
        for (final d in [[2,1],[2,-1],[-2,1],[-2,-1],[1,2],[1,-2],[-1,2],[-1,-2]])
          addIfValid(pos.row + d[0], pos.col + d[1]);
        break;
      case PieceType.king:
        for (final d in [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]])
          addIfValid(pos.row + d[0], pos.col + d[1]);
        break;
      case PieceType.pawn:
        final dir = color == PieceColor.white ? -1 : 1;
        final startRow = color == PieceColor.white ? 6 : 1;
        if (Position(pos.row + dir, pos.col).isValid && board[pos.row + dir][pos.col] == null) {
          moves.add(Position(pos.row + dir, pos.col));
          if (pos.row == startRow && board[pos.row + 2 * dir][pos.col] == null)
            moves.add(Position(pos.row + 2 * dir, pos.col));
        }
        for (final dc in [-1, 1]) {
          final r = pos.row + dir; final c = pos.col + dc;
          if (Position(r, c).isValid) {
            if (board[r][c]?.color == enemy) moves.add(Position(r, c));
            if (enPassantTarget != null && enPassantTarget.row == r && enPassantTarget.col == c)
              moves.add(Position(r, c));
          }
        }
        break;
    }
    return moves;
  }

  static bool isKingInCheck(List<List<ChessPiece?>> board, PieceColor color) {
    Position? kingPos;
    for (int r = 0; r < 8 && kingPos == null; r++)
      for (int c = 0; c < 8; c++)
        if (board[r][c]?.color == color && board[r][c]?.type == PieceType.king)
          { kingPos = Position(r, c); break; }
    if (kingPos == null) return false;
    final enemy = color == PieceColor.white ? PieceColor.black : PieceColor.white;
    for (int r = 0; r < 8; r++)
      for (int c = 0; c < 8; c++)
        if (board[r][c]?.color == enemy &&
            getRawMoves(board, Position(r, c), null).contains(kingPos))
          return true;
    return false;
  }

  static List<Position> getLegalMoves(
      List<List<ChessPiece?>> board, Position pos,
      Position? enPassantTarget, Map<String, bool> castlingRights) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    final legal = <Position>[];
    for (final to in getRawMoves(board, pos, enPassantTarget)) {
      final nb = _applyMoveToBoard(board, pos, to, enPassantTarget);
      if (!isKingInCheck(nb, piece.color)) legal.add(to);
    }

    // Castling
    if (piece.type == PieceType.king && !isKingInCheck(board, piece.color)) {
      final prefix = piece.color == PieceColor.white ? 'w' : 'b';
      final row = piece.color == PieceColor.white ? 7 : 0;
      if (castlingRights['${prefix}K'] == true &&
          board[row][5] == null && board[row][6] == null &&
          !_isSquareAttacked(board, Position(row, 5), piece.color) &&
          !_isSquareAttacked(board, Position(row, 6), piece.color))
        legal.add(Position(row, 6));
      if (castlingRights['${prefix}Q'] == true &&
          board[row][3] == null && board[row][2] == null && board[row][1] == null &&
          !_isSquareAttacked(board, Position(row, 3), piece.color) &&
          !_isSquareAttacked(board, Position(row, 2), piece.color))
        legal.add(Position(row, 2));
    }
    return legal;
  }

  static bool _isSquareAttacked(
      List<List<ChessPiece?>> board, Position pos, PieceColor defenderColor) {
    final enemy = defenderColor == PieceColor.white ? PieceColor.black : PieceColor.white;
    for (int r = 0; r < 8; r++)
      for (int c = 0; c < 8; c++)
        if (board[r][c]?.color == enemy &&
            getRawMoves(board, Position(r, c), null).contains(pos))
          return true;
    return false;
  }

  static List<List<ChessPiece?>> _applyMoveToBoard(
      List<List<ChessPiece?>> board, Position from, Position to,
      Position? enPassantTarget) {
    final nb = board.map((r) => List<ChessPiece?>.from(r)).toList();
    final piece = nb[from.row][from.col]!;
    nb[to.row][to.col] = piece;
    nb[from.row][from.col] = null;
    if (piece.type == PieceType.pawn && enPassantTarget != null && to == enPassantTarget) {
      final capRow = piece.color == PieceColor.white ? to.row + 1 : to.row - 1;
      nb[capRow][to.col] = null;
    }
    return nb;
  }

  static bool hasAnyLegalMoves(List<List<ChessPiece?>> board, PieceColor color,
      Position? enPassantTarget, Map<String, bool> castlingRights) {
    for (int r = 0; r < 8; r++)
      for (int c = 0; c < 8; c++)
        if (board[r][c]?.color == color &&
            getLegalMoves(board, Position(r, c), enPassantTarget, castlingRights).isNotEmpty)
          return true;
    return false;
  }

  static String getMoveNotation(ChessPiece piece, Position from,
      Position to, ChessPiece? captured, bool isCheck, bool isCheckmate) {
    const sym = {
      PieceType.king: 'K', PieceType.queen: 'Q', PieceType.rook: 'R',
      PieceType.bishop: 'B', PieceType.knight: 'N', PieceType.pawn: '',
    };
    final fromFile = piece.type == PieceType.pawn && captured != null
        ? 'abcdefgh'[from.col] : '';
    final checkStr = isCheckmate ? '#' : (isCheck ? '+' : '');
    return '${sym[piece.type]}$fromFile${captured != null ? 'x' : ''}$to$checkStr';
  }
}
