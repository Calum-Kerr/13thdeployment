# Soulsborne Web Game

A web browser-based Souls-like game built with the Godot engine, featuring tight combat mechanics, interconnected level design, deep lore, challenging difficulty, and asynchronous multiplayer elements.

## Project Overview

This project aims to recreate the core experience of FromSoftware's Soulsborne series in a web browser environment using the Godot engine. The game will feature:

- Deliberate, weighty combat system with stamina management
- Interconnected level design with shortcuts and vertical exploration
- Deep lore delivered through environmental storytelling
- Challenging but fair difficulty curve
- Asynchronous multiplayer elements

## Development Principles

This project follows NASA's coding guidelines for safety and robustness:
- Modular, well-documented code
- Thorough testing procedures
- Clear component separation
- Comprehensive documentation

## Getting Started

### Prerequisites
- Godot Engine 4.x
- Web browser with WebGL support
- Git (for version control)

### Installation
1. Clone the repository
```
git clone https://github.com/yourusername/soulsborne-web-game.git
```
2. Open the project in Godot Engine
3. Run the project or export it for web

## Project Structure

```
/
├── src/                    # Source code
│   ├── player/             # Player character code
│   ├── enemies/            # Enemy AI and behavior
│   ├── levels/             # Level design and world building
│   ├── ui/                 # User interface elements
│   ├── systems/            # Game systems (combat, progression, etc.)
│   ├── multiplayer/        # Multiplayer functionality
│   ├── assets/             # Game assets
│   │   ├── audio/          # Sound effects and music
│   │   ├── models/         # 3D models
│   │   ├── textures/       # Textures and materials
│   │   └── animations/     # Character and object animations
│   └── utils/              # Utility functions and helpers
├── docs/                   # Documentation
├── tests/                  # Test scripts
└── .godot/                 # Godot project files
```

## Features

### Core Gameplay
- Stamina-based combat system
- Dodge rolls with invincibility frames
- Parry and riposte mechanics
- Equipment load affecting movement speed
- Death penalty with soul recovery

### World Design
- Interconnected levels with shortcuts
- Vertical exploration
- Environmental storytelling
- Checkpoint (bonfire) system

### Progression
- Soul/currency system
- Character leveling and stat allocation
- Weapon upgrading and scaling
- Item discovery and lore

### Multiplayer
- Player messages
- Death markers
- Phantom glimpses
- Cooperative summoning
- PvP invasions

## Roadmap

See the [checklist_roadmap.md](checklist_roadmap.md) file for a detailed development plan.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- FromSoftware for creating the Soulsborne series
- The Godot Engine team
- All contributors and testers 