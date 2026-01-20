# Node
The Node is the base struct used to represent objects in the game. Whether it be audio, visual, functional, or otherwise, it can be represented by a node.

## Node Properties
Each node has some basic generic properties for processing.
```odin
    id: NodeID,
    name: string,
    type: NodeType,
    parent: NodeIndex,
    children: [dynamic]NodeIndex,
    nodeManager: ^NodeManager,
    layer: string,
    initialize: nodeInitializeSignature,
    enter_tree: proc(node: rawptr),
    ready: nodeReadySignature,
    process: nodeProcessSignature,
    draw: nodeDrawSignature,
    exit_tree: proc(node: rawptr),
    is_initialized: bool,
    globalTransform: proc(node: ^Node) -> TransformComponent,

```

