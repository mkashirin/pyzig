const c = @import("c.zig");
const PyObject = c.PyObject;
const PyMethodDef = c.PyMethodDef;

const PyModuleDef_HEAD_INIT = c.PyModuleDef_Base{
    .ob_base = PyObject{
        .ob_refcnt = 1,
        .ob_type = null,
    },
};

pub export fn sumz(self: [*c]PyObject, args: [*c]PyObject) [*c]PyObject {
    var a: c_long, var b: c_long = .{ undefined, undefined };
    _ = self;
    if (!(c.PyArg_ParseTuple(args, "ll", &a, &b) != 0)) return null;
    return c.PyLong_FromLong((a + b));
}

pub export fn multz(self: [*c]PyObject, args: [*c]PyObject) [*c]PyObject {
    var a: c_long, var b: c_long = .{ undefined, undefined };
    _ = self;
    if (!(c.PyArg_ParseTuple(args, "ll", &a, &b) != 0)) return null;
    return c.PyLong_FromLong((a * b));
}

pub export fn divz(self: [*c]PyObject, args: [*c]PyObject) [*c]PyObject {
    var a: c_long, var b: c_long = .{ undefined, undefined };
    _ = self;
    if (!(c.PyArg_ParseTuple(args, "ll", &a, &b) != 0)) return null;
    return c.PyLong_FromLong(@divExact(a, b));
}

pub var methods = [_]PyMethodDef{
    PyMethodDef{
        .ml_name = "sumz",
        .ml_meth = @ptrCast(@alignCast(&sumz)),
        .ml_flags = @as(c_int, 1),
        .ml_doc = null,
    },
    PyMethodDef{
        .ml_name = "multz",
        .ml_meth = @ptrCast(@alignCast(&multz)),
        .ml_flags = @as(c_int, 1),
        .ml_doc = null,
    },
    PyMethodDef{
        .ml_name = "divz",
        .ml_meth = @ptrCast(@alignCast(&divz)),
        .ml_flags = @as(c_int, 1),
        .ml_doc = null,
    },
    PyMethodDef{
        .ml_name = null,
        .ml_meth = null,
        .ml_flags = 0,
        .ml_doc = null,
    },
};

pub var module = c.PyModuleDef{
    .m_name = "zigmodule",
    .m_methods = &methods,
};

pub export fn PyInit_zigmodule() [*c]PyObject {
    return c.PyModule_Create(&module);
}
