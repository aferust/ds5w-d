# DualSense on Windows [API]
![](https://raw.githubusercontent.com/Ohjurot/DualSense-Windows/main/Doc/GitHub_readme/header.png)



- Windows API for the PS5 DualSense controller. Ported from [the C++ codebase of Ludwig Füchsl](https://github.com/Ohjurot/DualSense-Windows/) to dlang, and published with his permission. This API will help you using the DualSense controller in your windows D Applications / Projects.
- DS5-Edge support has been added, unlike the original C++ repo.

## Features

- Reading all button input from the controller
- Reading the analog sticks and analog triggers
- Reading the two finger touch positions
- Reading the Accelerometer and Gyroscope
- Using the haptic feedback for default rumbleing 
- Controlling the adaptive triggers (3 Types of effects) and reading back the users force while active
- Controlling the RGB color of the lightbar
- Setting the player indication LEDs and the microphone LED

## Using the API

This is the minimal example on how to use the library:

```d
import std.stdio;
import core.stdc.string;

import ds5w;

int main()
{

    DeviceEnumInfo[16] infos;

    size_t controllersCount = 0;
    auto rv = enumDevices(infos[], &controllersCount);

    if (controllersCount == 0)
    {
        writeln("No DualSense controller found!");
        return -1;
    }

    switch (rv)
    {
    case DS5W_OK:
        // The buffer was not big enough. Ignore for now
    case DS5W_E_INSUFFICIENT_BUFFER:
        break;

        // Any other error will terminate the application
    default:
        // Insert your error handling
        return -1;
    }

    // Check number of controllers
    if (!controllersCount)
    {
        return -1;
    }

    // Context for controller
    DeviceContext con;

    // Init controller and close application is failed
    if (DS5W_FAILED(initDeviceContext(&infos[0], &con)))
    {
        return -1;
    }

    // Main loop
    while (true)
    {
        // Input state
        DS5InputState inState;

        DS5W_ReturnValue retVal;
        retVal = getDeviceInputState(&con, &inState);
        // Retrieve data
        if (retVal == DS5W_ReturnValue.OK)
        {
            // Check for the Logo button
            if (inState.buttonsB & DS5W_ISTATE_BTN_B_PLAYSTATION_LOGO)
            {
                // Break from while loop
                break;
            }

            writefln("Left: x = %d, y = %d", inState.leftStick.x, inState.leftStick.y);

            DS5OutputState outState;

            // Set output data
            outState.leftRumble = inState.leftTrigger;
            outState.rightRumble = inState.rightTrigger;

            if (inState.leftTrigger > 20)
                outState.lightbar = Color(255, 0, 0);

            // Send output to the controller
            setDeviceOutputState(&con, &outState);
        }
        else
        {
            reconnectDevice(&con);
        }
    }

    // Shutdown context
    freeDeviceContext(&con);

    // Return zero
    return 0;
}
```
## For docs and further referencing
- refer to the test folder
- visit [the original C++ repo](https://github.com/Ohjurot/DualSense-Windows/)