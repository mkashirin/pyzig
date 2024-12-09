// Export the Python C API
pub usingnamespace @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
    @cInclude("structmember.h");
});
