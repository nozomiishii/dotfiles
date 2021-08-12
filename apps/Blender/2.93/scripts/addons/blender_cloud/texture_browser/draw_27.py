"""OpenGL drawing code for the texture browser.

Requires Blender 2.79 or older.
"""

import typing

import bgl
import blf
import bpy

Float2 = typing.Tuple[float, float]
Float3 = typing.Tuple[float, float, float]
Float4 = typing.Tuple[float, float, float, float]


def text(pos2d: Float2, display_text: typing.Union[str, typing.List[str]],
         rgba: Float4 = (1.0, 1.0, 1.0, 1.0),
         fsize=12,
         align='L'):
    """Draw text with the top-left corner at 'pos2d'."""

    dpi = bpy.context.user_preferences.system.dpi
    gap = 12
    x_pos, y_pos = pos2d
    font_id = 0
    blf.size(font_id, fsize, dpi)

    # Compute the height of one line.
    mwidth, mheight = blf.dimensions(font_id, "Tp")  # Use high and low letters.
    mheight *= 1.5

    # Split text into lines.
    if isinstance(display_text, str):
        mylines = display_text.split("\n")
    else:
        mylines = display_text
    maxwidth = 0
    maxheight = len(mylines) * mheight

    for idx, line in enumerate(mylines):
        text_width, text_height = blf.dimensions(font_id, line)
        if align == 'C':
            newx = x_pos - text_width / 2
        elif align == 'R':
            newx = x_pos - text_width - gap
        else:
            newx = x_pos

        # Draw
        blf.position(font_id, newx, y_pos - mheight * idx, 0)
        bgl.glColor4f(*rgba)
        blf.draw(font_id, " " + line)

        # saves max width
        if maxwidth < text_width:
            maxwidth = text_width

    return maxwidth, maxheight


def aabox(v1: Float2, v2: Float2, rgba: Float4):
    """Draw an axis-aligned box."""

    bgl.glColor4f(*rgba)
    bgl.glRectf(*v1, *v2)


def aabox_with_texture(v1: Float2, v2: Float2):
    """Draw an axis-aligned box with a texture."""

    bgl.glColor4f(1.0, 1.0, 1.0, 1.0)

    bgl.glEnable(bgl.GL_TEXTURE_2D)
    bgl.glBegin(bgl.GL_QUADS)
    bgl.glTexCoord2d(0, 0)
    bgl.glVertex2d(v1[0], v1[1])
    bgl.glTexCoord2d(0, 1)
    bgl.glVertex2d(v1[0], v2[1])
    bgl.glTexCoord2d(1, 1)
    bgl.glVertex2d(v2[0], v2[1])
    bgl.glTexCoord2d(1, 0)
    bgl.glVertex2d(v2[0], v1[1])
    bgl.glEnd()
    bgl.glDisable(bgl.GL_TEXTURE_2D)


def bind_texture(texture: bpy.types.Image):
    """Bind a Blender image to a GL texture slot."""
    bgl.glBindTexture(bgl.GL_TEXTURE_2D, texture.bindcode[0])


def load_texture(texture: bpy.types.Image) -> int:
    """Load the texture, return OpenGL error code."""
    return texture.gl_load(filter=bgl.GL_NEAREST, mag=bgl.GL_NEAREST)
