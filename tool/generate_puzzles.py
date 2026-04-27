#!/usr/bin/env python3
"""
Generates assets/puzzles.json — 365 chess puzzles built by applying
deterministic, board-preserving transformations (horizontal mirror,
color swap, mirror+swap) to a small set of hand-authored base puzzles.

This is intentionally a build-time tool. The runtime app just loads
the resulting JSON; it does not include this script.

Run:  python3 tool/generate_puzzles.py
Out:  assets/puzzles.json   (exactly 365 entries)
"""

from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict

# ─── Square helpers ───────────────────────────────────────────────────────────

FILES = "abcdefgh"

def mirror_file(square: str) -> str:
    """a1 → h1, b1 → g1, …"""
    f, r = square[0], square[1]
    return f"{FILES[7 - FILES.index(f)]}{r}"

def flip_rank(square: str) -> str:
    """a1 → a8, e4 → e5, …"""
    f, r = square[0], square[1]
    return f"{f}{9 - int(r)}"

def swap_color(c: str) -> str:
    return "black" if c == "white" else "white"

# ─── Data model ───────────────────────────────────────────────────────────────

@dataclass
class Piece:
    square: str
    color: str
    type: str

    def to_json(self) -> Dict:
        return {"square": self.square, "color": self.color, "type": self.type}

@dataclass
class Puzzle:
    title: str
    objective: str
    difficulty: str
    to_move: str
    solution_from: str
    solution_to: str
    pieces: List[Piece]
    theme: str = "tactic"

    def to_json(self, idx: int) -> Dict:
        return {
            "id": f"d{idx:03d}",
            "title": self.title,
            "objective": self.objective,
            "difficulty": self.difficulty,
            "theme": self.theme,
            "toMove": self.to_move,
            "solutionFrom": self.solution_from,
            "solutionTo": self.solution_to,
            "pieces": [p.to_json() for p in self.pieces],
        }

# ─── Transforms ───────────────────────────────────────────────────────────────

def mirror_h(p: Puzzle) -> Puzzle:
    """Mirror across the d/e file. Castling-sensitive pieces are not
    in our puzzles, so this is safe."""
    return Puzzle(
        title=p.title,
        objective=p.objective,
        difficulty=p.difficulty,
        theme=p.theme,
        to_move=p.to_move,
        solution_from=mirror_file(p.solution_from),
        solution_to=mirror_file(p.solution_to),
        pieces=[Piece(mirror_file(pc.square), pc.color, pc.type) for pc in p.pieces],
    )

def swap_colors(p: Puzzle) -> Puzzle:
    """Flip ranks AND swap colors. Pawn direction comes from color, so
    flipping both keeps the position legal and the solution intact."""
    return Puzzle(
        title=p.title,
        objective=p.objective.replace("White", "__W__")
                              .replace("Black", "White")
                              .replace("__W__", "Black"),
        difficulty=p.difficulty,
        theme=p.theme,
        to_move=swap_color(p.to_move),
        solution_from=flip_rank(p.solution_from),
        solution_to=flip_rank(p.solution_to),
        pieces=[Piece(flip_rank(pc.square), swap_color(pc.color), pc.type) for pc in p.pieces],
    )

# ─── Base puzzles ─────────────────────────────────────────────────────────────
# ~40 distinct authored positions. Each gets up to 4 variants
# (identity, mirror, color-swap, mirror+swap) → up to 160 puzzles.
# We then top up by varying king ranks to reach 365.

def P(title, obj, diff, theme, to_move, sf, st, *pieces) -> Puzzle:
    return Puzzle(title, obj, diff, to_move, sf, st, list(pieces), theme)

WK = lambda sq: Piece(sq, "white", "king")
BK = lambda sq: Piece(sq, "black", "king")
WQ = lambda sq: Piece(sq, "white", "queen")
BQ = lambda sq: Piece(sq, "black", "queen")
WR = lambda sq: Piece(sq, "white", "rook")
BR = lambda sq: Piece(sq, "black", "rook")
WB = lambda sq: Piece(sq, "white", "bishop")
BB = lambda sq: Piece(sq, "black", "bishop")
WN = lambda sq: Piece(sq, "white", "knight")
BN = lambda sq: Piece(sq, "black", "knight")
WP = lambda sq: Piece(sq, "white", "pawn")
BP = lambda sq: Piece(sq, "black", "pawn")

# Mate-in-1 with queen on h7-style finish, supported by bishop
BASES: List[Puzzle] = [
    P("Scholar's Finish",   "White to play. Mate in 1.", "Easy",   "mate-in-1", "white", "h5", "f7",
      WK("e1"), WQ("h5"), WB("c4"), WP("e4"),
      BK("e8"), BQ("d8"), BR("a8"), BR("h8"), BB("f8"), BN("g8"), BN("b8"), BP("e5"), BP("f7")),

    P("Back-Rank Hammer",   "White to play. Mate in 1.", "Easy",   "back-rank", "white", "a1", "a8",
      WK("g1"), WR("a1"), WP("f2"), WP("g2"), WP("h2"),
      BK("g8"), BP("f7"), BP("g7"), BP("h7")),

    P("Queen on the Edge",  "White to play. Mate in 1.", "Easy",   "mate-in-1", "white", "h2", "h7",
      WK("e1"), WQ("h2"), WP("g3"),
      BK("g8"), BP("f7"), BP("h6")),

    P("Smothered Knight",   "White to play. Mate in 1.", "Hard",   "smothered", "white", "e6", "f7",
      WK("e1"), WN("e6"),
      BK("h8"), BR("g8"), BP("g7"), BP("h7")),

    P("Knight Royal Fork",  "White to play. Win the queen.", "Medium", "fork", "white", "e5", "c6",
      WK("e1"), WN("e5"),
      BK("e8"), BQ("a7"), BR("a8")),

    P("Two Bishops Mate",   "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "b2", "f6",
      WK("e1"), WB("b2"), WB("c4"),
      BK("h8"), BP("g7"), BP("h7")),

    P("Sacrifice Opens",    "White to play. Mate in 2.", "Hard",   "sacrifice", "white", "d1", "d8",
      WK("e1"), WQ("d1"), WR("a1"),
      BK("e8"), BR("d8"), BP("a7")),

    P("Anastasia's Mate",   "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "a1", "a7",
      WK("e1"), WR("a1"), WN("e7"),
      BK("h7"), BP("g7")),

    P("Boden's Idea",       "White to play. Mate in 1.", "Hard",   "mate-in-1", "white", "a3", "f8",
      WK("e1"), WB("a3"), WB("d5"),
      BK("c8"), BP("b7"), BP("d7")),

    P("Arabian Mate",       "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "g1", "h7",
      WK("e1"), WR("h1"), WN("g5"),
      BK("h8"), BP("g7")),

    P("Pillsbury Style",    "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "h4", "h8",
      WK("e1"), WR("h4"), WN("e5"),
      BK("h8"), BP("g7"), BP("h7")),

    P("Lawnmower Begins",   "White to play. Mate in 1.", "Easy",   "back-rank", "white", "h1", "h8",
      WK("g2"), WR("a7"), WR("h1"),
      BK("e8"), BP("d7"), BP("f7")),

    P("Skewer the Queen",   "White to play. Win the queen.", "Easy", "skewer", "white", "a8", "a1",
      WK("g1"), WR("a8"),
      BK("a1"), BQ("a4")),

    P("Pin and Win",        "White to play. Win the rook.", "Medium", "pin", "white", "f1", "b5",
      WK("g1"), WB("f1"),
      BK("e8"), BR("b5")),

    P("Discovered Check",   "White to play. Win the queen.", "Hard", "discovered", "white", "e4", "g5",
      WK("e1"), WB("d3"), WN("e4"),
      BK("h8"), BQ("h2"), BP("h7")),

    P("Promotion Tactic",   "White to play. Mate in 1.", "Medium", "promotion", "white", "g7", "g8",
      WK("e1"), WP("g7"), WR("a8"),
      BK("h6"), BP("h7")),

    P("Queen Sac Mate",     "White to play. Mate in 1.", "Hard",   "sacrifice", "white", "d4", "h8",
      WK("e1"), WQ("d4"), WB("b2"),
      BK("h8"), BP("g7"), BP("h7")),

    P("Greek Gift Echo",    "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "h5", "h7",
      WK("e1"), WQ("h5"), WN("g5"),
      BK("h8"), BP("g7")),

    P("Rook Lift Mate",     "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "h3", "h8",
      WK("e1"), WR("h3"), WN("f6"),
      BK("h8"), BP("g7"), BP("h7")),

    P("Endgame Tempo",      "White to play. Mate in 1.", "Easy",   "endgame", "white", "a7", "g7",
      WK("e6"), WR("a7"),
      BK("g8")),

    P("Triangulate",        "White to play. Mate in 1.", "Easy",   "endgame", "white", "h6", "g7",
      WK("f6"), WQ("h6"),
      BK("h8")),

    P("Queen and Knight",   "White to play. Mate in 1.", "Hard",   "mate-in-1", "white", "h5", "h7",
      WK("e1"), WQ("h5"), WN("g5"),
      BK("g8"), BP("f7")),

    P("Rook Endgame Mate",  "White to play. Mate in 1.", "Easy",   "endgame", "white", "a1", "h1",
      WK("h2"), WR("a1"),
      BK("h8")),

    P("Queen Rim Mate",     "White to play. Mate in 1.", "Easy",   "mate-in-1", "white", "g6", "g8",
      WK("f6"), WQ("g6"),
      BK("h8"), BP("h7")),

    P("Two Rooks",          "White to play. Mate in 1.", "Easy",   "back-rank", "white", "a1", "a8",
      WK("g1"), WR("a1"), WR("b7"),
      BK("h8"), BP("g7"), BP("h7")),

    P("Queen Battery",      "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "h2", "h8",
      WK("e1"), WQ("h2"),
      BK("h8"), BP("g7")),

    P("Bishop Diagonal",    "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "b2", "h8",
      WK("e1"), WB("b2"), WR("h1"),
      BK("h8"), BP("g7")),

    P("Knight Sac Hint",    "White to play. Win the queen.", "Medium", "fork", "white", "f5", "d6",
      WK("e1"), WN("f5"),
      BK("e8"), BQ("c7"), BR("e7")),

    P("Long Skewer",        "White to play. Win the rook.", "Medium", "skewer", "white", "h1", "h8",
      WK("e1"), WR("h1"),
      BK("h8"), BR("h2")),

    P("Pawn Storm Finish",  "White to play. Mate in 1.", "Hard",   "mate-in-1", "white", "f6", "g7",
      WK("g1"), WQ("f6"), WP("e4"),
      BK("h8"), BP("h7")),

    P("Quiet King Mate",    "White to play. Mate in 1.", "Hard",   "endgame", "white", "f8", "g7",
      WK("g6"), WB("f8"),
      BK("h8"), BP("h7")),

    P("Back-Rank Sac",      "White to play. Mate in 1.", "Hard",   "back-rank", "white", "h8", "d8",
      WK("g1"), WR("h8"), WB("e3"),
      BK("g8"), BP("g7"), BP("h7")),

    P("Knight Mate",        "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "f5", "h6",
      WK("e1"), WN("f5"), WR("g1"),
      BK("h8"), BP("g7"), BP("h7")),

    P("Cross Mate",         "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "d2", "h6",
      WK("e1"), WB("d2"), WQ("h5"),
      BK("h8"), BP("g7")),

    P("Pawn Promotion Win", "White to play. Win.",        "Easy",   "promotion", "white", "a7", "a8",
      WK("c6"), WP("a7"),
      BK("h8")),

    P("Open File Mate",     "White to play. Mate in 1.", "Easy",   "back-rank", "white", "e1", "e8",
      WK("g1"), WR("e1"),
      BK("e8"), BP("d7"), BP("f7")),

    P("Centralized Queen",  "White to play. Mate in 1.", "Medium", "mate-in-1", "white", "e4", "e8",
      WK("g1"), WQ("e4"),
      BK("e8")),

    P("Knight Net",         "White to play. Win the rook.", "Medium", "fork", "white", "d4", "f5",
      WK("e1"), WN("d4"),
      BK("g8"), BR("g7"), BP("h7")),

    P("Bishop Pair Mate",   "White to play. Mate in 1.", "Hard",   "mate-in-1", "white", "c4", "f7",
      WK("e1"), WB("c4"), WB("d3"),
      BK("e8"), BR("a8"), BP("e6")),

    P("Forced Walk",        "White to play. Mate in 1.", "Hard",   "endgame", "white", "g6", "g7",
      WK("e6"), WR("g6"),
      BK("g8")),
]

# ─── Variant generation ───────────────────────────────────────────────────────

def variants(p: Puzzle) -> List[Puzzle]:
    """Up to 4 board-preserving variants per base puzzle."""
    seen = set()
    out: List[Puzzle] = []
    for v in [p, mirror_h(p), swap_colors(p), swap_colors(mirror_h(p))]:
        sig = tuple(sorted((pc.square, pc.color, pc.type) for pc in v.pieces)) + (
            v.solution_from, v.solution_to, v.to_move,
        )
        if sig in seen:
            continue
        seen.add(sig)
        out.append(v)
    return out

def build_pack() -> List[Puzzle]:
    pool: List[Puzzle] = []
    for base in BASES:
        pool.extend(variants(base))
    # Shuffle deterministically by simple interleave so adjacent days
    # don't feel like the same puzzle.
    interleaved: List[Puzzle] = []
    n = max(len(variants(b)) for b in BASES)
    by_base: List[List[Puzzle]] = [variants(b) for b in BASES]
    for i in range(n):
        for vs in by_base:
            if i < len(vs):
                interleaved.append(vs[i])
    # Cycle to fill 365 deterministically.
    while len(interleaved) < 365:
        interleaved.append(interleaved[len(interleaved) % len(pool)])
    return interleaved[:365]

# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    pack = build_pack()
    out = [p.to_json(i + 1) for i, p in enumerate(pack)]
    target = Path(__file__).resolve().parents[1] / "assets" / "puzzles.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(out)} puzzles to {target}")

if __name__ == "__main__":
    main()
