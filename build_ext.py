from setuptools import setup, Extension
from Cython.Build import cythonize
import os
import sys

# Define platform-specific compile and link arguments
if sys.platform == "win32":
    extra_compile_args = ["/O2"]  # Optimization flag for MSVC
    extra_link_args = []
else:
    extra_compile_args = ["-O2"]  # Optimization flag for GCC/Clang
    extra_link_args = []

# Define the extension module for C++
extensions = [
    Extension(
        name="file_tree",  # The name of the compiled module
        sources=[os.path.join('src', 'file_tree.pyx')],  # The Cython source file
        include_dirs=[os.path.join(os.getcwd())],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        language="c++"  # Set the language to C++
    )
]

# Setup function to build the module
setup(
    name="FileTreeModule",
    version="1.0",
    description="A module to handle file tree operations.",
    ext_modules=cythonize(extensions, language_level="3"),  # Set language level to Python 3
    zip_safe=False,
)
