import 'package:flutter/foundation.dart';
import 'chess_logic.dart';

class ChessController extends ChangeNotifier {
  late List<List<ChessPiece?>> _board;
  late PieceColor _currentTurn;
  late List<Move> _moveHistory;
  late Map<String, bool> _castlingRights;
  Position? _enPassantTarget;
  Position? _selectedPos;
  List<Position> _legalMoves = [];
  bool _isCheck = false;
  bool _isCheckmate = false;
  bool _isStalemate = false;
  List<ChessPiece> _capturedByWhite = [];
  List<ChessPiece> _capturedByBlack = [];
  Position? _lastMoveFrom;
  Position? _lastMoveTo;
  Position? _pendingPromotion;

  ChessController() {
    _initGame();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  List<List<ChessPiece?>> get board           => _board;
  PieceColor get currentTurn                  => _currentTurn;
  List<Move> get moveHistory                  => _moveHistory;
  Position? get selectedPos                   => _selectedPos;
  List<Position> get legalMoves               => _legalMoves;
  bool get isCheck                            => _isCheck;
  bool get isCheckmate                        => _isCheckmate;
  bool get isStalemate                        => _isStalemate;
  List<ChessPiece> get capturedByWhite        => _capturedByWhite;
  List<ChessPiece> get capturedByBlack        => _capturedByBlack;
  Position? get lastMoveFrom                  => _lastMoveFrom;
  Position? get lastMoveTo                    => _lastMoveTo;
  bool get isGameOver                         => _isCheckmate || _isStalemate;
  bool get awaitingPromotion                  => _pendingPromotion != null;

  String get statusText {
    if (_isCheckmate) {
      final winner = _currentTurn == PieceColor.white ? 'Black' : 'White';
      return '$winner wins by checkmate!';
    }
    if (_isStalemate) return 'Draw by stalemate!';
    if (_isCheck)
      return '${_currentTurn == PieceColor.white ? "White" : "Black"} is in check!';
    return '${_currentTurn == PieceColor.white ? "White" : "Black"}\'s turn';
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  void _initGame() {
    _board            = ChessLogic.initialBoard();
    _currentTurn      = PieceColor.white;
    _moveHistory      = [];
    _castlingRights   = ChessLogic.initialCastlingRights();
    _enPassantTarget  = null;
    _selectedPos      = null;
    _legalMoves       = [];
    _isCheck          = false;
    _isCheckmate      = false;
    _isStalemate      = false;
    _capturedByWhite  = [];
    _capturedByBlack  = [];
    _lastMoveFrom     = null;
    _lastMoveTo       = null;
    _pendingPromotion = null;
  }

  void resetGame() {
    _initGame();
    notifyListeners();
  }

  // ── Square tap ────────────────────────────────────────────────────────────
  void onSquareTap(Position pos) {
    if (isGameOver || awaitingPromotion) return;

    final int r = pos.row;
    final int c = pos.col;
    final piece = _board[r][c];

    // Is this square one of the legal move destinations?
    final bool isLegalDest = _legalMoves
        .any((m) => m.row == r && m.col == c);

    debugLog('onSquareTap r=$r c=$c '
        'selectedPos=$_selectedPos '
        'isLegalDest=$isLegalDest '
        'legalMoves=${_legalMoves.length}');

    // Case 1: a piece is selected AND this square is a legal destination → MOVE
    if (_selectedPos != null && isLegalDest) {
      _executeMove(_selectedPos!, pos);
      return;
    }

    // Case 2: tapped one of our own pieces → SELECT (or re-select)
    if (piece != null && piece.color == _currentTurn) {
      _selectedPos = pos;
      _legalMoves = ChessLogic.getLegalMoves(
          _board, pos, _enPassantTarget, _castlingRights);
      notifyListeners();
      return;
    }

    // Case 3: tapped empty or enemy square with nothing useful → DESELECT
    _selectedPos = null;
    _legalMoves = [];
    notifyListeners();
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    print(msg);
  }

  // ── Execute move ──────────────────────────────────────────────────────────
  void _executeMove(Position from, Position to) {
    final piece    = _board[from.row][from.col]!;
    ChessPiece? captured = _board[to.row][to.col];
    bool isEnPassant = false;
    bool isCastling  = false;

    final nb = _board.map((r) => List<ChessPiece?>.from(r)).toList();

    // En passant capture
    if (piece.type == PieceType.pawn &&
        _enPassantTarget != null && to == _enPassantTarget) {
      final capRow = piece.color == PieceColor.white ? to.row + 1 : to.row - 1;
      final epPiece = nb[capRow][to.col];
      if (epPiece != null) {
        _addCaptured(piece.color, epPiece);
        nb[capRow][to.col] = null;
        captured = epPiece;
      }
      isEnPassant = true;
    } else if (captured != null) {
      _addCaptured(piece.color, captured);
    }

    // Castling – slide rook
    if (piece.type == PieceType.king) {
      final diff = to.col - from.col;
      if (diff.abs() == 2) {
        isCastling = true;
        if (diff == 2) { nb[from.row][5] = nb[from.row][7]; nb[from.row][7] = null; }
        else           { nb[from.row][3] = nb[from.row][0]; nb[from.row][0] = null; }
      }
    }

    nb[to.row][to.col]     = piece;
    nb[from.row][from.col] = null;

    // Update castling rights
    final nc = Map<String, bool>.from(_castlingRights);
    if (piece.type == PieceType.king) {
      final p = piece.color == PieceColor.white ? 'w' : 'b';
      nc['${p}K'] = false; nc['${p}Q'] = false;
    }
    if (piece.type == PieceType.rook) {
      if (from.col == 7) nc[piece.color == PieceColor.white ? 'wK' : 'bK'] = false;
      if (from.col == 0) nc[piece.color == PieceColor.white ? 'wQ' : 'bQ'] = false;
    }
    _castlingRights = nc;

    // En-passant target for next move
    _enPassantTarget = (piece.type == PieceType.pawn && (to.row - from.row).abs() == 2)
        ? Position((from.row + to.row) ~/ 2, from.col)
        : null;

    _lastMoveFrom = from;
    _lastMoveTo   = to;
    _board        = nb;

    // Pawn promotion – wait for player choice
    if (piece.type == PieceType.pawn && (to.row == 0 || to.row == 7)) {
      _pendingPromotion = to;
      _selectedPos      = null;
      _legalMoves       = [];
      notifyListeners();
      return;
    }

    _finishTurn(from, to, piece, captured, isEnPassant, isCastling, null);
  }

  void _addCaptured(PieceColor capturer, ChessPiece piece) {
    if (capturer == PieceColor.white) {
      _capturedByWhite = [..._capturedByWhite, piece];
    } else {
      _capturedByBlack = [..._capturedByBlack, piece];
    }
  }

  void promotePawn(PieceType type) {
    if (_pendingPromotion == null) return;
    final pos   = _pendingPromotion!;
    final piece = _board[pos.row][pos.col]!;
    final nb    = _board.map((r) => List<ChessPiece?>.from(r)).toList();
    nb[pos.row][pos.col] = ChessPiece(color: piece.color, type: type);
    _board            = nb;
    _pendingPromotion = null;

    _switchAndCheck();
    _selectedPos = null;
    _legalMoves  = [];
    notifyListeners();
  }

  // ── After each move: switch turn, detect check/mate/stalemate ────────────
  void _finishTurn(Position from, Position to, ChessPiece piece,
      ChessPiece? captured, bool isEnPassant, bool isCastling,
      PieceType? promotionType) {
    _switchAndCheck();

    final notation = ChessLogic.getMoveNotation(
        piece, from, to, captured, _isCheck, _isCheckmate);
    _moveHistory = [
      ..._moveHistory,
      Move(
        from: from, to: to, captured: captured,
        isCastling: isCastling, isEnPassant: isEnPassant,
        promotionType: promotionType, notation: notation,
      ),
    ];

    _selectedPos = null;
    _legalMoves  = [];
    notifyListeners();
  }

  void _switchAndCheck() {
    _currentTurn = _currentTurn == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    _isCheck = ChessLogic.isKingInCheck(_board, _currentTurn);
    final hasMoves = ChessLogic.hasAnyLegalMoves(
        _board, _currentTurn, _enPassantTarget, _castlingRights);
    _isCheckmate = _isCheck  && !hasMoves;
    _isStalemate = !_isCheck && !hasMoves;
  }
}
