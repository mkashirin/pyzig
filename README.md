<h1 align="center">PyZig</h1>

<p align="center">
Create Python native extensions using Zig and Python C API!
</p>

## Usage

First, create and activate a virtual environment and install dev dependencies
(using UV and bash):
```sh
uv venv
source ".venv/bin/activate"
uv pip install -r "pyproject.toml" --extra "dev"
```

### Manual Build and Installation

Then build a shared library file by executing:
```sh
zig build
```
The Python package can be now built and installed like so (using UV):
```sh
uv build
uv pip install "."
```

### Automated Build and Installation

Use `ZIG_INSTALLED` environment variable to specify what type of Zig compiler
to use (unset is for Python Zig module, 1 is for system-wide installed
binary). Then create and activate a virtual environment (example above). After
that, run the build shell script:
```sh
bash "build_python_library.sh"
```

### Testing

Once the installation is complete, the test can be run as follows:
```sh
python "tests/test_zigmodule.py"
```

Have fun!

## TODOs

- Generate stubs automatically
- Build some Zig API for more convinient interaction with Python C API.
