class Node:
    def __init__(self, name):
        self.name = name
        self.children = []
    def add_child(self, child_node):
        self.children.append(child_node)


# recursive function to display nodes in a tree structure not using my previous logic
# recursive function to display nodes in a tree structure not using my previous logic
def show_nodes(n: Node, depth: int, count: int = 0):
    # Print the current node with appropriate indentation
    if depth == 0:
        print(n.name)
    else:
        # Create tree structure with proper branching symbols
        is_last = count == len(n.children) if depth > 0 else False
        prefix = "    " * (depth - 1) + ("└── " if is_last else "├── ")
        print(prefix + n.name)

    # Recursively print all children
    for i, child in enumerate(n.children):
        show_nodes(child, depth + 1, i + 1)

# Example usage
root = Node("Root")
child1 = Node("Child1")
child2 = Node("Child2")
child3 = Node("Child3")
subchild1 = Node("SubChild1")
subchild2 = Node("SubChild2")
child1.add_child(subchild1)
child1.add_child(subchild2)
root.add_child(child1)
root.add_child(child2)
root.add_child(child3)
show_nodes(root, 0)
