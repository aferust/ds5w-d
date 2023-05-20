module ds5w.winhelper;

import core.stdc.stddef : wchar_t;

import core.sys.windows.windows;

debug string GetLastErrorAsString()
{
    DWORD errorMessageID = GetLastError();
    if (errorMessageID == 0)
        return "success";

    LPSTR messageBuffer = null;

    size_t size = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, errorMessageID, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), cast(LPSTR)&messageBuffer, 0, NULL);

    string message = messageBuffer[0 .. size].dup;

    LocalFree(messageBuffer);

    return message;
}

__gshared const GUID_DEVINTERFACE_HID = GUID(
    0x4D1E55B2L, 0xF16F, 0x11CF,
    [0x88, 0xCB, 0x00, 0x11, 0x11, 0x00, 0x00, 0x30]
);

struct HIDD_ATTRIBUTES
{
    DWORD Size = HIDD_ATTRIBUTES.sizeof;
    USHORT VendorID;
    USHORT ProductID;
    USHORT VersionNumber;
}

alias PHIDP_PREPARSED_DATA = void*;

struct HIDP_CAPS
{
    ushort Usage;
    ushort UsagePage;
    ushort InputReportByteLength;
    ushort OutputReportByteLength;
    ushort FeatureReportByteLength;
    ushort[17] Reserved;

    ushort NumberLinkCollectionNodes;

    ushort NumberInputButtonCaps;
    ushort NumberInputValueCaps;
    ushort NumberInputDataIndices;

    ushort NumberOutputButtonCaps;
    ushort NumberOutputValueCaps;
    ushort NumberOutputDataIndices;

    ushort NumberFeatureButtonCaps;
    ushort NumberFeatureValueCaps;
    ushort NumberFeatureDataIndices;
}

alias PHIDP_CAPS = HIDP_CAPS*;

@nogc nothrow extern (C):

ubyte HidD_GetAttributes(
    HANDLE HidDeviceObject,
    HIDD_ATTRIBUTES* Attributes
);

int wcscpy_s(wchar_t*, size_t, const(wchar_t)*);

BOOLEAN HidD_GetPreparsedData(
    HANDLE HidDeviceObject,
    PHIDP_PREPARSED_DATA* PreparsedData
);

enum HIDP_STATUS_SUCCESS = 1114112; //0x110010;
int HidP_GetCaps(PHIDP_PREPARSED_DATA PreparsedData, PHIDP_CAPS Capabilities);

ubyte HidD_FreePreparsedData(PHIDP_PREPARSED_DATA);

size_t wcslen(const(wchar_t*));

ubyte HidD_GetFeature(HANDLE HidDeviceObject, void* ReportBuffer, ulong ReportBufferLength);
ubyte HidD_FlushQueue(HANDLE HidDeviceObject);
