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
    var contentView: ContentView?;
    var charBuffer: [String] = [String](repeating: "", count: 0);
    var emojiDict: [String : String] = [:];
}

func unicodeToUTF16(str: String) -> String
{
    guard var num = UInt32(str, radix: 16) else {return "";}
    if (num > 0xDF77 && num < 0xE000) {return "";}
    if (num <= 0xDF77 || (num >= 0xE000 && num <= 0xFFFF)) {return str;}
    num -= 0x10000;
    let i1 : UInt32 = (54 << 10) + ((num >> 10)&1023);
    let i2: UInt32 = (55 << 10) + (num&1023);
    return String(i1, radix: 16) + "+" + String(i2, radix: 16);
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
    print(dir);
    do {
        let inputString = try String(contentsOf: dir, encoding: .utf8);
        let lines = inputString.components(separatedBy: .newlines);
        for i in 0..<lines.count
        {
            if (!lines[i].contains(":")) {continue;}
            let parts = lines[i].components(separatedBy: ":");
            let codestr = parts[0].trimmingCharacters(in: .whitespacesAndNewlines);
            let descr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines);
            UIApplication.shared.emojiDict[descr] = codestrToOutput(str: codestr);
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
    for i in 1..<UIApplication.shared.charBuffer.count - 1{sum += UIApplication.shared.charBuffer[i];}
    return UIApplication.shared.emojiDict[sum] ?? "";
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>?
{
    if (type != .keyDown) {return Unmanaged.passRetained(event);}
    var cnt = 0;
    var inputString = UniChar();
    event.keyboardGetUnicodeString(maxStringLength: 2, actualStringLength: &cnt, unicodeString: &inputString);
    if (cnt == 0) {return Unmanaged.passRetained(event);}
    
    let input : Character = Character(UnicodeScalar(inputString) ?? UnicodeScalar(0));
    if (input == Character(" ")) {UIApplication.shared.charBuffer.removeAll();}
    else if ((input == Character(":")) ^ !UIApplication.shared.charBuffer.isEmpty) {UIApplication.shared.charBuffer.append(String(input));}
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
    }
    return Unmanaged.passRetained(event);
}

extension Bool
{
    static func ^ (left: Bool, right: Bool) -> Bool {return left != right;}
}
