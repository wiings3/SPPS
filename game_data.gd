extends RefCounted

const MAX_ENCOUNTERS: int = 7

static func opponents() -> Array[Dictionary]:
	return [
		{"name":"Deckhand Dax", "subtitle":"Dockside card shark", "aggression":0.24, "bluff":0.12, "quote":"Try not to cry on the cards."},
		{"name":"Smuggler Vexa", "subtitle":"Contraband broker", "aggression":0.34, "bluff":0.24, "quote":"Everything is legal if nobody logs it."},
		{"name":"Rustjaw Rell", "subtitle":"Scrap-fleet raider", "aggression":0.46, "bluff":0.10, "quote":"I don't bluff. I threaten mathematically."},
		{"name":"Lady Void", "subtitle":"Wanted in seven systems", "aggression":0.45, "bluff":0.34, "quote":"You brought money. How optimistic."},
		{"name":"Professor Knives", "subtitle":"Retired casino mathematician", "aggression":0.50, "bluff":0.18, "quote":"Probability is just violence with paperwork."},
		{"name":"Saint Blackjack", "subtitle":"Cult leader and debt collector", "aggression":0.55, "bluff":0.30, "quote":"Luck is a god. I collect the tithe."},
		{"name":"Admiral Ash", "subtitle":"The Black Orbit", "aggression":0.62, "bluff":0.22, "quote":"Your ship will look excellent in my hangar."}
	]

static func upgrades() -> Dictionary:
	return {
		# BLUFF
		"dead_eye": {
			"name":"Dead-Eye Stare", "tags":["BLUFF"],
			"desc":"Raises gain +18% fold chance. Simple, rude, effective."
		},
		"shark_smile": {
			"name":"Shark Smile", "tags":["BLUFF", "ECONOMY"],
			"desc":"Whenever an opponent folds to your raise or shove, gain +10 chips."
		},
		"terror_engine": {
			"name":"Terror Engine", "tags":["BLUFF"],
			"desc":"Each bluff win permanently adds +4% fold chance this run, up to +20%."
		},
		"cornered_rat": {
			"name":"Cornered Rat", "tags":["BLUFF", "RISK"],
			"desc":"While at 45 chips or less, gain +22% fold chance."
		},
		"no_witnesses": {
			"name":"No Witnesses", "tags":["BLUFF", "ECONOMY"],
			"desc":"Bluff wins pay +4 chips for every bluff win already scored this run."
		},

		# RISK / ALL-IN
		"blood_money": {
			"name":"Blood Money", "tags":["RISK", "ECONOMY"],
			"desc":"Win after going ALL-IN to collect +18 bonus chips."
		},
		"redline_reactor": {
			"name":"Redline Reactor", "tags":["RISK", "BLUFF"],
			"desc":"ALL-IN shoves gain +15% fold chance."
		},
		"double_down": {
			"name":"Double Down", "tags":["RISK", "ECONOMY"],
			"desc":"Called ALL-IN wins pay +30 chips, but opponents are 12% less likely to fold."
		},
		"escape_pod": {
			"name":"Escape Pod", "tags":["RISK"],
			"desc":"Once per run, losing an ALL-IN leaves you with 20 chips instead of zero."
		},
		"death_wish": {
			"name":"Death Wish", "tags":["RISK"],
			"desc":"Begin an encounter below 40 chips to gain +15 chips and extra shove pressure."
		},

		# CHEAT / CARD CONTROL
		"marked_deck": {
			"name":"Marked Deck", "tags":["CHEAT"],
			"desc":"Reveal one opponent hole card every encounter."
		},
		"second_deal": {
			"name":"Second Deal", "tags":["CHEAT"],
			"desc":"Before the flop, CHEAT redraws your lower hole card."
		},
		"loaded_river": {
			"name":"Loaded River", "tags":["CHEAT"],
			"desc":"After the flop, CHEAT redraws the newest visible community card."
		},
		"greased_dealer": {
			"name":"Greased Dealer", "tags":["CHEAT"],
			"requires_any":["second_deal", "loaded_river"],
			"desc":"Gain one additional CHEAT use every encounter."
		},
		"inside_man": {
			"name":"Inside Man", "tags":["CHEAT", "ECONOMY"],
			"requires_any":["second_deal", "loaded_river"],
			"desc":"If you cheated during the hand and still win, collect +12 chips."
		},
		"sleeve_ace": {
			"name":"Sleeve Ace", "tags":["CHEAT"],
			"desc":"If your opening hand has no Ace, secretly replace the lower card with an Ace."
		},

		# ECONOMY / SURVIVAL
		"pirates_cut": {
			"name":"Pirate's Cut", "tags":["ECONOMY"],
			"desc":"Every pot you win pays an extra 15% from the house."
		},
		"cheap_ante": {
			"name":"Forged Buy-In", "tags":["ECONOMY"],
			"desc":"Antes cost 3 fewer chips."
		},
		"insurance": {
			"name":"Insurance Fraud", "tags":["ECONOMY", "RISK"],
			"desc":"The first non-ALL-IN loss each run refunds 15 chips."
		},
		"hot_hand": {
			"name":"Hot Hand", "tags":["ECONOMY"],
			"desc":"Gain 6 chips at the start of every encounter."
		},
		"salvage_rights": {
			"name":"Salvage Rights", "tags":["ECONOMY"],
			"desc":"Showdown victories pay +10 chips."
		},
		"cold_reader": {
			"name":"Cold Reader", "tags":["CHEAT", "BLUFF"],
			"desc":"Each street gives a vague read on the opponent's current strength."
		}
	}
