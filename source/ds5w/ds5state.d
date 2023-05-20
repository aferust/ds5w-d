/*
	DS5State.h is part of DualSenseWindows
	https://github.com/Ohjurot/DualSense-Windows

	Contributors of this file:
	11.2020 Ludwig Füchsl

	Licensed under the MIT License (To be found in repository root directory)
*/
module ds5w.ds5state;

enum DS5W_ISTATE_BTX_SQUARE = 0x10;
enum DS5W_ISTATE_BTX_CROSS = 0x20;
enum DS5W_ISTATE_BTX_CIRCLE = 0x40;
enum DS5W_ISTATE_BTX_TRIANGLE = 0x80;
enum DS5W_ISTATE_DPAD_LEFT = 0x01;
enum DS5W_ISTATE_DPAD_DOWN = 0x02;
enum DS5W_ISTATE_DPAD_RIGHT = 0x04;
enum DS5W_ISTATE_DPAD_UP = 0x08;

enum DS5W_ISTATE_BTN_A_LEFT_BUMPER = 0x01;
enum DS5W_ISTATE_BTN_A_RIGHT_BUMPER = 0x02;
enum DS5W_ISTATE_BTN_A_LEFT_TRIGGER = 0x04;
enum DS5W_ISTATE_BTN_A_RIGHT_TRIGGER = 0x08;
enum DS5W_ISTATE_BTN_A_SELECT = 0x10;
enum DS5W_ISTATE_BTN_A_MENU = 0x20;
enum DS5W_ISTATE_BTN_A_LEFT_STICK = 0x40;
enum DS5W_ISTATE_BTN_A_RIGHT_STICK = 0x80;

enum DS5W_ISTATE_BTN_B_PLAYSTATION_LOGO = 0x01;
enum DS5W_ISTATE_BTN_B_PAD_BUTTON = 0x02;
enum DS5W_ISTATE_BTN_B_MIC_BUTTON = 0x04;

enum DS5W_OSTATE_PLAYER_LED_LEFT = 0x01;
enum DS5W_OSTATE_PLAYER_LED_MIDDLE_LEFT = 0x02;
enum DS5W_OSTATE_PLAYER_LED_MIDDLE = 0x04;
enum DS5W_OSTATE_PLAYER_LED_MIDDLE_RIGHT = 0x08;
enum DS5W_OSTATE_PLAYER_LED_RIGHT = 0x10;

/// <summary>
/// Analog stick
/// </summary>
struct AnalogStick
{
    /// <summary>
    /// X Position of stick (0 = Center)
    /// </summary>
    byte x;

    /// <summary>
    /// Y Posistion of stick (0 = Center)
    /// </summary>
    byte y;
}

/// <summary>
/// 3 Component vector
/// </summary>
struct Vec3
{
    short x;
    short y;
    short z;
}

alias Vector3 = Vec3;

/// <summary>
/// RGB Color
/// </summary>
struct Color
{
    ubyte r;
    ubyte g;
    ubyte b;
}

/// <summary>
/// Touchpad state
/// </summary>
struct Touch
{
    /// <summary>
    /// X positon of finger (~ 0 - 2000)
    /// </summary>
    uint x;

    /// <summary>
    /// Y position of finger (~ 0 - 2048)
    /// </summary>
    uint y;

    /// <summary>
    /// Touch is down
    /// </summary>
    bool down;

    /// <summary>
    /// 7-bit ID for touch
    /// </summary>
    ubyte id;
}

struct Battery
{
    /// <summary>
    /// Charching state of the battery
    /// </summary>
    bool chargin;

    /// <summary>
    /// Indicates that the battery is fully charged
    /// </summary>
    bool fullyCharged;

    /// <summary>
    /// Battery charge level 0x0 to 
    /// </summary>
    ubyte level;
}

/// <summary>
/// State of the mic led
/// </summary>
enum MicLed : ubyte
{
    /// <summary>
    /// Lef is off
    /// </summary>
    OFF = 0x00,

    /// <summary>
    /// Led is on
    /// </summary>
    ON = 0x01,

    /// <summary>
    /// Led is pulsing
    /// </summary>
    PULSE = 0x02,
}

/// <summary>
/// Type of trigger effect
/// </summary>
enum TriggerEffectType : ubyte
{
    /// <summary>
    /// No resistance is applied
    /// </summary>
    NoResitance = 0x00,

    /// <summary>
    /// Continuous Resitance is applied
    /// </summary>
    ContinuousResitance = 0x01,

    /// <summary>
    /// Seciton resistance is appleyed
    /// </summary>
    SectionResitance = 0x02,

    /// <summary>
    /// Extended trigger effect
    /// </summary>
    EffectEx = 0x26,

    /// <summary>
    /// Calibrate triggers
    /// </summary>
    Calibrate = 0xFC,
}

/// <summary>
/// Trigger effect
/// </summary>
struct TriggerEffect
{
    /// <summary>
    /// Trigger effect type
    /// </summary>
    TriggerEffectType effectType;

    /// <summary>
    /// Union for effect parameters
    /// </summary>
    union
    {
        /// <summary>
        /// Union one raw data
        /// </summary>
        ubyte[6] _u1_raw;

        /// <summary>
        /// For type == ContinuousResitance
        /// </summary>
        struct TContinuous
        {
            /// <summary>
            /// Start position of resistance
            /// </summary>
            ubyte startPosition;

            /// <summary>
            /// Force of resistance
            /// </summary>
            ubyte force;

            /// <summary>
            /// PAD / UNUSED
            /// </summary>
            ubyte[4] _pad;
        }

        TContinuous Continuous;

        /// <summary>
        /// For type == SectionResitance
        /// </summary>
        struct TSection
        {
            /// <summary>
            /// Start position of resistance
            /// </summary>
            ubyte startPosition;

            /// <summary>
            /// End position of resistance (>= start)
            /// </summary>
            ubyte endPosition;

            /// <summary>
            /// PAD / UNUSED
            /// </summary>
            ubyte[4] _pad;
        }

        TSection Section;
        /// <summary>
        /// For type == EffectEx
        /// </summary>
        struct TEffectEx
        {
            /// <summary>
            /// Position at witch the effect starts
            /// </summary>
            ubyte startPosition;

            /// <summary>
            /// Wher the effect should keep playing when trigger goes beyond 255
            /// </summary>
            bool keepEffect;

            /// <summary>
            /// Force applied when trigger >= (255 / 2)
            /// </summary>
            ubyte beginForce;

            /// <summary>
            /// Force applied when trigger <= (255 / 2)
            /// </summary>
            ubyte middleForce;

            /// <summary>
            /// Force applied when trigger is beyond 255
            /// </summary>
            ubyte endForce;

            /// <summary>
            /// Vibration frequency of the trigger
            /// </summary>
            ubyte frequency;
        }

        TEffectEx EffectEx;

    }
}

/// <summary>
/// Led brightness
/// </summary>
enum LedBrightness : ubyte
{
    /// <summary>
    /// Low led brightness
    /// </summary>
    LOW = 0x02,

    /// <summary>
    /// Medium led brightness
    /// </summary>
    MEDIUM = 0x01,

    /// <summary>
    /// High led brightness
    /// </summary>
    HIGH = 0x00,
}

/// <summary>
/// Player leds values
/// </summary>
struct PlayerLeds
{
    /// <summary>
    /// Player indication leds bitflag (You may used them for other features) DS5W_OSTATE_PLAYER_LED_???
    /// </summary>
    ubyte bitmask;

    /// <summary>
    /// Indicates weather the player leds should fade in
    /// </summary>
    bool playerLedFade;

    /// <summary>
    /// Brightness of the player leds
    /// </summary>
    LedBrightness brightness;
}

/// <summary>
/// Input state of the controler
/// </summary>
struct DS5InputState
{
    /// <summary>
    /// Position of left stick
    /// </summary>
    AnalogStick leftStick;

    /// <summary>
    /// Posisiton of right stick
    /// </summary>
    AnalogStick rightStick;

    /// <summary>
    /// Left trigger position
    /// </summary>
    ubyte leftTrigger;

    /// <summary>
    /// Right trigger position
    /// </summary>
    ubyte rightTrigger;

    /// <summary>
    /// Buttons and dpad bitmask DS5W_ISTATE_BTX_?? and DS5W_ISTATE_DPAD_?? indices check with if(buttonsAndDpad & DS5W_ISTATE_DPAD_??)...
    /// </summary>
    ubyte buttonsAndDpad;

    /// <summary>
    /// Button bitmask A (DS5W_ISTATE_BTN_A_??)
    /// </summary>
    ubyte buttonsA;

    /// <summary>
    /// Button bitmask B (DS5W_ISTATE_BTN_B_??)
    /// </summary>
    ubyte buttonsB;

    /// <summary>
    /// Accelerometer
    /// </summary>
    Vector3 accelerometer;

    /// <summary>
    /// Gyroscope  (Currently only raw values will be dispayed! Probably needs calibration (Will be done within the lib in the future))
    /// </summary>
    Vector3 gyroscope;

    /// <summary>
    /// First touch point
    /// </summary>
    Touch touchPoint1;

    /// <summary>
    /// Second touch point
    /// </summary>
    Touch touchPoint2;

    /// <summary>
    /// Battery information
    /// </summary>
    Battery battery;

    /// <summary>
    /// Indicates the connection of headphone
    /// </summary>
    bool headPhoneConnected;

    /// <summary>
    /// EXPERIMAENTAL: Feedback of the left adaptive trigger (only when trigger effect is active)
    /// </summary>
    ubyte leftTriggerFeedback;

    /// <summary>
    /// EXPERIMAENTAL: Feedback of the right adaptive trigger (only when trigger effect is active)
    /// </summary>
    ubyte rightTriggerFeedback;
}

struct DS5OutputState
{
    /// <summary>
    /// Left / Hard rumbel motor
    /// </summary>
    ubyte leftRumble;

    /// <summary>
    /// Right / Soft rumbel motor
    /// </summary>
    ubyte rightRumble;

    /// <summary>
    /// State of the microphone led
    /// </summary>
    MicLed microphoneLed;

    /// <summary>
    /// Diables all leds
    /// </summary>
    bool disableLeds;

    /// <summary>
    /// Player leds
    /// </summary>
    PlayerLeds playerLeds;

    /// <summary>
    /// Color of the lightbar
    /// </summary>
    Color lightbar;

    /// <summary>
    /// Effect of left trigger
    /// </summary>
    TriggerEffect leftTriggerEffect;

    /// <summary>
    /// Effect of right trigger
    /// </summary>
    TriggerEffect rightTriggerEffect;

}
