
### State

This directory includes classes that manage internal and external state on swayze.

This includes:

- Selection state: immutable value listenable collection of selections that also computes active 
cell.
- Table state: meta information of table such as name and id, and a reactive immutable state for 
columns and rows: count and rows sizes. 
- Cell state: guards a matrix of all cells of the table and its data, each cell is a immutable
object, but the matrix is mutable. 
