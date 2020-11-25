//
//  UIApplication.swift
//  EasyEmoteMacOS
//
//  Created by Jacky He on 2020-11-23.
//

import Foundation
import Cocoa
import ApplicationServices
import Carbon

class UIApplication
{
    static let shared = UIApplication();
    var charBuffer: [String] = [String](repeating: "", count: 0);
    var emojiTree: Trie = Trie();
    var window: NSWindow?;
    var visible: Bool = false;
}

//class InputControl: NSControl, NSControlTextEditingDelegate
//{
//    static let shared = InputControl();
//    func controlTextDidBeginEditing(_ obj: Notification) {
//        print("something");
//    }
//}

func unicodeToUTF16(str: String) -> String
{
    guard var num = UInt32(str, radix: 16) else {return "";}
    if (num > 0xDF77 && num < 0xE000) {return "";}
    if (num <= 0xDF77 || (num >= 0xE000 && num <= 0xFFFF)) {return str.uppercased();}
    num -= 0x10000;
    let i1 : UInt32 = (54 << 10) + ((num >> 10)&1023);
    let i2: UInt32 = (55 << 10) + (num&1023);
    return (String(i1, radix: 16) + "+" + String(i2, radix: 16)).uppercased();
}

func codestrToOutput(str: String) -> String
{
    let codes = str.components(separatedBy: .whitespaces);
    var res = "";
    for i in 0..<codes.count
    {
        res += unicodeToUTF16(str: codes[i]);
        res += "+";
    }
    res.removeLast()
    return res;
}

func loadData()
{
    let dir = Bundle.main.url(forResource: "emojiStore", withExtension: "txt")!;
    do {
        let inputString = try String(contentsOf: dir, encoding: .utf8);
        let lines = inputString.components(separatedBy: .newlines);
        for i in 0..<lines.count
        {
            if (!lines[i].contains(":")) {continue;}
            let parts = lines[i].components(separatedBy: ":");
            let codestr = parts[0].trimmingCharacters(in: .whitespacesAndNewlines);
            let descr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines);
            UIApplication.shared.emojiTree.insert(word: ":"+descr+":", codestr: codestrToOutput(str: codestr), unicodestr: codestr);
        }
    }
    catch {print("error getting contents of file");}
}

func createStringForKey(keyCode: CGKeyCode) -> String?
{
    let maxNameLength = 4;
    var nameBuffer = [UniChar](repeating: 0, count: maxNameLength);
    var nameLength = 0;
    
    let modifierKeys = UInt32(alphaLock >> 8) & 0xFF // Caps Lock
    var deadKeys: UInt32 = 0;
    let keyboardType = UInt32(LMGetKbdType());
    
    let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
    guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else {print("Could not get keyboard layout data"); return nil}
    
    let layoutData = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data;
    
    let osStatus = layoutData.withUnsafeBytes {
        UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, keyCode, UInt16(kUCKeyActionDown), modifierKeys, keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask), &deadKeys, maxNameLength, &nameLength, &nameBuffer)
    };
    guard osStatus == noErr else {print("Code: 0x%04X Status: %+i", keyCode, osStatus); return nil;}
    return String(utf16CodeUnits: nameBuffer, count: nameLength);
}

func keyCodeForChar(c: Character) -> CGKeyCode?
{
    var dict : [String : CGKeyCode] = [:];
    for i in 0...127
    {
        guard let s = createStringForKey(keyCode: CGKeyCode(i)) else {continue;}
        dict[s] = CGKeyCode(i);
    }
    return dict[String(c)];
}

func backSpaceNTimes(n: UInt32)
{
    let src = CGEventSource(stateID: .privateState);
    let str = "\u{8}";
    let idx = str.index(str.startIndex, offsetBy: 0);
    guard let c = keyCodeForChar(c: str[idx]) else {return;}
    for _ in 0..<n
    {
        let event = CGEvent(keyboardEventSource: src, virtualKey: c, keyDown: true);
        let loc = CGEventTapLocation.cghidEventTap;
        event?.post(tap: loc);
    }
}

func sendStringOnAlt(str: String)
{
    let src = CGEventSource(stateID: .privateState);
    for i in 0..<str.count
    {
        let idx = str.index(str.startIndex, offsetBy: i);
        guard let c = keyCodeForChar(c: str[idx]) else {continue;}
        let event = CGEvent(keyboardEventSource: src, virtualKey: c, keyDown: true);
        event?.flags = [.maskShift, .maskAlternate];
        let loc = CGEventTapLocation.cghidEventTap;
        event?.post(tap: loc);
    }
}

func processBuffer() -> String
{
    var sum = "";
    for i in 0..<UIApplication.shared.charBuffer.count {sum += UIApplication.shared.charBuffer[i];}
    return UIApplication.shared.emojiTree.get_code_str(descr: sum) ?? "";
}

func processChoices()
{
    var sum = "";
    for i in 0..<UIApplication.shared.charBuffer.count {sum += UIApplication.shared.charBuffer[i];}
    EmoteChoices.shared.choices = UIApplication.shared.emojiTree.get_most_relevant(input: sum);
    if (EmoteChoices.shared.choices.count == 0) {EmoteChoices.shared.chosenIdx = 0;}
    else {EmoteChoices.shared.chosenIdx = max(min(EmoteChoices.shared.choices.count - 1, EmoteChoices.shared.chosenIdx), 0);}
}

func makeWindowVisible()
{
    var screenPos : NSPoint = NSEvent.mouseLocation;
    UIApplication.shared.window?.layoutIfNeeded();
//    screenPos.y += UIApplication.shared.window?.frame.height ?? 0;
    UIApplication.shared.window?.setFrameTopLeftPoint(screenPos)
    UIApplication.shared.window?.orderFrontRegardless();
    UIApplication.shared.visible = true;
}

func makeWindowInvisible()
{
    UIApplication.shared.window?.orderBack(nil);
    UIApplication.shared.window?.setIsVisible(false);
    UIApplication.shared.visible = false;
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>?
{
    if (type != .keyDown) {return Unmanaged.passRetained(event);}
    var cnt = 0;
    var inputString = UniChar();
    event.keyboardGetUnicodeString(maxStringLength: 2, actualStringLength: &cnt, unicodeString: &inputString);
    if (cnt == 0) {return Unmanaged.passRetained(event);}
    let keycode = event.getIntegerValueField(.keyboardEventKeycode);
//    let keyboardtype = event.getIntegerValueField(.keyboardEventKeyboardType);
    let input : Character = Character(UnicodeScalar(inputString) ?? UnicodeScalar(0));
    
    if (input == Character("\u{8}")) //BACKSPACE
    {
        if (!UIApplication.shared.charBuffer.isEmpty) {UIApplication.shared.charBuffer.removeLast();}
        processChoices();
        print(EmoteChoices.shared.choices);
        if (EmoteChoices.shared.choices.count > 0) {makeWindowVisible();}
        else{makeWindowInvisible();}
    }
    else if (keycode == 76 || keycode == 36)//RETURN/ENTER
    {
        if (EmoteChoices.shared.choices.count > 0)
        {
            backSpaceNTimes(n: UInt32(UIApplication.shared.charBuffer.count));
            //@assert 0 <= EmoteChoices.shared.chosenIdx < \length(EmoteChoices.shared.choices);
            sendStringOnAlt(str: EmoteChoices.shared.choices[EmoteChoices.shared.chosenIdx].1);
            event.type = .keyUp;
            UIApplication.shared.charBuffer.removeAll();
        }
    }
    else if (keycode == 126) //UP ARROW
    {
        let cnt = EmoteChoices.shared.choices.count;
        if (cnt > 0)
        {
            EmoteChoices.shared.chosenIdx = (EmoteChoices.shared.chosenIdx - 1 + cnt)%cnt;
        }
    }
    else if (keycode == 125) //DOWN ARROW
    {
        let cnt = EmoteChoices.shared.choices.count;
        if (cnt > 0)
        {
            EmoteChoices.shared.chosenIdx = (EmoteChoices.shared.chosenIdx + 1)%cnt;
        }
    }
    else if ((input == Character(":")) ^ !UIApplication.shared.charBuffer.isEmpty)
    {
        UIApplication.shared.charBuffer.append(String(input));
        processChoices();
        print(EmoteChoices.shared.choices);
        
        //make window appear
        if (EmoteChoices.shared.choices.count > 0){makeWindowVisible();}
        else{makeWindowInvisible();}
    }
    else if (input == Character(":") && !UIApplication.shared.charBuffer.isEmpty)
    {
        UIApplication.shared.charBuffer.append(String(input));
        let emoteStr = processBuffer();
        
        if (emoteStr != "")
        {
            backSpaceNTimes(n: UInt32(UIApplication.shared.charBuffer.count) - UInt32(1));
            sendStringOnAlt(str: emoteStr);
            event.type = .keyUp;
        }
        UIApplication.shared.charBuffer.removeAll();
        
        //make window disappear
        makeWindowInvisible()
    }
    return Unmanaged.passRetained(event);
}

extension Bool
{
    static func ^ (left: Bool, right: Bool) -> Bool {return left != right;}
}
