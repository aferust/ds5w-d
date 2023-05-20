/*
	DualSenseWindows API
	https://github.com/Ohjurot/DualSense-Windows

	MIT License

	Copyright (c) 2020 Ludwig Füchsl

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

*/
module ds5w.io;

import ds5w.dswapi;
import ds5w.device;
import ds5w.ds5state;
import ds5w.dscrc32;
import ds5w.winhelper;
import ds5w.ds5input;
import ds5w.ds5output;

import core.stdc.stddef : wchar_t;
import core.stdc.stdlib : alloca;

import core.sys.windows.windows;
import core.sys.windows.setupapi;

/// <summary>
/// Enumerate all ds5 deviced connected to the computer
/// </summary>
/// <param name="devInfoArr">A slice of DeviceEnumInfo objects / DeviceEnumInfo pointers</param>
/// <param name="requiredLength">pointer to uint witch recives the required total length</param>
/// <returns>DS5W Return value</returns>
DS5W_ReturnValue enumDevices(DeviceEnumInfo[] devInfoArr, size_t* requiredLength)
{
    size_t inArrLength = devInfoArr.length;
    // Check for invalid non expected buffer
    if (inArrLength && !devInfoArr)
    {
        inArrLength = 0;
    }

    // Get all hid devices from devs
    HANDLE hidDiHandle = SetupDiGetClassDevs(&GUID_DEVINTERFACE_HID, null, null, DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);
    if (!hidDiHandle || (hidDiHandle == INVALID_HANDLE_VALUE))
    {
        return DS5W_E_EXTERNAL_WINAPI;
    }

    // Index into input array
    uint inputArrIndex = 0;
    bool inputArrOverflow = false;

    // Enumerate over hid device
    DWORD devIndex = 0;
    SP_DEVINFO_DATA hidDiInfo;
    hidDiInfo.cbSize = SP_DEVINFO_DATA.sizeof;

    while (SetupDiEnumDeviceInfo(hidDiHandle, devIndex, &hidDiInfo))
    {
        // Enumerate over all hid device interfaces
        DWORD ifIndex = 0;
        SP_DEVICE_INTERFACE_DATA ifDiInfo;
        ifDiInfo.cbSize = SP_DEVICE_INTERFACE_DATA.sizeof;

        while (SetupDiEnumDeviceInterfaces(hidDiHandle, &hidDiInfo, &GUID_DEVINTERFACE_HID, ifIndex, &ifDiInfo))
        {

            // Query device path size
            DWORD requiredSize = 0;
            SetupDiGetDeviceInterfaceDetailW(hidDiHandle, &ifDiInfo, null, 0, &requiredSize, null);

            // Check size
            if (requiredSize > (260 * wchar_t.sizeof))
            {
                SetupDiDestroyDeviceInfoList(hidDiHandle);
                return DS5W_E_EXTERNAL_WINAPI;
            }

            // Allocate memory for path on the stack
            SP_DEVICE_INTERFACE_DETAIL_DATA_W* devicePath = cast(
                SP_DEVICE_INTERFACE_DETAIL_DATA_W*) alloca(requiredSize);

            if (!devicePath)
            {
                SetupDiDestroyDeviceInfoList(hidDiHandle);
                return DS5W_E_STACK_OVERFLOW;
            }

            // Get device path
            devicePath.cbSize = SP_DEVICE_INTERFACE_DETAIL_DATA_W.sizeof;
            SetupDiGetDeviceInterfaceDetailW(hidDiHandle, &ifDiInfo, devicePath, requiredSize, NULL, NULL);

            // Check if input array has space
            // Check if device is reachable
            HANDLE deviceHandle = CreateFileW(devicePath.DevicePath, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);

            // Check if device is reachable
            if (deviceHandle && (deviceHandle != INVALID_HANDLE_VALUE))
            {

                // Get vendor and product id
                uint vendorId = 0;
                uint productId = 0;
                HIDD_ATTRIBUTES deviceAttributes;
                if (HidD_GetAttributes(deviceHandle, &deviceAttributes))
                {
                    vendorId = deviceAttributes.VendorID;
                    productId = deviceAttributes.ProductID;
                }

                // Check if ids match
                if (vendorId == PSVENDOR &&
                    (productId == DEVICE_VARIANT.DS_REGULAR || productId == DEVICE_VARIANT.DS_EDGE))
                {
                    debug
                    {
                        import std.stdio;

                        writeln("vendorId ", vendorId, " productId ", productId);
                    }
                    // Get pointer to target
                    DeviceEnumInfo* ptrInfo = null;
                    if (inputArrIndex < inArrLength)
                    {
                        ptrInfo = &devInfoArr[inputArrIndex];
                    }

                    // Copy path
                    if (ptrInfo)
                    {
                        wcscpy_s(ptrInfo._internal.path.ptr, 260, cast(
                                const(wchar_t)*) devicePath.DevicePath);
                    }

                    // Get preparsed data
                    PHIDP_PREPARSED_DATA ppd;
                    if (HidD_GetPreparsedData(deviceHandle, &ppd))
                    {

                        // Get device capcbilitys
                        HIDP_CAPS deviceCaps;

                        if (HidP_GetCaps(ppd, &deviceCaps) == HIDP_STATUS_SUCCESS)
                        {
                            debug
                            {
                                import core.stdc.stdio : printf;
                                import std.stdio : writeln;

                                writeln(deviceCaps);
                                printf("%ls\n", ptrInfo._internal.path.ptr);
                            }
                            // Check for device connection type
                            if (ptrInfo)
                            {
                                // Check if controller matches USB specifications
                                if (deviceCaps.InputReportByteLength == 64)
                                {
                                    ptrInfo._internal.connection = DeviceConnection.USB;

                                    // Device found and valid -> Inrement index
                                    inputArrIndex++;
                                }
                                // Check if controler matches BT specifications
                            else if (
                                    deviceCaps.InputReportByteLength == 78)
                                {
                                    ptrInfo._internal.connection = DeviceConnection.BT;

                                    // Device found and valid -> Inrement index
                                    inputArrIndex++;
                                }

                                ptrInfo.variant = cast(DEVICE_VARIANT) productId;
                            }
                        }

                        // Free preparsed data
                        HidD_FreePreparsedData(ppd);
                    }
                }

                // Close device
                CloseHandle(deviceHandle);
            }

            // Increment index
            ifIndex++;
        }

        // Increment index
        devIndex++;
    }

    // Close device enum list
    SetupDiDestroyDeviceInfoList(hidDiHandle);

    // Set required size if exists
    if (requiredLength)
    {
        *requiredLength = inputArrIndex;
    }

    // Check if array was suficient
    if (inputArrIndex <= inArrLength)
    {
        return DS5W_OK;
    }
    // Else return error
    else
    {
        return DS5W_E_INSUFFICIENT_BUFFER;
    }
}

/// <summary>
/// Initializes a DeviceContext from its enum infos
/// </summary>
/// <param name="ptrEnumInfo">Pointer to enum object to create device from</param>
/// <param name="ptrContext">Pointer to context to create to</param>
/// <returns>If creation was successfull</returns>
DS5W_ReturnValue initDeviceContext(DeviceEnumInfo* ptrEnumInfo, DeviceContext* ptrContext)
{
    // Check if pointers are valid
    if (!ptrEnumInfo || !ptrContext)
    {
        return DS5W_E_INVALID_ARGS;
    }

    // Check len
    if (wcslen(ptrEnumInfo._internal.path.ptr) == 0)
    {
        return DS5W_E_INVALID_ARGS;
    }

    // Connect to device
    HANDLE deviceHandle = CreateFileW(ptrEnumInfo._internal.path.ptr, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, null, OPEN_EXISTING, 0, null);
    if (!deviceHandle || (deviceHandle == INVALID_HANDLE_VALUE))
    {
        return DS5W_E_DEVICE_REMOVED;
    }

    // Write to conext
    ptrContext._internal.connected = true;
    ptrContext._internal.connection = ptrEnumInfo._internal.connection;
    ptrContext._internal.deviceHandle = deviceHandle;
    //wcscpy_s(ptrContext._internal.devicePath.ptr, 260, ptrEnumInfo._internal.path.ptr);
    ptrContext._internal.devicePath[] = ptrEnumInfo._internal.path[];
    ptrContext.variant = ptrEnumInfo.variant; // Regular or Edge
    // Get input report length
    ushort reportLength = 0;
    if (ptrContext._internal.connection == DeviceConnection.BT)
    {
        // Start BT by reading feature report 5
        ubyte[64] fBuffer;
        fBuffer[0] = 0x05;
        if (!HidD_GetFeature(deviceHandle, fBuffer.ptr, 64))
        {
            return DS5W_E_BT_COM;
        }

        // The bluetooth input report is 78 Bytes long
        reportLength = 547;
    }
    else
    {
        // The usb input report is 64 Bytes long
        reportLength = 64;
    }

    // Return OK
    return DS5W_OK;
}

/// <summary>
/// Free the device conntext
/// </summary>
/// <param name="ptrContext">Pointer to context</param>
void freeDeviceContext(DeviceContext* ptrContext)
{
    // Check if handle is existing
    if (ptrContext._internal.deviceHandle)
    {
        // Send zero output report to disable all onging outputs
        DS5OutputState os;

        os.leftTriggerEffect.effectType = TriggerEffectType.NoResitance;
        os.rightTriggerEffect.effectType = TriggerEffectType.NoResitance;
        os.disableLeds = true;

        setDeviceOutputState(ptrContext, &os);

        // Close handle
        CloseHandle(ptrContext._internal.deviceHandle);
        ptrContext._internal.deviceHandle = null;
    }

    // Unset bool
    ptrContext._internal.connected = false;

    // Unset string
    ptrContext._internal.devicePath[0] = 0x0;
}

/// <summary>
/// Try to reconnect a removed device
/// </summary>
/// <param name="ptrContext">Context to reconnect on</param>
/// <returns>Result</returns>
DS5W_ReturnValue reconnectDevice(DeviceContext* ptrContext)
{
    // Check len
    if (wcslen(ptrContext._internal.devicePath.ptr) == 0)
    {
        return DS5W_E_INVALID_ARGS;
    }

    // Connect to device
    HANDLE deviceHandle = CreateFileW(ptrContext._internal.devicePath.ptr, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, null, OPEN_EXISTING, 0, null);
    if (!deviceHandle || (deviceHandle == INVALID_HANDLE_VALUE))
    {
        return DS5W_E_DEVICE_REMOVED;
    }

    // Write to conext
    ptrContext._internal.connected = true;
    ptrContext._internal.deviceHandle = deviceHandle;

    // Return ok
    return DS5W_OK;
}

/// <summary>
/// Get device input state
/// </summary>
/// <param name="ptrContext">Pointer to context</param>
/// <param name="ptrInputState">Pointer to input state</param>
/// <returns>Result of call</returns>
DS5W_ReturnValue getDeviceInputState(DeviceContext* ptrContext, DS5InputState* ptrInputState)
{
    // Check pointer
    if (!ptrContext || !ptrInputState)
    {
        return DS5W_E_INVALID_ARGS;
    }

    // Check for connection
    if (!ptrContext._internal.connected)
    {
        return DS5W_E_DEVICE_REMOVED;
    }

    // Get the most recent package
    HidD_FlushQueue(ptrContext._internal.deviceHandle);

    // Get input report length
    uint inputReportLength = 0;
    if (ptrContext._internal.connection == DeviceConnection.BT)
    {
        // The bluetooth input report is 78 Bytes long
        inputReportLength = 78;
        ptrContext._internal.hidBuffer[0] = 0x31;
    }
    else
    {
        // The usb input report is 64 Bytes long
        inputReportLength = 64;
        ptrContext._internal.hidBuffer[0] = 0x01;
    }

    // Get device input
    if (ReadFile(ptrContext._internal.deviceHandle, ptrContext._internal.hidBuffer.ptr, inputReportLength, NULL, NULL) == FALSE)
    {
        // Close handle and set error state
        CloseHandle(ptrContext._internal.deviceHandle);
        ptrContext._internal.deviceHandle = null;
        ptrContext._internal.connected = false;

        // Return error
        return DS5W_E_DEVICE_REMOVED;
    }

    // Evaluete input buffer
    if (ptrContext._internal.connection == DeviceConnection.BT)
    {
        // Call bluetooth evaluator if connection is qual to BT
        evaluateHidInputBuffer(&ptrContext._internal.hidBuffer[2], ptrInputState);
    }
    else
    {
        // Else it is USB so call its evaluator
        evaluateHidInputBuffer(&ptrContext._internal.hidBuffer[1], ptrInputState);
    }

    // Return ok
    return DS5W_OK;
}

/// <summary>
/// Set the device output state
/// </summary>
/// <param name="ptrContext">Pointer to context</param>
/// <param name="ptrOutputState">Pointer to output state to be set</param>
/// <returns>Result of call</returns>
DS5W_ReturnValue setDeviceOutputState(DeviceContext* ptrContext, DS5OutputState* ptrOutputState)
{
    // Check pointer
    if (!ptrContext || !ptrOutputState)
    {
        return DS5W_E_INVALID_ARGS;
    }

    // Check for connection
    if (!ptrContext._internal.connected)
    {
        return DS5W_E_DEVICE_REMOVED;
    }

    // Get otuput report length
    ushort outputReportLength = 0;
    if (ptrContext._internal.connection == DeviceConnection.BT)
    {
        // The bluetooth input report is 547 Bytes long
        outputReportLength = 547;
    }
    else
    {
        // The usb input report is 48 or 64 Bytes long for DS_REGULAR and DS_EDGE
        if (ptrContext.variant == DEVICE_VARIANT.DS_EDGE)
            outputReportLength = 64;
        else
            outputReportLength = 48;
    }

    // Cleat all input data
    ptrContext._internal.hidBuffer[0 .. outputReportLength] = 0;
    // Build output buffer
    if (ptrContext._internal.connection == DeviceConnection.BT)
    {
        //return DS5W_E_CURRENTLY_NOT_SUPPORTED;
        // Report type
        ptrContext._internal.hidBuffer[0x00] = 0x31;
        ptrContext._internal.hidBuffer[0x01] = 0x02;
        createHidOutputBuffer(&ptrContext._internal.hidBuffer[2], ptrOutputState);

        // Hash
        const crcChecksum = CRC32.compute(ptrContext._internal.hidBuffer.ptr, 74);

        ptrContext._internal.hidBuffer[0x4A] = cast(ubyte)(
            (crcChecksum & 0x000000FF) >> 0UL);
        ptrContext._internal.hidBuffer[0x4B] = cast(ubyte)(
            (crcChecksum & 0x0000FF00) >> 8UL);
        ptrContext._internal.hidBuffer[0x4C] = cast(ubyte)(
            (crcChecksum & 0x00FF0000) >> 16UL);
        ptrContext._internal.hidBuffer[0x4D] = cast(ubyte)(
            (crcChecksum & 0xFF000000) >> 24UL);

    }
    else
    {
        // Report type
        ptrContext._internal.hidBuffer[0x00] = 0x02;

        // Else it is USB so call its evaluator
        createHidOutputBuffer(&ptrContext._internal.hidBuffer[1], ptrOutputState);
    }

    // Write to controller
    if (!WriteFile(ptrContext._internal.deviceHandle, ptrContext._internal.hidBuffer.ptr, outputReportLength, NULL, NULL))
    {
        debug
        {
            import std.stdio : writeln;

            writeln(GetLastErrorAsString());
        }
        // Close handle and set error state
        CloseHandle(ptrContext._internal.deviceHandle);
        ptrContext._internal.deviceHandle = null;
        ptrContext._internal.connected = false;

        // Return error
        return DS5W_E_DEVICE_REMOVED;
    }

    // OK 
    return DS5W_OK;
}
