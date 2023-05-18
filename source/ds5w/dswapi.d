/*
	DSW_Api.h is part of DualSenseWindows
	https://github.com/Ohjurot/DualSense-Windows

	Contributors of this file:
	11.2020 Ludwig Füchsl

	Licensed under the MIT License (To be found in repository root directory)
*/
module ds5w.dswapi;

bool DS5W_SUCCESS(BOOL)(BOOL expr)
{
    return expr == DS5W_ReturnValue.OK;
}

bool DS5W_FAILED(BOOL)(BOOL expr)
{
    return expr != DS5W_ReturnValue.OK;
}

enum DS5W_OK = DS5W_ReturnValue.OK;
enum DS5W_E_UNKNOWN = DS5W_ReturnValue.E_UNKNOWN;
enum DS5W_E_INSUFFICIENT_BUFFER = DS5W_ReturnValue.E_INSUFFICIENT_BUFFER;
enum DS5W_E_EXTERNAL_WINAPI = DS5W_ReturnValue.E_EXTERNAL_WINAPI;
enum DS5W_E_STACK_OVERFLOW = DS5W_ReturnValue.E_STACK_OVERFLOW;
enum DS5W_E_INVALID_ARGS = DS5W_ReturnValue.E_INVALID_ARGS;
enum DS5W_E_CURRENTLY_NOT_SUPPORTED = DS5W_ReturnValue.E_CURRENTLY_NOT_SUPPORTED;
enum DS5W_E_DEVICE_REMOVED = DS5W_ReturnValue.E_DEVICE_REMOVED;
enum DS5W_E_BT_COM = DS5W_ReturnValue.E_BT_COM;

/// <summary>
/// Enum for return values
/// </summary>
enum DS5W_ReturnValue : uint
{
    /// <summary>
    /// Operation completed without an error
    /// </summary>
    OK = 0,

    /// <summary>
    /// Operation encountered an unknown error
    /// </summary>
    E_UNKNOWN = 1,

    /// <summary>
    /// The user supplied buffer is to small
    /// </summary>
    E_INSUFFICIENT_BUFFER = 2,

    /// <summary>
    /// External unexpected winapi error (please report as issue if you get this error!)
    /// </summary>
    E_EXTERNAL_WINAPI = 3,

    /// <summary>
    /// Not enought memroy on the stack
    /// </summary>
    E_STACK_OVERFLOW = 4,

    /// <summary>
    /// Invalid arguments
    /// </summary>
    E_INVALID_ARGS = 5,

    /// <summary>
    /// This feature is currently not supported
    /// </summary>
    E_CURRENTLY_NOT_SUPPORTED = 6,

    /// <summary>
    /// Device was disconnected
    /// </summary>
    E_DEVICE_REMOVED = 7,

    /// <summary>
    /// Bluetooth communication error
    /// </summary>
    E_BT_COM = 8,

}

alias DS5W_RV = DS5W_ReturnValue;
