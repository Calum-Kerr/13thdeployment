# Source Code Structure

This directory contains the source code for the Soulsborne Web Game project. The code is organized into several subdirectories, each with a specific purpose.

## Directory Structure

- `player/`: Player character code, including movement, combat, and stats
- `enemies/`: Enemy AI and behavior, including standard enemies and bosses
- `levels/`: Level design and world building
- `ui/`: User interface elements, including menus and HUD
- `systems/`: Game systems such as combat, progression, and checkpoints
- `multiplayer/`: Multiplayer functionality, including messages and phantoms
- `assets/`: Game assets, including audio, models, textures, and animations
- `utils/`: Utility functions and helpers

## Main Files

- `main.tscn` and `main.gd`: The main entry point for the game
- `levels/game.tscn` and `levels/game.gd`: The main game scene

## Coding Guidelines

All code in this project follows NASA's coding guidelines for safety and robustness:

- Simple control flow
- Fixed upper bounds for loops
- Limited function size
- Consistent error handling
- Clear documentation
- Thorough testing

For more details, see the [NASA Coding Guidelines](../docs/nasa_coding_guidelines.md) document.

## Adding New Code

When adding new code to the project:

1. Place it in the appropriate directory based on its purpose
2. Follow the established naming conventions
3. Document the code with comments
4. Write tests for the code in the `tests/unit/` directory
5. Ensure the code passes all existing tests

## Naming Conventions

- Classes: PascalCase (e.g., `PlayerCharacter`)
- Functions and variables: snake_case (e.g., `move_player()`, `health_points`)
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)
- Signals: snake_case (e.g., `player_died`)
- Files: snake_case (e.g., `player_character.gd`)

## Documentation

All code should be documented with comments:

- Class-level comments describing the purpose of the class
- Function-level comments describing what the function does
- Complex code sections should have inline comments explaining how they work

Example:

```gdscript
"""
PlayerCharacter: Main player character class.
Handles movement, combat, and stats.
"""

# Constants
const MAX_HEALTH = 100

# Properties
var current_health: int = MAX_HEALTH

func take_damage(amount: int) -> void:
    """
    Apply damage to the player.
    
    Parameters:
        amount: The amount of damage to apply
    """
    current_health = max(0, current_health - amount)
    
    # Check if the player has died
    if current_health == 0:
        _die()
``` 