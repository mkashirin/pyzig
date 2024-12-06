# PyZig

Create Python native extensions using Zig and Python C API!

## Usage

First, build a shared library file by executing:
```sh
zig build
```
Then create a virtual environment (using UV):
```
uv venv ".venv"
````
The Python package can be now built/installed like so (using UV):
```sh
uv build
uv pip install .
```
Once the installation is complete, the test can be run as follows:
```sh
python tests/test_sum.py
```
Have fun!

## TODO

* Generate stubs automatically
