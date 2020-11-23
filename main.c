#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include "lib/vector.h"
#include "lib/salloc.h"

vector_t v;

CFStringRef createStringForKey(CGKeyCode keyCode)
{
    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardLayoutInputSource();
    CFDataRef layoutData =
        TISGetInputSourceProperty(currentKeyboard,
                                  kTISPropertyUnicodeKeyLayoutData);
    const UCKeyboardLayout *keyboardLayout =
        (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);

    UInt32 keysDown = 0;
    UniChar chars[4];
    UniCharCount realLength;

    UCKeyTranslate(keyboardLayout,
                   keyCode,
                   kUCKeyActionDisplay,
                   0,
                   LMGetKbdType(),
                   kUCKeyTranslateNoDeadKeysBit,
                   &keysDown,
                   sizeof(chars) / sizeof(chars[0]),
                   &realLength,
                   chars);
    CFRelease(currentKeyboard);

    return CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 1);
}

CGKeyCode keyCodeForChar(const char c)
{
    static CFMutableDictionaryRef charToCodeDict = NULL;
    uintptr_t code;
    UniChar character = c;
    CFStringRef charStr = NULL;

    /* Generate table of keycodes and characters. */
    if (charToCodeDict == NULL) {
        size_t i;
        charToCodeDict = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                   128,
                                                   &kCFCopyStringDictionaryKeyCallBacks,
                                                   NULL);
        if (charToCodeDict == NULL) return UINT16_MAX;

        /* Loop through every keycode (0 - 127) to find its current mapping. */
        for (i = 0; i < 128; ++i) {
            CFStringRef string = createStringForKey((CGKeyCode)i);
            if (string != NULL) {
                CFDictionaryAddValue(charToCodeDict, string, (const void *)i);
                CFRelease(string);
            }
        }
    }

    charStr = CFStringCreateWithCharacters(kCFAllocatorDefault, &character, 1);

    /* Our values may be NULL (0), so we need to use this function. */
    if (!CFDictionaryGetValueIfPresent(charToCodeDict, charStr,
                                       (const void **)&code)) {
        code = UINT16_MAX;
    }

    CFRelease(charStr);
    return (CGKeyCode)code;
}

char *unicodeToUTF16(uint32_t c)
{
    if (c > 0xDF77 && c < 0xE000) return NULL;
    if (c <= 0xDF77 || (c >= 0xE000 && c <= 0xFFFF))
    {
        char *res = smalloc(sizeof(char)*5);
        sprintf(res, "%04x", c);
        res[4] = 0;
        return res;
    }
    c -= 0x10000;
    uint32_t i1 = (54 << 10) + ((c >> 10)&1023);
    uint32_t i2 = (55 << 10) + (c&1023);
    char *res = smalloc(sizeof(char)*10);
    sprintf(res, "%04x+%04x", i1, i2);
    res[9] = 0;
    return res;
}


void sendStringOnAlt (char *str, size_t len)
{
    for (int i = 0; i < len; i++)
    {
        CGEventRef event = CGEventCreateKeyboardEvent(NULL, keyCodeForChar(str[i]), true);
        CGEventSetFlags(event, kCGEventFlagMaskShift | kCGEventFlagMaskAlternate);
        CGEventPost(kCGAnnotatedSessionEventTap, event);
        CFRelease(event);
    }
}

void backspaceNTimes(size_t n)
{
    for (int i = 0; i < n; i++)
    {
        CGEventRef event = CGEventCreateKeyboardEvent(NULL, keyCodeForChar('\b'), true);
        CGEventPost(kCGAnnotatedSessionEventTap, event);
        CFRelease (event);
    }
}

char *process_vector(vector_t vec)
{
    char *text = smalloc(vsize(vec) + 1);
    for (int i = 0; i < vsize(vec); i++) text[i] = velem_at(vec, i);
    text [vsize(vec)] = 0;
    printf("%s\n", text);
    return unicodeToUTF16(0x1F483);
}

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp)) return event;
    
    //The incoming keycode.
    
    UniCharCount cnt;
    UniChar *inputString = malloc(sizeof(UniChar)*2);
    CGEventKeyboardGetUnicodeString(event, 1, &cnt, inputString);
    if (cnt == 0) return event;
    if (type == kCGEventKeyUp) return event;
    
    if (inputString[0] == ' ') vclear(v);
    else if ((inputString[0] == ':') ^ !vempty(v)) vpush_back(v, inputString[0]);
    else if (inputString[0] == ':' && !vempty(v))
    {
        vpush_back(v, inputString[0]);
        char *emotestr = process_vector(v);
        if (emotestr != NULL)
        {
            
            backspaceNTimes(vsize(v) - 1);
            sendStringOnAlt(emotestr, strlen(emotestr));
            free(emotestr);
            CGEventSetType(event, kCGEventKeyUp);
        }
        vclear(v);
    }
//    if (inputString[0] == 'a')
//    {
//        sendStringOnAlt("d83d+dc83", 9, type);
//        CGEventSetType(event, kCGEventKeyUp);
//    }
//    free(inputString);

    //We must return the event for it to be useful.
    return event;
}

int main(void)
{
    CFMachPortRef eventTap;
    CGEventMask eventMask;
    CFRunLoopSourceRef runLoopSource;

    
    //Create an event tap. We are interested in key presses
    eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp));
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, myCGEventCallback, NULL);
    
    if (!eventTap)
    {
        fprintf(stderr, "failed to create event tap\n");
        exit(1);
    }
    //initialize vector
    v = v_new();
    
    //Create a run loop source
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    //Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    //Add to the current run loop.
    CGEventTapEnable(eventTap, true);
    
    //Set it all running.
    CFRunLoopRun();

    //In a real program, one would have arranged for cleaning up
    vfree(v);
    
    exit(0);
    
}

