const c = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", "1");
    @cInclude("Python.h");
});

const PyObject = c.PyObject;
const PyMethodDef = c.PyMethodDef;

const PyModuleDef_HEAD_INIT = c.PyModuleDef_Base{
    .ob_base = PyObject{
        .unnamed_0 = 1, // `ob_refcnt` field
        .ob_type = null,
    },
};

pub export fn sum(self: [*]PyObject, args: [*]PyObject) [*c]PyObject {
    var a: c_long = undefined;
    var b: c_long = undefined;
    _ = self;
    if (!(c._PyArg_ParseTuple_SizeT(args, "ll", &a, &b) != 0)) return null;
    return c.PyLong_FromLong((a + b));
}

pub var methods = [_:PyMethodDef{}]PyMethodDef{
    PyMethodDef{
        .ml_name = "sum",
        .ml_meth = @ptrCast(@alignCast(&sum)),
        .ml_flags = @as(c_int, 1),
        .ml_doc = null,
    },
};

pub var module = c.PyModuleDef{
    .m_name = "summodule",
    .m_methods = &methods,
};

pub export fn PyInit_summodule() [*c]PyObject {
    return c.PyModule_Create(&module);
}
