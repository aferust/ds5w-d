module ds5w.device;

import core.stdc.stddef : wchar_t;

/*
	Device.h is part of DualSenseWindows
	https://github.com/Ohjurot/DualSense-Windows

	Contributors of this file:
	11.2020 Ludwig Füchsl

	Licensed under the MIT License (To be found in repository root directory)
*/

/// <summary>
/// Enum for device connection type
/// </summary>
enum DeviceConnection : ubyte
{
    /// <summary>
    /// Controler is connected via USB
    /// </summary>
    USB = 0,

    /// <summary>
    /// Controler is connected via bluetooth
    /// </summary>
    BT = 1,
}

/// <summary>
/// Struckt for storing device enum info while device discovery
/// </summary>
struct DeviceEnumInfo
{
    /// <summary>
    /// Encapsulate data in struct to (at least try) prevent user from modifing the context
    /// </summary>
    struct Internal
    {
        /// <summary>
        /// Path to the discovered device
        /// </summary>
        wchar_t[260] path;

        /// <summary>
        /// Connection type of the discoverd device
        /// </summary>
        DeviceConnection connection;
    }

    Internal _internal;
}

/// <summary>
/// Device context
/// </summary>
struct DeviceContext
{
    /// <summary>
    /// Encapsulate data in struct to (at least try) prevent user from modifing the context
    /// </summary>
    struct Internal
    {
        /// <summary>
        /// Path to the device
        /// </summary>
        wchar_t[260] devicePath;

        /// <summary>
        /// Handle to the open device
        /// </summary>
        void* deviceHandle;

        /// <summary>
        /// Connection of the device
        /// </summary>
        DeviceConnection connection;

        /// <summary>
        /// Current state of connection
        /// </summary>
        bool connected;

        /// <summary>
        /// HID Input buffer (will be allocated by the context init function)
        /// </summary>
        ubyte[547] hidBuffer;
    }

    Internal _internal;
}
