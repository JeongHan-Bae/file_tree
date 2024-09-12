# cython: language_level=3
import bisect
import fnmatch
import json
import os
from collections import deque

__all__ = ['FileTree', 'TrimmedTree']
__author__ = "JeongHan Bae"
__email__ = "mastropseudo@gmail.com"
__date__ = "2024.09"
__license__ = "Apache License 2.0"
__github__ = "https://github.com/JeongHan-Bae"
__url__ = "https://github.com/JeongHan-Bae/file_tree"
__version__ = "1.0.0"

cdef class TreeNode:  # cdef, inner class
    cdef str name
    cdef bint is_leaf
    cdef list[TreeNode] children
    cdef set non_leaf_names

    cpdef str get_name(self):
        return self.name
    cpdef bint check_leaf(self):
        return self.is_leaf
    cpdef list[TreeNode] get_children(self):
        return self.children

    def __init__(self, str name, bint is_leaf=False):
        self.children = []
        self.name = name
        self.is_leaf = is_leaf
        if not is_leaf:
            self.non_leaf_names = set()

    cpdef void add_child(self, TreeNode node):
        # Add a child node to the current TreeNode and update the non_leaf_names set
        self.children.append(node)
        if not node.is_leaf:
            self.non_leaf_names.add(node.name)

    cdef void reserve_children(self, int size):
        # Reserve space for children to improve efficiency during additions
        self.children.extend([None] * size)
        self.children = self.children[:0]  # Ensure the list is the correct length

    cdef void sort_children(self):
        # Sort children by their name to maintain order
        self.children.sort(key=lambda node: node.name)

    def __lt__(self, TreeNode other):
        # Compare TreeNodes based on their name for sorting
        return self.name < other.name

    def __eq__(self, TreeNode other):
        # Check equality of TreeNodes based on their name
        return self.name == other.name

    cpdef str to_repr(self, int level = 0, tuple[int, int] depth = (0, 0)):
        # Generate a string representation of the TreeNode with optional depth control
        stack = deque([(self, level)])
        representation = ""

        folder_depth, file_depth = depth

        if folder_depth < 0 or file_depth < 0:
            raise ValueError("Depth values cannot be negative")

        while stack:
            current_node, current_level = stack.pop()
            indent = '    ' * current_level
            is_leaf = current_node.check_leaf()

            # Check depth constraints
            if is_leaf:
                if file_depth != 0 and current_level > file_depth:
                    continue
            else:
                if folder_depth != 0 and current_level > folder_depth:
                    continue

            # Generate the representation string
            if current_level > 0:
                representation += f"\n{indent}|-- {current_node.get_name()}"
            else:
                representation += f"{current_node.get_name()}"

            if not is_leaf:
                representation += '/'
                for child in reversed(current_node.get_children()):
                    stack.append((child, current_level + 1))

        return representation

    def __repr__(self):
        return self.to_repr(level=0)

    @staticmethod
    def from_repr(str repr_str) -> TreeNode:
        lines = repr_str.strip().splitlines()
        if not lines:
            return None # noqa

        root_name: str = lines[0].strip().replace('/', '')
        root_node = TreeNode(root_name) # noqa
        node_stack = deque([root_node])

        for line in lines[1:]:
            indent_level: int = len(line) - len(line.lstrip())
            level: int = indent_level // 4  # assuming each level of indent is 4 spaces
            line_content: str = line.strip()

            is_leaf = not line_content.endswith('/')
            if is_leaf:
                name: str = line_content.replace('|-- ', '').strip()
            else:
                name: str = line_content.replace('/', '').replace('|-- ', '').strip()

            new_node = TreeNode(name, is_leaf=is_leaf) # noqa

            while len(node_stack) > level + 1:
                node_stack.pop()

            parent_node = node_stack[-1]
            parent_node.add_child(new_node) # noqa

            if not is_leaf:
                node_stack.append(new_node)

        return root_node

    cpdef str to_md(self, int level=0, bint is_last=False, str prefix='', tuple[int, int] depth=(0, 0)):
        # Generate a markdown representation of the TreeNode with optional depth control
        folder_depth, file_depth = depth

        if folder_depth < 0 or file_depth < 0:
            raise ValueError("Depth values must be non-negative")

        stack = deque([(self, level, is_last, prefix)])
        md_representation = ""

        while stack:
            current_node, current_level, current_is_last, current_prefix = stack.pop()
            indent: str = current_prefix + (('└── ' if current_is_last else '├── ') if current_level > 0 else '')
            md_representation += f"{indent}{current_node.get_name()}/" if not current_node.check_leaf() \
                else f"{indent}{current_node.get_name()}"

            if not current_node.check_leaf():
                new_prefix: str = (current_prefix + ('    ' if current_is_last else '│   ')) \
                    if current_level > 0 else prefix

                if folder_depth == 0 and file_depth == 0:
                    # When both depths are 0, use the original method for simplicity and efficiency
                    children: list[TreeNode] = current_node.get_children() # noqa
                    if children:
                        # Process the last child node separately
                        last_child: TreeNode = children[-1]
                        stack.append((last_child, current_level + 1, True, new_prefix)) # noqa
                        # Process the remaining child nodes
                        for child in reversed(children[:-1]):
                            stack.append((child, current_level + 1, False, new_prefix)) # noqa
                else:
                    # Filter child nodes based on depth constraints
                    validate_stack = deque()
                    for child in current_node.get_children(): # noqa
                        if child.check_leaf():
                            if file_depth == 0 or current_level + 1 <= file_depth:
                                validate_stack.append(child)
                        else:
                            if folder_depth == 0 or current_level + 1 <= folder_depth:
                                validate_stack.append(child)

                    if validate_stack:
                        # Process the last valid child node
                        last_valid_child: TreeNode = validate_stack.pop()
                        stack.append((last_valid_child, current_level + 1, True, new_prefix)) # noqa
                        # Process the remaining valid child nodes
                        while validate_stack:
                            child: TreeNode = validate_stack.pop()
                            stack.append((child, current_level + 1, False, new_prefix)) # noqa

            if stack:
                md_representation += "\n"

        return md_representation

    @staticmethod
    def from_md(str md_str) -> TreeNode:
        lines = md_str.strip().splitlines()
        if not lines:
            return None # noqa

        root_name: str = lines[0].strip().replace('/', '')
        root_node = TreeNode(root_name) # noqa
        node_stack = deque([root_node])

        for line in lines[1:]:
            indent_level: int = len(line) - len(line.replace('│', '').lstrip())
            level: int = indent_level // 4  # assuming each level of indent is 4 spaces
            line_content: str = line.strip()

            is_leaf = not line_content.endswith('/')
            name: str = (line_content.replace('│', '').replace('└── ', '')
                         .replace('├── ', '').replace('/', '').strip())

            new_node: TreeNode = TreeNode(name, is_leaf=is_leaf) # noqa

            while len(node_stack) > level + 1:
                node_stack.pop()

            parent_node: TreeNode = node_stack[-1]
            parent_node.add_child(new_node) # noqa

            if not is_leaf:
                node_stack.append(new_node)

        return root_node

    cpdef dict to_dict(self):
        stack = deque([(self, None)])
        result_dict = {}

        while stack:
            current_node, parent_dict = stack.pop()
            node_dict = {current_node.get_name(): {} if not current_node.check_leaf() else None}

            if parent_dict is not None:
                parent_dict[current_node.get_name()] = node_dict[current_node.get_name()] # noqa

            if not current_node.check_leaf():
                for child in reversed(current_node.get_children()):
                    stack.append((child, node_dict[current_node.get_name()]))

            if parent_dict is None:
                result_dict = node_dict

        return result_dict

    @staticmethod
    def from_dict(dict node_dict) -> TreeNode:
        stack = deque([(None, node_dict)])
        root_node = None

        while stack:
            parent_node, current_dict = stack.pop()
            name = next(iter(current_dict))
            is_leaf = current_dict[name] is None
            current_node = TreeNode(name, is_leaf=is_leaf)

            if parent_node is not None:
                parent_node.add_child(current_node) # noqa
            else:
                root_node = current_node

            if not is_leaf:
                for child_name, child_dict in reversed(current_dict[name].items()):
                    stack.append((current_node, {child_name: child_dict})) # noqa

        return root_node

# Independent cdef function for internal use only
cdef bint _should_ignore(str path, list[str] ignore_patterns = None):
    cdef str pattern
    ignore_patterns = [] if ignore_patterns is None else ignore_patterns
    if os.path.isdir(path) and not path.endswith('/'): # noqa
        path += '/'
    for pattern in reversed(ignore_patterns):
        if pattern.startswith('!'):
            if fnmatch.fnmatch(path, pattern[1:]): # noqa
                return False  # Match the contain pattern
        else:
            if fnmatch.fnmatch(path, pattern): # noqa
                return True  # Match the ignore pattern

    return False  # None Match, not ignore

cdef void _build_tree(TreeNode root_node, str root_path, list[str] ignore_patterns=None):
    cdef TreeNode current_node
    cdef str current_path
    cdef str item
    cdef str item_path
    cdef str relative_path

    stack: deque[tuple[TreeNode, str]] = deque([(root_node, root_path)]) # noqa

    while stack:
        current_node, current_path = stack.pop()

        try:
            for item in os.listdir(current_path): # noqa
                item_path = os.path.join(current_path, item) # noqa
                relative_path = os.path.relpath(item_path, root_path) # noqa

                if _should_ignore(relative_path, ignore_patterns):
                    continue

                if os.path.isdir(item_path): # noqa
                    child_node = TreeNode(item)
                    current_node.add_child(child_node)
                    stack.append((child_node, item_path)) # noqa
                else:
                    leaf_node = TreeNode(item, is_leaf=True) # noqa
                    current_node.add_child(leaf_node)
        except PermissionError:
            print(f"Permission denied: {current_path}")


cdef void _build_tree_with_depth(TreeNode root_node, str root_path, tuple[int, int] depth, list[str] ignore_patterns = None):
    # Internal function to build the file tree with limited depth and optional ignore patterns.
    cdef int current_folder_depth = 0
    cdef int current_file_depth = 0
    cdef TreeNode current_node
    cdef str current_path
    cdef str item
    cdef str item_path
    cdef str relative_path

    stack: deque[tuple[TreeNode, str, int]] = deque([(root_node, root_path, current_folder_depth)]) # noqa
    folder_depth, file_depth = depth

    while stack:
        current_node, current_path, current_folder_depth = stack.pop() # noqa

        # Stop if the current folder depth exceeds the allowed folder depth
        if folder_depth != 0 and current_folder_depth > folder_depth:
            continue

        try:
            for item in os.listdir(current_path): # noqa
                item_path = os.path.join(current_path, item) # noqa
                relative_path = os.path.relpath(item_path, root_path) # noqa

                if _should_ignore(relative_path, ignore_patterns):
                    continue

                if os.path.isdir(item_path): # noqa
                    if folder_depth != 0 and current_folder_depth == folder_depth:
                        continue  # Limit dir, continue
                    # Process directories
                    child_node = TreeNode(item)
                    current_node.add_child(child_node)
                    stack.append((child_node, item_path, current_folder_depth + 1)) # noqa
                else:
                    # Process files
                    if file_depth != 0 and current_folder_depth >= file_depth:
                        continue
                    leaf_node = TreeNode(item, is_leaf=True) # noqa
                    current_node.add_child(leaf_node)
        except PermissionError:
            print(f"Permission denied: {current_path}")


class FileTree:  # def class, visible

    def __init__(self, str root_path, list[str] ignore=None):
        # Initialize the FileTree with the root path and build the tree structure
        if not os.path.exists(str(root_path)):
            raise ValueError(f"The path {root_path} does not exist.")

        self.root_path = root_path # noqa
        self.root_node = TreeNode(os.path.basename(str(root_path))) # noqa
        _build_tree(self.root_node, self.root_path, ignore_patterns=ignore)  # Call the external cdef function # noqa


    def where(self, str target) -> [str | None]:
        # Search for the target node and return its path if found
        stack = [(self.root_node, self.root_path)] # noqa
        cdef TreeNode current_node
        cdef str current_path
        cdef int index

        while stack:
            current_node, current_path = stack.pop()

            # Perform binary search for the target node in the children list
            index = bisect.bisect_left(current_node.children, TreeNode(target))
            if index < len(current_node.children) and current_node.children[index].get_name() == target: # noqa
                return os.path.join(current_path, target) # noqa

            # Convert non_leaf_names to list and perform binary search for each non-leaf node
            for non_leaf_name in sorted(current_node.non_leaf_names):
                index = bisect.bisect_left(current_node.children, TreeNode(non_leaf_name))
                if (index < len(current_node.children)
                        and current_node.children[index].get_name() == non_leaf_name): # noqa
                    stack.append((current_node.children[index], os.path.join(current_path, non_leaf_name))) # noqa

        return None  # Return None if the target node is not found

    def create_subtree(self, str relative_path) -> [FileTree | None]:
        # Create and return a subtree based on the relative path, handling ./ and ../
        path_queue = deque()
        path_parts = os.path.normpath(str(relative_path)).split(os.sep)
        cdef str part
        cdef TreeNode current_node = self.root_node # noqa
        cdef int index

        # Process the relative path and populate the queue
        for part in path_parts:
            if part == '.':
                continue  # Ignore current directory symbol
            elif part == '..':
                if not path_queue:
                    raise ValueError("Cannot navigate above the root directory.")
                path_queue.pop()  # Go up one directory
            else:
                path_queue.append(part)

        # Navigate the tree using the processed path queue
        while path_queue:
            part = path_queue.popleft()
            index = bisect.bisect_left(current_node.children, TreeNode(part))
            if index < len(current_node.children) and current_node.children[index].get_name() == part: # noqa
                current_node = current_node.children[index]
            else:
                raise ValueError(f"Path '{relative_path}' is invalid. '{part}' does not exist.")

        # At this point, current_node is the root of the subtree we want to return
        # Create a new FileTree object using the subtree root and the resolved path
        subtree_root_path = os.path.join(self.root_path, relative_path) # noqa
        subtree: FileTree = FileTree(subtree_root_path) # noqa
        subtree.root_node = current_node  # Set the root node to the found subtree

        return subtree  # Return the new FileTree

    def __repr__(self):
        # Generate a string representation of the FileTree for debugging purposes
        return f"Root Dir: {self.root_path}\n{self.root_node.to_repr(level=0)}" # noqa

    def to_str(self, tuple[int, int] depth = (0, 0)) -> str:
        # Generate a string representation of the FileTree with optional depth control.
        return f"Root Dir: {self.root_path}\n{self.root_node.to_repr(level=0, depth=depth)}" # noqa

    @staticmethod
    def from_str(repr_str: str) -> FileTree:
        lines = repr_str.strip().splitlines()
        if len(lines) < 2:
            return None # noqa

        # "Root Dir: <path>"
        root_path = lines[0].replace("Root Dir: ", "").strip() # noqa
        # root_node
        repr_content = "\n".join(lines[1:])
        root_node = TreeNode.from_repr(repr_content) # noqa

        tree = FileTree(root_path) # noqa
        tree.root_node = root_node
        return tree

    def to_md(self, tuple[int, int] depth = (0, 0)) -> str:
        return f"{self.root_node.to_md(depth=depth)}" # noqa

    @staticmethod
    def from_md(md_str: str) -> FileTree:
        lines = md_str.splitlines()
        if not lines:
            return None # noqa

        # Find first and last "```"
        start_idx = None
        end_idx = None
        for i, line in enumerate(lines):
            if "```" in line:
                if start_idx is None:
                    start_idx = i
                else:
                    end_idx = i
                    break

        # Format check
        if start_idx is None or end_idx is None:
            raise ValueError("Markdown format error: missing matching ``` markers.")

        start_indent: int = len(lines[start_idx]) - len(lines[start_idx].lstrip())
        end_indent: int = len(lines[end_idx]) - len(lines[end_idx].lstrip())

        if start_indent != end_indent:
            error_message = (
                f"Markdown format error: inconsistent indentation for ``` markers.\n"
                f"Start indent: {start_indent}, line: '{lines[start_idx]}'\n"
                f"End indent: {end_indent}, line: '{lines[end_idx]}'"
            )
            raise ValueError(error_message)

        # Get context between "```" and remove leading indents
        indent_length = start_indent
        md_content = "\n".join(line[indent_length:].rstrip() for line in lines[start_idx + 1:end_idx])

        root_node: TreeNode = TreeNode.from_md(md_content) # noqa

        root_path: str = root_node.get_name() # noqa

        tree = FileTree(root_path) # noqa
        tree.root_node = root_node
        return tree

    def dump_md(self,
                file_path: str,
                append: bool = False,
                indent: int = 0,
                tuple[int, int] depth=(0, 0),
                title: [str | None] = None) -> None:
        mode: str = 'a' if append else 'w'
        indent_space: str = ' ' * indent
        with open(file_path, mode, encoding='utf-8') as f:
            if title is not None:
                f.write(f"{title}\n\n")
            f.write(f"{indent_space}```\n")
            md_output = self.root_node.to_md(prefix=indent_space, depth=depth) # noqa
            f.write(md_output + '\n')
            f.write(f"{indent_space}```\n")

    @staticmethod
    def load_md(file_path: str) -> FileTree:
        # Load the tree from a Markdown file
        with open(file_path, 'r', encoding='utf-8') as f:
            md_str = f.read()
        return FileTree.from_md(md_str)

    def to_dict(self) -> dict:
        if self.root_node is None: # noqa
            return {}
        return self.root_node.to_dict() # noqa

    @staticmethod
    def from_dict(dict tree_dict, str root_path = None) -> FileTree:
        if not tree_dict:
            return None # noqa

        root_node = TreeNode.from_dict(tree_dict) # noqa

        if root_path is None:
            root_path = root_node.get_name()  # Use name of root node as path

        tree = FileTree(root_path) # noqa
        tree.root_node = root_node
        return tree

    def dump_json(self, str file_path):
        # Save the tree as a JSON file
        with open(file_path, 'w', encoding='utf-8') as f: # noqa
            json.dump(self.to_dict(), f, ensure_ascii=False, indent=4)

    @staticmethod
    def load_json(str file_path) -> FileTree:
        # Load the tree from a JSON file
        with open(file_path, 'r', encoding='utf-8') as f: # noqa
            node_dict = json.load(f)
        return FileTree.from_dict(node_dict)

def TrimmedTree(str root_path, tuple[int, int] depth = (0, 0), list[str] ignore = None) -> FileTree:
    # Creates a FileTree with limited depth based on the given path and depth tuple.
    cdef TreeNode root_node = TreeNode(os.path.basename(root_path)) # noqa
    _build_tree_with_depth(root_node, root_path, depth, ignore_patterns=ignore)
    tree = FileTree(root_path, ignore=['*']) # Generate an empty tree # noqa
    tree.__setattr__('root_node', root_node)
    return tree

def parse_ignore_file(str file_path, str comment_symbol = '#') -> list[str]:
    # Check if file exists and is not a directory
    if not os.path.exists(file_path): # noqa
        raise FileNotFoundError(f"The file '{file_path}' does not exist.")
    if not os.path.isfile(file_path): # noqa
        raise FileNotFoundError(f"'{file_path}' is not a valid file.")

    # Read and parse the file
    with open(file_path, 'r', encoding='utf-8') as f:  # noqa
        lines = f.readlines()

    # Remove comments and empty lines
    parsed_lines = [line.strip() for line in lines if line.strip() and not line.strip().startswith(comment_symbol)]  # noqa

    return parsed_lines