"""Compatibility functions to support Blender 2.79 and 2.80+ in one code base."""
import functools

import bpy


if bpy.app.version < (2, 80):
    SYNC_SELECT_VERSION_ICON = 'DOTSDOWN'
else:
    SYNC_SELECT_VERSION_ICON = 'DOWNARROW_HLT'


# Get references to all property definition functions in bpy.props,
# so that they can be used to replace 'x = IntProperty()' to 'x: IntProperty()'
# dynamically when working on Blender 2.80+
__all_prop_funcs = {
    getattr(bpy.props, propname)
    for propname in dir(bpy.props)
    if propname.endswith('Property')
}

def convert_properties(class_):
    """Class decorator to avoid warnings in Blender 2.80+

    This decorator replaces property definitions like this:

        someprop = bpy.props.IntProperty()

    to annotations, as introduced in Blender 2.80:

        someprop: bpy.props.IntProperty()

    No-op if running on Blender 2.79 or older.
    """

    if bpy.app.version < (2, 80):
        return class_

    if not hasattr(class_, '__annotations__'):
        class_.__annotations__ = {}

    attrs_to_delete = []
    for name, value in class_.__dict__.items():
        if not isinstance(value, tuple) or len(value) != 2:
            continue

        prop_func, kwargs = value
        if prop_func not in __all_prop_funcs:
            continue

        # This is a property definition, replace it with annotation.
        attrs_to_delete.append(name)
        class_.__annotations__[name] = value

    for attr_name in attrs_to_delete:
        delattr(class_, attr_name)

    return class_


@functools.lru_cache()
def factor(factor: float) -> dict:
    """Construct keyword argument for UILayout.split().

    On Blender 2.8 this returns {'factor': factor}, and on earlier Blenders it returns
    {'percentage': factor}.
    """
    if bpy.app.version < (2, 80, 0):
        return {'percentage': factor}
    return {'factor': factor}
