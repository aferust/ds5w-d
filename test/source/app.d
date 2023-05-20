module app;

import std.stdio;
import std.algorithm : max;

import core.stdc.stdlib : system;

import ds5w;

int main()
{
    writeln("DualSense Controller Windows Test\n========================\n");

    DeviceEnumInfo[16] infos;

    size_t controllersCount = 0;
    auto rv = enumDevices(infos[], &controllersCount);

    if (controllersCount == 0)
    {
        writeln("No DualSense controller found!");
        system("pause");
        return -1;
    }

    // Print all controller
    writeln("Found ", controllersCount, " DualSense Controller(s):");

    foreach (i; 0 .. controllersCount)
    {
        if (infos[i]._internal.connection == DeviceConnection.BT)
        {
            "Wireless (Bluetooth) controller (".writeln;
        }
        else
        {
            "Wired (USB) controller (".writeln;
        }

        writeln(infos[i]._internal.path ~ ")");
    }

    DeviceContext con;
    if (DS5W_SUCCESS(initDeviceContext(&infos[0], &con)))
    {
        "DualSense controller connected".writeln;

        // Title
        writeln("DS5 (");
        if (con._internal.connection == DeviceConnection.BT)
        {
            "BT".writeln;
        }
        else
        {
            "USB".writeln;
        }
        ") Press L1 and R1 to exit".writeln;

        // State object
        DS5InputState inState;
        DS5OutputState outState;

        // Color intentsity
        float intensity = 1.0f;
        ushort lrmbl = 0;
        ushort rrmbl = 0;

        // Force
        TriggerEffectType rType = TriggerEffectType.NoResitance;

        int btMul = con._internal.connection == DeviceConnection.BT ? 10 : 1;

        // Application infinity loop
        while (!(inState.buttonsA & DS5W_ISTATE_BTN_A_LEFT_BUMPER && inState
                .buttonsA & DS5W_ISTATE_BTN_A_RIGHT_BUMPER))
        {
            // Get input state
            if (DS5W_SUCCESS(getDeviceInputState(&con, &inState)))
            {
                // === Read Input ===
                // Build all universal buttons (USB and BT) as text
                " === Universal input ===".writeln;

                writeln("Left Stick\tX: ", inState.leftStick.x, "\tY: ", inState.leftStick.y, (
                        inState.buttonsA & DS5W_ISTATE_BTN_A_LEFT_STICK ? "\tPUSH" : ""));
                writeln("Right Stick\tX: ", inState.rightStick.x, "\tY: ", inState.rightStick.y, (
                        inState.buttonsA & DS5W_ISTATE_BTN_A_RIGHT_STICK ? "\tPUSH" : ""));
                writeln("");

                writeln("Left Trigger:  ", inState.leftTrigger, "\tBinary active: ",
                    (inState.buttonsA & DS5W_ISTATE_BTN_A_LEFT_TRIGGER ? "Yes" : "No"), (
                        inState.buttonsA & DS5W_ISTATE_BTN_A_LEFT_BUMPER ? "\tBUMPER" : ""));
                writeln("Right Trigger: ", inState.rightTrigger, "\tBinary active: ",
                    (inState.buttonsA & DS5W_ISTATE_BTN_A_RIGHT_TRIGGER ? "Yes" : "No"), (
                        inState.buttonsA & DS5W_ISTATE_BTN_A_RIGHT_BUMPER ? "\tBUMPER" : ""));
                writeln("");

                writeln("DPAD: ", (inState.buttonsAndDpad & DS5W_ISTATE_DPAD_LEFT ? "L " : "  "), (
                        inState.buttonsAndDpad & DS5W_ISTATE_DPAD_UP ? "U " : "  "),
                    (inState.buttonsAndDpad & DS5W_ISTATE_DPAD_DOWN ? "D " : "  "), (
                        inState.buttonsAndDpad & DS5W_ISTATE_DPAD_RIGHT ? "R " : "  "), "\tButtons: ", (inState.buttonsAndDpad & DS5W_ISTATE_BTX_SQUARE ? "S " : "  "), (
                        inState.buttonsAndDpad & DS5W_ISTATE_BTX_CROSS ? "X " : "  "),
                    (inState.buttonsAndDpad & DS5W_ISTATE_BTX_CIRCLE ? "O " : "  "), (
                        inState.buttonsAndDpad & DS5W_ISTATE_BTX_TRIANGLE ? "T " : "  "));
                writeln((inState.buttonsA & DS5W_ISTATE_BTN_A_MENU ? "MENU" : ""), (
                        inState.buttonsA & DS5W_ISTATE_BTN_A_SELECT ? "\tSELECT" : ""));

                writeln("Trigger Feedback:\tLeft: ", cast(int) inState.leftTriggerFeedback, "\tRight: ", cast(
                        int) inState.rightTriggerFeedback);

                writeln("Touchpad", (inState.buttonsB & DS5W_ISTATE_BTN_B_PAD_BUTTON ? " (pushed):"
                        : ":"));

                writeln("Finger 1\tX: ", inState.touchPoint1.x, "\t Y: ", inState.touchPoint1.y);
                writeln("Finger 2\tX: ", inState.touchPoint2.x, "\t Y: ", inState.touchPoint2.y);
                writeln("");
                writeln("Battery: ", inState.battery.level, (inState.battery.chargin ? " Charging"
                        : ""), (inState.battery.fullyCharged ? "  Fully charged" : ""));
                writeln("");
                writeln((inState.buttonsB & DS5W_ISTATE_BTN_B_PLAYSTATION_LOGO ? "PLAYSTATION" : ""), (
                        inState.buttonsB & DS5W_ISTATE_BTN_B_MIC_BUTTON ? "\tMIC" : ""));

                // Ommited accel and gyro

                // === Write Output ===
                // Rumbel
                lrmbl = cast(ushort) max(lrmbl - 0x200 / btMul, 0);
                rrmbl = cast(ushort) max(rrmbl - 0x100 / btMul, 0);

                outState.leftRumble = (lrmbl & 0xFF00) >> 8UL;
                outState.rightRumble = (rrmbl & 0xFF00) >> 8UL;

                // Lightbar
                outState.lightbar = color_R8G8B8_UCHAR_A32_FLOAT(255, 0, 0, intensity);
                intensity -= 0.0025f / btMul;
                if (intensity <= 0.0f)
                {
                    intensity = 1.0f;

                    lrmbl = 0xFF00;
                    rrmbl = 0xFF00;
                }

                // Player led
                if (outState.rightRumble)
                {
                    outState.playerLeds.playerLedFade = true;
                    outState.playerLeds.bitmask = DS5W_OSTATE_PLAYER_LED_MIDDLE;
                    outState.playerLeds.brightness = LedBrightness.HIGH;
                }
                else
                {
                    outState.playerLeds.bitmask = 0;
                }

                // Set force
                if (inState.rightTrigger == 0xFF)
                {
                    rType = TriggerEffectType.ContinuousResitance;
                }
                else if (inState.rightTrigger == 0x00)
                {
                    rType = TriggerEffectType.NoResitance;
                }

                // Mic led
                if (inState.buttonsB & DS5W_ISTATE_BTN_B_MIC_BUTTON)
                {
                    outState.microphoneLed = MicLed.ON;
                }
                else if (inState.buttonsB & DS5W_ISTATE_BTN_B_PLAYSTATION_LOGO)
                {
                    outState.microphoneLed = MicLed.OFF;
                }

                // Left trigger is clicky / section
                outState.leftTriggerEffect.effectType = TriggerEffectType.SectionResitance;
                outState.leftTriggerEffect.Section.startPosition = 0x00;
                outState.leftTriggerEffect.Section.endPosition = 0x60;

                // Right trigger is forcy
                outState.rightTriggerEffect.effectType = rType;
                outState.rightTriggerEffect.Continuous.force = 0xFF;
                outState.rightTriggerEffect.Continuous.startPosition = 0x00;

                setDeviceOutputState(&con, &outState);
            }
            else
            {
                // Device disconnected show error and try to reconnect
                writeln("Device removed!");
                reconnectDevice(&con);
            }
        }

        // Free state
        freeDeviceContext(&con);
    }
    else
    {
        writeln("Failed to connect to controller!");
        system("pause");
        return -1;
    }
    return 0;
}
