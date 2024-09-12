# file_tree.pyi
"""
Author: JeongHan Bae
Date: 2024

Classifier:
    - Programming Language :: Python :: 3
    - License :: OSI Approved :: Apache License 2.0
    - Operating System :: OS Dependent

This module provides the `FileTree` class to manage file directory trees.

For more information, please visit:
    https://github.com/JeongHan-Bae/file_tree

Copyright 2024 JeongHan Bae <mastropseudo@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""


from typing import Optional, List, Union, Dict, Tuple

__all__ = ['FileTree', 'TrimmedTree']
__author__ = "JeongHan Bae"
__email__ = "mastropseudo@gmail.com"
__date__ = "2024.09"
__license__ = "Apache License 2.0"
__github__ = "https://github.com/JeongHan-Bae"
__url__ = "https://github.com/JeongHan-Bae/file_tree"
__version__ = "1.0.0"


class FileTree:
    """
    FileTree is a class that represents a file directory tree. It provides methods to construct
    the tree from a root directory, search within the tree, and create subtrees based on relative paths.
    """

    root_path: str

    def __init__(self, root_path: str, ignore: Optional[List[str]] = None) -> None:
        """
        Initialize the FileTree with the root path and build the tree structure.

        :param root_path: The root directory path to build the tree from.
        :param ignore: A list of patterns to ignore during the tree build.
        :raises ValueError: If the path does not exist.
        """
        ...

    def where(self, target: str) -> Optional[str]:
        """
        Search for the target file or folder by its name and return its path if found.

        :param target: The name of the file or folder to search for.
        :return: The path to the target file or folder, or None if not found.
        """
        ...

    def create_subtree(self, relative_path: str) -> Optional[FileTree]:
        """
        Create and return a subtree based on the relative path.

        :param relative_path: The relative path to the desired subtree.
        :return: A new FileTree corresponding to the relative path, or None if not found.
        :raises ValueError: If the path is invalid or navigation above the root directory is attempted.
        """
        ...

    def __repr__(self) -> str:
        """
        Generate a string representation of the FileTree for debugging purposes.

        :return: The string representation of the FileTree.
        """
        ...

    def to_str(self, depth: Tuple[int, int] = (0, 0)) -> str:
        """
        Generate a string representation of the FileTree with optional depth control.

        :param depth: A tuple containing (folder_depth, file_depth). If 0, it means no depth limit.
        :return: A string representation of the FileTree with the specified depth.
        """
        ...

    @staticmethod
    def from_str(repr_str: str) -> FileTree:
        """
        Create a FileTree from a string representation.

        :param repr_str: A string representing the file tree structure.
        :return: A FileTree object created from the string.
        """
        ...

    def to_md(self, depth: Tuple[int, int] = (0, 0)) -> str:
        """
        Generate a markdown representation of the FileTree.

        :param depth: A tuple containing (folder_depth, file_depth). If 0, it means no depth limit.
        :return: A string in Markdown format representing the FileTree.
        """
        ...

    @staticmethod
    def from_md(md_str: str) -> FileTree:
        """
        Create a FileTree from a markdown string representation.

        The provided markdown string must contain the file tree structure
        wrapped within a code block marked by "```". This code block must be
        the first code block in the markdown string.

        :param md_str: A markdown string representing the file tree structure.
        :return: A FileTree object created from the markdown string.
        :raises ValueError: If the Markdown format is incorrect or the code block is missing.
        """

    def dump_md(self, file_path: str, append: bool = False, indent: int = 0, title: Optional[str] = None, depth: Tuple[int, int] = (0, 0)) -> None:
        """
        Export the markdown representation of the FileTree to a file.

        :param file_path: The path to the file where the markdown should be saved.
        :param append: Whether to append to the file (if True) or overwrite it (if False).
        :param indent: The number of spaces to indent the markdown content.
        :param title: An optional title to add to the beginning of the markdown content.
        :param depth: A tuple containing (folder_depth, file_depth). If 0, it means no depth limit.
        """
        ...

    @staticmethod
    def load_md(file_path: str) -> FileTree:
        """
        Load the FileTree from a markdown file.

        The markdown file must contain the file tree structure wrapped within
        a code block marked by "```". This code block must be the first code block
        in the markdown file.

        :param file_path: The path to the markdown file to load.
        :return: A FileTree object created from the markdown file.
        :raises ValueError: If the Markdown format is incorrect or the code block is missing.
        """
        ...

    def to_dict(self) -> Dict[str, Union[None, dict]]:
        """
        Convert the FileTree to a dictionary representation.

        :return: A dictionary representation of the FileTree.
        """
        ...

    @staticmethod
    def from_dict(tree_dict: Dict[str, Union[None, dict]], root_path: Optional[str] = None) -> FileTree:
        """
        Create a FileTree from a dictionary representation.

        :param tree_dict: A dictionary representing the file tree structure.
        :param root_path: The root path for the FileTree, or the root node name if not provided.
        :return: A FileTree object created from the dictionary.
        """
        ...

    def dump_json(self, file_path: str) -> None:
        """
        Save the FileTree as a JSON file.

        :param file_path: The path to the file where the JSON should be saved.
        """
        ...

    @staticmethod
    def load_json(file_path: str) -> FileTree:
        """
        Load the FileTree from a JSON file.

        :param file_path: The path to the JSON file to load.
        :return: A FileTree object created from the JSON file.
        """
        ...


def TrimmedTree(root_path: str, depth: Tuple[int, int] = (0, 0), ignore: Optional[List[str]] = None) -> FileTree:
    """
    Creates a FileTree with limited depth based on the given path, depth tuple, and optional ignore patterns.

    :param root_path: The root directory path to create the tree from.
    :param depth: A tuple containing (folder_depth, file_depth). If 0, it means no depth limit.
    :param ignore: A list of ignore patterns to exclude certain paths from the tree. Can be None.

    :return: FileTree: A FileTree object representing the directory structure with limited depth.
    """
    ...

def parse_ignore_file(file_path: str, comment_symbol: str = '#') -> list[str]:
    """
    Parse the ignore file and return a list of valid patterns.

    :param file_path: The path to the ignore file.
    :param comment_symbol: The symbol indicating the start of a comment line. Defaults to '#' as used in .gitignore files.
    :return: A list of patterns from the ignore file excluding comments and empty lines.
    :raises FileNotFoundError: If the file does not exist or is not a valid file.
    """
    ...
