# ProceduralGenerations
Procedural Generation algorithms using Godot 3.5.1

First project is using famous Wave Function Collapse algorithm for generating a grid from tiles using principle of Sudoku or Lego. 
Simply put: in the grid, at first all tiles have all possible tiles and their rotations, but as tiles being added to the grid, neighboring tiles's possibilies get reduced.
This algortithms uses breadth first search across the grid, choosing tile with least amount of possibilities, collapsing it into one.
Possibly this could lead to very interesting usages of this algorithm, not just making tileset level. As a thought, imagine a game where you could have giant skeleton boss,
but the skeleton could be procedurally generated using such collapse algorithm, making a weird monstrousity every iteration. This could be any other "structured by rules" entities,
such as tanks, towers, geographic landscape etc. Hopefully this knowledge will be used in my future projects.

MDeOff
