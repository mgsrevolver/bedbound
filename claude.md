Project: The Listener - An Earthbound-Inspired Mobile RPG
Core Vision
We're building a narrative-focused mobile RPG inspired by the intersection of:

Earthbound's humor, suburban surrealism, and pixel art aesthetic
Rachel Cusk's Outline trilogy - a blank-slate protagonist who discovers identity through witnessing others' stories
Mobile-first design for non-gamers who rarely play beyond crossword puzzles
The player is a quiet child who progresses by listening to NPCs confess, trauma-dump, and share their stories. Identity and backstory emerge through others' reactions and assumptions.

Target Audience
Primary: Non-gamers (think: your mother, partner who only does crosswords)

Dead simple touch controls
No visible stats, levels, or math
Humor and narrative drive engagement
15-minute play sessions on mobile
Core Mechanics
Universal Dialogue System
Every NPC interaction uses exactly 4 options:

"Say nothing" - Pure receptivity, lets NPCs fill the void
"Nod" - Gentle encouragement to continue
"Ask why" - Probe deeper into motivations
"Repeat their words back" - Therapeutic mirroring
Progression Through Listening
No combat or traditional RPG mechanics
Progress by becoming a trusted listener in the community
Unlock new areas, private spaces, deeper conversations through social trust
World literally expands as emotional barriers dissolve
Feedback Systems
Confession Journal - Auto-fills with story fragments, reveals connections between NPCs
Relationship Web - Visual map showing how everyone connects, your growing centrality
Environmental Changes - Doors open, new locations appear, NPCs move to private spaces
Integrated Puzzles
Memory-based: Remember door codes, song names, personal details from confessions
Social Logic: Navigate conflicting stories, time approaches correctly, introduce compatible people
Environmental Storytelling: Photos contradict stories, organize objects to trigger memories
Information Threading: Use details from one confession to unlock questions for others
Technical Specifications
Platform & Engine
Engine: Godot (GDScript primary language)
Target Platforms: iOS and Android mobile
Visual Style: Earthbound-inspired 16-bit pixel art with modern mobile UI overlays
Controls: Touch-first design, large finger-friendly interface elements
Key Technical Requirements
Pixel-perfect sprite rendering and animation
Tile-based overworld with smooth character movement
Robust dialogue system with branching conversations
Save system for story progress and relationship states
Mobile-optimized performance and battery usage
Development Phases
Phase 1: Core Foundation
Goal: Prove the dialogue system and basic mechanics work

Basic character movement in a simple test scene
Universal 4-option dialogue system implementation
3-4 prototype NPC encounters with full conversation trees
Basic save/load functionality
Success Criteria:

Can complete one full NPC conversation from start to meaningful conclusion
All 4 dialogue options feel distinct and produce different NPC reactions
Progress persists between sessions
Phase 2: World & Systems
Goal: Build the interconnected town and relationship mechanics

Town design with 8-12 NPCs and their locations
Relationship web visualization system
Confession journal with auto-population
Environmental puzzle integration
Area unlocking based on social progress
Success Criteria:

Can navigate between multiple NPCs with interconnected stories
Journal and relationship web accurately reflect player progress
At least 2 areas unlock through listening/trust-building
Phase 3: Content & Polish
Goal: Complete narrative content and mobile optimization

All NPC storylines and interconnections
Protagonist backstory revelation sequence
Mobile touch controls refinement
Performance optimization for target devices
App store assets and submission preparation
Success Criteria:

Complete playable experience from start to narrative conclusion
Smooth performance on iOS and Android devices
Ready for app store submission
Development Best Practices for This Project

1. Story-First Development
   Write and test all dialogue content before implementing complex systems
   Prototype conversations in simple text format first
   Validate that the 4-option system works across different personality types
2. Mobile-Native Thinking
   Test touch interactions on actual devices early and often
   Design UI elements for thumb navigation
   Consider battery impact and performance constraints
   Plan for interruption-friendly gameplay (pause anywhere, quick save)
3. Non-Gamer Validation
   Test with actual non-gamers throughout development
   Prioritize clarity and obviousness over gaming conventions
   Eliminate any mechanics that require gaming literacy
   Code Organization Strategy
   Scene Structure
   Main Scene
   ├── UI Layer (modern mobile interface)
   ├── Game World (pixel art overworld)
   ├── Dialogue System (universal 4-option handler)
   ├── Data Management (save/load, NPC states)
   └── Audio Manager (music, sound effects)
   Key Systems to Architect Early
   DialogueManager: Handles universal 4-option system, NPC state tracking
   RelationshipTracker: Manages trust levels, unlocked content, story connections
   JournalSystem: Auto-populates with story fragments, manages revelation pacing
   WorldStateManager: Controls area accessibility, environmental changes
   Working with Claude Code
   Effective Prompting Strategy
   Always start with step-by-step reasoning: "Explain your approach before writing code"
   Reference this document: "Based on the project goals in claude.md..."
   Test-driven development: Ask for failing tests first, then implementation
   Iterate on architecture: "Critique this approach - what problems might arise?"
   Godot-Specific Help Needed
   Scene and node structure best practices
   GDScript syntax and patterns (coming from JS background)
   Mobile export configuration and optimization
   Godot's signal system for event handling
   UI system for touch-friendly interfaces
   Content Development Support
   Dialogue writing in Earthbound's humorous style
   Character personality consistency across conversations
   Story connection and revelation pacing
   Environmental storytelling integration
   Success Metrics
   Development Milestones
   First NPC conversation fully playable
   All 4 dialogue options implemented and distinct
   Basic save/load working
   3+ NPCs with interconnected stories
   Journal and relationship web functional
   First area unlock through social progress
   Mobile touch controls polished
   Complete story playable start to finish
   Performance optimized for mobile
   App store ready
   Player Experience Goals
   Non-gamer can complete first conversation without tutorials
   Story and humor engage players more than mechanics
   15-minute sessions feel complete and satisfying
   Relationships feel meaningful and progression clear
   Mobile controls feel natural and responsive
   Remember: This game succeeds through emotional engagement and narrative craft, not mechanical complexity. Every technical decision should serve the story and accessibility goals.
