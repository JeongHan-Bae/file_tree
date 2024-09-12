# FileTree

**Author:** JeongHan Bae  
**Date:** 2024

### Classifier:
- Programming Language :: Python :: 3
- License :: OSI Approved :: Apache License 2.0
- Operating System :: OS Dependent

This package provides the `FileTree` class to manage file directory trees. It includes features like searching for files, creating subtrees, and exporting/importing tree structures in different formats.

For more information, please visit:  
[https://github.com/JeongHan-Bae/file_tree](https://github.com/JeongHan-Bae/file_tree)

## Project Structure

Here is an overview of the `file_tree` project structure and the purpose of each file and directory:

```markdown
file_tree/
├── include/
│   └── file_tree.pyi           # Type stub file with function and class declarations for IDEs and type checkers
├── INFO/
│   └── METADATA                # Metadata file with project details such as author, version, and license
├── make/
│   └── file_tree.cp310-win_amd64.pyd  # Compiled extension module for Python 3.10 on Windows (64-bit)
├── src/
│   └── file_tree.pyx           # Cython source file containing the core implementation of the module
├── wheel/                      # Directory for generated wheel files (compiled Python package)
├── build_ext.py                # Script for building the extension module from the Cython source
├── make_wheel.py               # Script for creating the wheel package for distribution
├── pyproject.toml              # Configuration file specifying build requirements and settings (PEP 518)
├── README.md                   # Project README file containing instructions and documentation
└── requirements.txt            # File listing dependencies required to run or develop the project
```

Each component serves a specific role in the development, building, and distribution process:

- **include/file_tree.pyi**: Type stub file for function and class declarations, used by IDEs and type checkers to understand the structure of the `file_tree` module.
- **INFO/METADATA**: Metadata about the project, including the author, version, and license information.
- **make/file_tree.cp310-win_amd64.pyd**: Compiled extension module for Python 3.10 on Windows (64-bit architecture).
- **src/file_tree.pyx**: Cython source file, which contains the core implementation of the `file_tree` module.
- **wheel/**: A directory where generated wheel files (compiled Python packages) are stored.
- **build_ext.py**: Script to build the extension module from the Cython source file.
- **make_wheel.py**: Script to package the project into a wheel file for distribution.
- **pyproject.toml**: Configuration file specifying build dependencies and settings in accordance with [PEP 518](https://www.python.org/dev/peps/pep-0518/).
- **README.md**: The main documentation file that explains how to use and contribute to the project.
- **requirements.txt**: A list of dependencies required to run or develop the project.



### License

This project is licensed under the Apache License 2.0.  
You may not use this file except in compliance with the License.  
You may obtain a copy of the License at:

[https://www.apache.org/licenses/LICENSE-2.0](https://www.apache.org/licenses/LICENSE-2.0)

---

## Application Instructions

### Creating a `FileTree` Object

#### 1. **Using `FileTree` Class**

To create a `FileTree` instance from a root path, you can use the `FileTree` class constructor. Optionally, you can provide a list of ignore patterns. If `ignore` is not provided, no files or directories will be ignored.

**Example:**
```python
tree = FileTree(root_path="/path/to/root", ignore=["*.tmp", "cache/"])
```
- **root_path**: The path from which the tree will be constructed.
- **ignore**: An optional list of patterns to exclude specific files or directories. If omitted, all files and directories will be included.

> **Note**: You don’t need to pass `ignore` explicitly if you want to include all files and directories.
#### 1.~ **Using `parse_ignore_file` for Convenient Ignore Handling**

To simplify managing ignore patterns, we provide the `parse_ignore_file` function. This function allows you to parse an ignore file (e.g., `.gitignore` or `.some_other_ignore`), making it easier to respect ignore patterns already defined in your project without manually specifying them.

**Example:**
```python
# Parsing a .gitignore file for ignore patterns
ignore_patterns = parse_ignore_file("/path/to/.gitignore")
tree = FileTree(root_path="/path/to/root", ignore=ignore_patterns)
```

- **file_path**: The path to the ignore file (e.g., `.gitignore`, `.some_other_ignore`).
- **comment_symbol**: An optional symbol that denotes the start of a comment in the ignore file. Defaults to `'#'` as used in `.gitignore` files.

> **Note**: The `parse_ignore_file` function ignores empty lines and comments automatically, making it easier to handle ignore patterns from existing ignore files.

**Example with a custom comment symbol:**
```python
ignore_patterns = parse_ignore_file("/path/to/.some_other_ignore", comment_symbol="//")
tree = FileTree(root_path="/path/to/root", ignore=ignore_patterns)
```

Using `parse_ignore_file` simplifies the process of loading ignore patterns from files and ensures that your file tree is built according to predefined ignore rules, helping you maintain consistency with existing project configurations.

---

This creates a new subsection specifically for the auxiliary function, making it clear that `parse_ignore_file` is an additional, but helpful, feature.

#### 2. **Using `TrimmedTree` Function**

The `TrimmedTree` function allows you to create a `FileTree` with a depth limit. If `depth` is not provided, it defaults to `(0, 0)`, meaning there is no depth limit for both folders and files. Similarly, `ignore` is optional and defaults to including all files and directories.

**Example:**
```python
trimmed_tree = TrimmedTree(root_path="/path/to/root", depth=(2, 1), ignore=["*.log"])
```
- **root_path**: The root directory from which the tree will be constructed.
- **depth**: A tuple specifying folder and file depth limits. If not provided, it defaults to `(0, 0)` (no depth limit).
- **ignore**: An optional list of patterns to exclude files or directories. If not provided, no files or directories will be ignored.

> **Note**: You don’t need to pass `depth` or `ignore` explicitly if you want no depth limit and no ignored patterns.

**Without explicitly passing `depth` and `ignore`:**
```python
trimmed_tree = TrimmedTree(root_path="/path/to/root")
```

> **Important**: While this is possible, it’s **not recommended**. Using `TrimmedTree` without specifying `depth` and `ignore` results in extra overhead compared to directly creating a `FileTree`. If you do not need depth limitation, you should instantiate `FileTree` directly for better performance:

In cases where you need depth control, use `TrimmedTree` with an explicitly defined depth.

---

### Searching the `FileTree`

Use the `where` method to search for a target file or folder by name and retrieve its path if found.

**Example:**
```python
path_to_file = tree.where(target="file.txt")
```
- **target**: The name of the file or folder to search for.
- **Returns**: The path to the file or folder if found, otherwise `None`.

---

### Creating a Subtree

The `create_subtree` method allows you to create a subtree from a relative path.

**Example:**
```python
subtree = tree.create_subtree(relative_path="subdirectory")
```
- **relative_path**: The relative path to the desired subtree.
- **Returns**: A new `FileTree` representing the subtree, or `None` if the path is invalid.

---

### String and Markdown Representations

#### 1. **Convert to String**

You can generate a string representation of the file tree with optional depth control. If `depth` is `(0, 0)`, there is no limit on folder or file depth.

**Example:**
```python
tree_str = tree.to_str(depth=(2, 1))
```
- **depth**: A tuple with folder and file depth limits. If not passed, it defaults to `(0, 0)` (no depth limit).

#### 2. **Convert to Markdown**

Similarly, you can generate a markdown representation of the tree.

**Example:**
```python
markdown_repr = tree.to_md(depth=(2, 0))
```
- **depth**: A tuple with folder and file depth limits. If not passed, it defaults to `(0, 0)` (no depth limit).

---

### Exporting and Importing Trees

#### 1. **Export to Markdown (`dump_md`)**

To export the file tree to a markdown file, you can use the `dump_md` method. This allows you to append to the file, indent the content, and add a title at the beginning of the markdown content. The `depth` parameter can be used to control how deep the tree is represented. If not passed, `depth` defaults to `(0, 0)`.

**Example:**
```python
tree.dump_md(file_path="tree.md", append=False, indent=4, title="My File Tree", depth=(3, 2))
```

- **file_path**: The path to the markdown file where the tree will be saved.
- **append**: If `True`, the markdown will be appended to the existing file. If `False` (default), the file will be overwritten.
- **indent**: The number of spaces to indent the markdown content. Default is 0.
- **title**: An optional title that will be added at the beginning of the markdown. If `None`, no title is added.
- **depth**: A tuple of two integers, controlling how deep the folder and file structure will be shown. If not passed, defaults to `(0, 0)`.

#### 2. **Load from Markdown (`load_md`)**

To load a `FileTree` from a markdown file, the markdown must contain a code block marked by "```". Only the first code block in the file will be analyzed to construct the file tree. Any additional code blocks will be ignored.

**Example:**
```python
loaded_tree = FileTree.load_md(file_path="tree.md")
```

- **file_path**: The path to the markdown file to load.
- **Returns**: A `FileTree` object created from the markdown file.
- **Note**: Only the first code block in the markdown file is analyzed. If the format is incorrect or the code block is missing, a `ValueError` will be raised.

#### 3. **Export to JSON**

To export the file tree to a JSON file:

**Example:**
```python
tree.dump_json(file_path="tree.json")
```

#### 4. **Load from JSON**

To load a `FileTree` from a JSON file:

**Example:**
```python
tree_from_json = FileTree.load_json(file_path="tree.json")
```
