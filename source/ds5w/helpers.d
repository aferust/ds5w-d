/*
	Helpers.h is part of DualSenseWindows
	https://github.com/Ohjurot/DualSense-Windows

	Contributors of this file:
	11.2020 Ludwig Füchsl

	Licensed under the MIT License (To be found in repository root directory)
*/
module ds5w.helpers;

import ds5w.dswapi;
import ds5w.ds5state;

Color color_R32G32B32_FLOAT(float r, float g, float b)
{
    return Color(cast(ubyte)(255.0F * r), cast(ubyte)(255.0F * g), cast(ubyte)(255.0F * b));
}

Color color_R32G32B32A32_FLOAT(float r, float g, float b, float a)
{
    return Color(cast(ubyte)(255.0F * r * a), cast(ubyte)(255.0F * g * a), cast(ubyte)(255.0F * b * a));
}

Color color_R8G8B8A8_UCHAR(ubyte r, ubyte g, ubyte b, ubyte a)
{
    return Color(
        cast(ubyte)(r * (a / 255.0f)), cast(ubyte)(g * (a / 255.0f)), cast(ubyte)(b * (a / 255.0f))
    );
}

Color color_R8G8B8_UCHAR_A32_FLOAT(ubyte r, ubyte g, ubyte b, float a)
{
    return Color(cast(ubyte)(r * a), cast(ubyte)(g * a), cast(ubyte)(b * a));
}

import core.stdc.stdlib : malloc, free;

T[] mallocSlice(T)(size_t len)
{
    return (cast(T*) malloc(len * T.sizeof))[0 .. len];
}

void freeSlice(T)(const(T)[] slice) nothrow @nogc
{
    free(cast(void*)(slice.ptr)); // const cast here
}
