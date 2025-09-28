Project: The Listener - An Earthbound-Inspired Mobile RPG

Core Vision
A narrative-focused mobile RPG where you play a quiet child who progresses by listening to NPCs confess and share their stories. Inspired by Earthbound's suburban surrealism and Rachel Cusk's Outline trilogy.

The Core Insight: Children as Authentic Listeners
Adults talking to a child who simply nods and waits find themselves revealing truths they didn't plan to share. Children don't have conversational armor - they just listen, ask why, and repeat things back in ways that make adults hear themselves differently.

Target Audience
Non-gamers who rarely play beyond crosswords. Dead simple touch controls, no visible stats, 15-minute mobile sessions.

Core Mechanics
Universal 4-option dialogue system:
- "Say nothing" - Forces NPCs to fill uncomfortable silence
- "Nod" - Gentle encouragement without judgment
- "Ask why" - Innocent probing that cuts through deflection
- "Repeat back" - Makes adults hear themselves

The constraint isn't a limitation - it forces authentic interaction by removing conversational scripts.

Characters
Five NPCs with distinct psychological defense mechanisms:
- Paul: Projects his failings through legitimate-seeming complaints (divorce, curtains)
- Rita: Brilliant but unable to articulate her unified theory (failed academic, podcast obsession)
- Tatiana: Deflects sincerity through hostile humor (irony-poisoned troll, 4chan energy)
- Larry: Genuine spirituality hiding material privilege (meditation, mysterious wealth)
- Mark: Gets physical thrill from lying (replaced heroin with running and fabrication)

Dialogue Writing Philosophy
- Write how people really talk when they feel safely heard
- Every line serves psychological revelation
- Humor emerges from character specificity, not jokes
- Constraint breeds authenticity - limited options force honesty

Current Development State
- Basic overworld with character movement working
- 4-option dialogue system implemented (hardcoded in Rita/Paul)
- Trust tracking and conversation progression functional
- Character data exported to JSON (characters.json, dialogue_templates.json)

Next Immediate Steps
1. Convert one character (Rita) from hardcoded GDScript to JSON-driven dialogue
2. Test that the psychological framework actually creates compelling conversations
3. Build simple scene with 2-3 characters to test interconnections
4. Validate that non-gamers can navigate the interface

Key Technical Challenges
- JSON dialogue loader that handles branching conversations elegantly
- Touch UI that feels natural for mobile (conversation wheel vs traditional menu)
- Save system that preserves conversation state and NPC relationships
- Performance optimization for mobile (especially dialogue text rendering)

Development Philosophy
Story-first: Write and test dialogue content before building complex systems. Prototype conversations in Twine, export to JSON, test in Godot. The dialogue quality determines if this concept works.

Success Metric
The game works if players feel they're witnessing authentic psychological moments, not just consuming content.