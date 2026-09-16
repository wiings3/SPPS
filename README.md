# Space Pirate Poker Simulator — Prototype

Godot 4.5.1 prototype for a small poker roguelike built around **synergistic contraband builds**, not generic stat upgrades.

## Current run loop

1. Play one high-stakes Texas Hold'em encounter against a space-pirate captain.
2. Bet normally, bluff with raises, shove ALL-IN, or use contraband cheats.
3. Win or lose chips.
4. Pick 1 of 3 upgrades between encounters.
5. The draft becomes more likely to offer upgrades that share tags with your existing build.
6. Survive seven increasingly aggressive captains.

The final captain must be beaten to clear the run.

## Build archetypes

### BLUFF
Turn opponent folds into an engine. Dead-Eye Stare increases fold pressure, Shark Smile pays for forced folds, Terror Engine permanently grows your intimidation after bluff wins, and No Witnesses scales repeated bluff victories.

### RISK
Build around ALL-IN shoves. Blood Money pays successful shoves, Redline Reactor makes shoves scarier, Double Down makes called shoves harder but much more lucrative, and Escape Pod can save one disastrous all-in.

### CHEAT
Manipulate information and cards. Marked Deck reveals a hole card, Second Deal redraws your weaker opening card, Loaded River changes the newest community card, Greased Dealer grants another cheat use, and Inside Man pays when a rigged hand succeeds.

### ECONOMY
Compound winnings and survive variance. Pirate's Cut increases pots, Forged Buy-In reduces antes, Hot Hand supplies recurring chips, Salvage Rights pays showdown victories, and Insurance Fraud softens an early loss.

Many upgrades carry two tags so builds can cross-pollinate. For example, Shark Smile is BLUFF/ECONOMY and Cornered Rat is BLUFF/RISK.

## Draft philosophy

The draft is intentionally **synergy-aware rather than purely random**. Unowned upgrades normally have weight 1.0; each tag shared with the player's current build adds extra draft weight. This should make runs develop an identity without forcing the player down a fixed class path.

Some dependent upgrades, such as Greased Dealer and Inside Man, do not appear until the player owns an active cheating tool.

## Run it

1. Open Godot 4.5.1.
2. Import `project.godot`.
3. Press F6/F5 or click **Run Project**.

## Prototype intent

This is deliberately small and uses generated UI rather than final art. The current goal is to answer one design question:

**Can a normal poker hand become a radically different decision space because of the contraband build assembled during the run?**

If yes, presentation, content and balancing come next. If no, the upgrade interactions should be changed before the project grows.
