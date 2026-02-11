import from uuid { uuid4 }
cl import "./styles.css";

# A node becomes a persistent data container in the graph when attached to a root node
node Todo {
    has id: str,
        title: str,
        done: bool = False;
}

