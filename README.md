# PyZig

Create Python native extensions using Zig and Python C API!

## Usage

### Manual Build

First, create and activate a virtual environment and install dev dependencies
(using UV and bash):
```sh
uv venv ".venv"
source "./.venv/bin/activate"
uv pip install -r pyproject.toml --extra dev
```
Then build a shared library file by executing:
```sh
zig build
```
The Python package can be now built/installed like so (using UV):
```sh
uv build
uv pip install .
```
Once the installation is complete, the test can be run as follows:
```sh
python tests/test_summodule.py
```

### Automated Build

Use `ZIG_INSTALLED` environment varibale to specify what type of Zig compiler
to use (unset is for Python Ziglang module, 1 is for system-wide installed
binary). Then create and activate a virtual environment (example above). After
that, run the build shell script:
```sh
bash build_python_library.sh
```
Now, the tests can be run as the example from the previous section suggests.

Have fun!

## TODO

* Generate stubs automatically
* Build some Zig API for more convinient interaction with Python C API.
