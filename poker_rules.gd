extends RefCounted

const SUITS: Array[String] = ["♠", "♥", "♦", "♣"]
const RANK_TEXT: Dictionary = {11:"J", 12:"Q", 13:"K", 14:"A"}

static func build_deck() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for suit in SUITS:
		for rank in range(2, 15):
			result.append({"rank":rank, "suit":suit})
	result.shuffle()
	return result

static func draw_card(deck: Array[Dictionary]) -> Dictionary:
	return deck.pop_back()

static func card_text(card: Dictionary) -> String:
	if card.is_empty():
		return "?"
	var rank: int = int(card["rank"])
	var rank_text: String = str(rank) if rank <= 10 else str(RANK_TEXT[rank])
	return "%s%s" % [rank_text, str(card["suit"])]

static func estimate_strength(cards: Array[Dictionary]) -> float:
	if cards.size() < 5:
		var r1: int = int(cards[0]["rank"])
		var r2: int = int(cards[1]["rank"])
		if r1 == r2:
			return clampf(0.48 + float(r1) / 28.0, 0.0, 1.0)
		var high: int = maxi(r1, r2)
		var suited_bonus: float = 0.07 if cards[0]["suit"] == cards[1]["suit"] else 0.0
		var connected: float = 0.06 if absi(r1 - r2) <= 2 else 0.0
		return clampf(0.12 + float(high) / 22.0 + suited_bonus + connected, 0.0, 0.78)
	var score: Array[int] = evaluate_best(cards)
	var category: int = score[0]
	var kicker: int = score[1] if score.size() > 1 else 2
	return clampf(float(category) / 8.0 * 0.82 + float(kicker) / 14.0 * 0.18, 0.0, 1.0)

static func evaluate_best(cards: Array[Dictionary]) -> Array[int]:
	var best: Array[int] = []
	var count: int = cards.size()
	if count < 5:
		return [0, 0]
	for a in range(count - 4):
		for b in range(a + 1, count - 3):
			for c in range(b + 1, count - 2):
				for d in range(c + 1, count - 1):
					for e in range(d + 1, count):
						var five: Array[Dictionary] = [cards[a], cards[b], cards[c], cards[d], cards[e]]
						var score: Array[int] = evaluate_five(five)
						if best.is_empty() or compare_scores(score, best) > 0:
							best = score
	return best

static func evaluate_five(cards: Array[Dictionary]) -> Array[int]:
	var ranks: Array[int] = []
	var suits: Array[String] = []
	var counts: Dictionary = {}
	for card in cards:
		var rank: int = int(card["rank"])
		ranks.append(rank)
		suits.append(str(card["suit"]))
		counts[rank] = int(counts.get(rank, 0)) + 1
	ranks.sort()
	ranks.reverse()

	var flush: bool = true
	for suit in suits:
		if suit != suits[0]:
			flush = false
			break

	var dedup: Array[int] = []
	for rank in ranks:
		if not dedup.has(rank):
			dedup.append(rank)
	var straight_high: int = 0
	if dedup.size() == 5:
		if dedup == [14, 5, 4, 3, 2]:
			straight_high = 5
		elif dedup[0] - dedup[4] == 4:
			straight_high = dedup[0]

	if flush and straight_high > 0:
		return [8, straight_high]

	var fours: Array[int] = []
	var threes: Array[int] = []
	var pairs: Array[int] = []
	var singles: Array[int] = []
	for raw_rank in counts.keys():
		var rank: int = int(raw_rank)
		match int(counts[rank]):
			4: fours.append(rank)
			3: threes.append(rank)
			2: pairs.append(rank)
			1: singles.append(rank)
	fours.sort(); fours.reverse()
	threes.sort(); threes.reverse()
	pairs.sort(); pairs.reverse()
	singles.sort(); singles.reverse()

	if not fours.is_empty(): return [7, fours[0], singles[0]]
	if not threes.is_empty() and not pairs.is_empty(): return [6, threes[0], pairs[0]]
	if flush: return [5] + ranks
	if straight_high > 0: return [4, straight_high]
	if not threes.is_empty(): return [3, threes[0]] + singles
	if pairs.size() >= 2: return [2, pairs[0], pairs[1], singles[0]]
	if pairs.size() == 1: return [1, pairs[0]] + singles
	return [0] + ranks

static func compare_scores(a: Array[int], b: Array[int]) -> int:
	var length: int = maxi(a.size(), b.size())
	for i in range(length):
		var av: int = a[i] if i < a.size() else 0
		var bv: int = b[i] if i < b.size() else 0
		if av > bv: return 1
		if av < bv: return -1
	return 0

static func hand_name(category: int) -> String:
	match category:
		8: return "Straight Flush"
		7: return "Four of a Kind"
		6: return "Full House"
		5: return "Flush"
		4: return "Straight"
		3: return "Three of a Kind"
		2: return "Two Pair"
		1: return "Pair"
		_: return "High Card"
