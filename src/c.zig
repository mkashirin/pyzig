// Export the Python C API
pub usingnamespace @cImport({
    @cDefine("Py_LIMITED_API", "0x030B0000"); // Hardcoded for 3.11 for now
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
    @cInclude("structmember.h");
});
