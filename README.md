# Space Pirate Poker Simulator — Prototype

Godot 4.5.1 prototype focused on the smallest viable gameplay loop:

1. Play one high-stakes Texas Hold'em hand against a space-pirate opponent.
2. Win or lose chips through betting.
3. Pick 1 of 3 permanent contraband upgrades after every encounter.
4. Survive five increasingly aggressive captains.

## Run it

1. Open Godot 4.5.1.
2. Import `project.godot` from this folder.
3. Press F6/F5 or click Run Project.

## Current upgrades

- Marked Deck — reveal one opponent card.
- Sleeve Ace — improve an Ace-less starting hand.
- Loaded River — redraw one visible community card per encounter.
- Dead-Eye Stare — stronger fold pressure.
- Blood Money — bonus chips on wins.
- Pirate's Cut — larger payouts.
- Insurance Fraud — first loss refund.
- Forged Buy-In — cheaper antes.
- Cold Reader — vague opponent strength reads.
- Hot Hand — chips at the start of each encounter.

## Prototype intent

This is deliberately not content-complete and uses generated UI rather than art assets. The purpose is to test whether the loop of **poker encounter -> draft an upgrade -> increasingly broken build -> harder opponent** is fun before spending time on final art, animation, sound, progression, or meta systems.
