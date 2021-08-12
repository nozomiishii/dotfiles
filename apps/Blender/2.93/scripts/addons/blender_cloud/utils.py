# ##### BEGIN GPL LICENSE BLOCK #####
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# ##### END GPL LICENSE BLOCK #####

import json
import pathlib
import typing
from typing import Any, Dict, Optional, Tuple


def sizeof_fmt(num: int, suffix="B") -> str:
    """Returns a human-readable size.

    Source: http://stackoverflow.com/a/1094933/875379
    """

    for unit in ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"]:
        if abs(num) < 1024:
            return "%.1f %s%s" % (num, unit, suffix)
        num //= 1024

    return "%.1f Yi%s" % (num, suffix)


def find_in_path(path: pathlib.Path, filename: str) -> Optional[pathlib.Path]:
    """Performs a breadth-first search for the filename.

    Returns the path that contains the file, or None if not found.
    """

    import collections

    # Be lenient on our input type.
    if isinstance(path, str):
        path = pathlib.Path(path)

    if not path.exists():
        return None
    assert path.is_dir()

    to_visit = collections.deque([path])
    while to_visit:
        this_path = to_visit.popleft()

        for subpath in this_path.iterdir():
            if subpath.is_dir():
                to_visit.append(subpath)
                continue

            if subpath.name == filename:
                return subpath

    return None


# Mapping from (module name, function name) to the last value returned by that function.
_pyside_cache: Dict[Tuple[str, str], Any] = {}


def pyside_cache(wrapped):
    """Decorator, stores the result of the decorated callable in Python-managed memory.

    This is to work around the warning at
    https://www.blender.org/api/blender_python_api_master/bpy.props.html#bpy.props.EnumProperty
    """

    import functools

    @functools.wraps(wrapped)
    # We can't use (*args, **kwargs), because EnumProperty explicitly checks
    # for the number of fixed positional arguments.
    def decorator(self, context):
        result = None
        try:
            result = wrapped(self, context)
            return result
        finally:
            _pyside_cache[wrapped.__module__, wrapped.__name__] = result

    return decorator


def redraw(self, context):
    if context.area is None:
        return
    context.area.tag_redraw()


class JSONEncoder(json.JSONEncoder):
    """JSON encoder with support for some Blender types."""

    def default(self, o):
        if o.__class__.__name__ == "IDPropertyGroup" and hasattr(o, "to_dict"):
            return o.to_dict()
        return super().default(o)
