import os

from file_tree import FileTree, TrimmedTree, parse_ignore_file

import fnmatch




# 示例用法
gitignore_list = parse_ignore_file('.gitignore')
gitignore_list.append('check.py')
gitignore_list.append('.gitignore')
gitignore_list.append('wheel/*')
gitignore_list.append('!wheel/')
print(gitignore_list)
tree = TrimmedTree('.', ignore=gitignore_list)
print(tree.to_md())
