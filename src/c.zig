pub usingnamespace @cImport({
    @cDefine("Py_LIMITED_API", "0x030b0000");
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
    @cInclude("structmember.h");
});