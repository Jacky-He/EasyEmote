//
//  ContentView.swift
//  EasyEmoteMacOS
//
//  Created by Jacky He on 2020-11-23.
//

import SwiftUI

struct SelectionView: View {
    @EnvironmentObject var emoteChoices: EmoteChoices;
//    var strs: [(String, String, String)] = [
//        ("kiss;medium_light_skin_tone", "D83D+DC8F+D83C+DFFC", "1F48F 1F3FC"),
//        ("kiss;medium_dark_skin_tone", "D83D+DC8F+D83C+DFFE", "1F48F 1F3FE"),
//        ("kiss;medium_skin_tone", "D83D+DC8F+D83C+DFFD", "1F48F 1F3FD"),
//        ("kiss;man_man", "D83D+DC68+200D+2764+200D+D83D+DC8B+200D+D83D+DC68", "1F468 200D 2764 200D 1F48B 200D 1F468"),
//        ("kiss;man_man_medium_dark_skin_tone", "D83D+DC68+D83C+DFFE+200D+2764+200D+D83D+DC8B+200D+D83D+DC68+D83C+DFFE", "1F468 1F3FE 200D 2764 200D 1F48B 200D 1F468 1F3FE"),
//        ("kiss;man_man_medium_dark_skin_tone_light_skin_tone", "D83D+DC68+D83C+DFFE+200D+2764+200D+D83D+DC8B+200D+D83D+DC68+D83C+DFFB", "1F468 1F3FE 200D 2764 200D 1F48B 200D 1F468 1F3FB")
//    ];
    
    func convertToEmoteStr(str: String) -> String
    {
        let characters = str.components(separatedBy: .whitespaces);
        var res:String = "";
        for each in characters
        {
            let i = UInt32(each, radix: 16);
            res += String(UnicodeScalar(i!)!);
        }
        return res;
    }
    
    var body: some View {
        VStack(alignment: .leading)
        {
            ForEach(emoteChoices.choices, id: \.0) { row in
                EmojiDescrRow(descrstr: row.0, emotestr: convertToEmoteStr(str: row.2));
            }
        }
        .frame(width: 600)
        .padding(10)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(lineWidth: 2)
                .foregroundColor(Color.gray.opacity(0.1))
        )
    }
}

struct EmojiDescrRow: View {
    @EnvironmentObject var emoteChoices: EmoteChoices;
    
    var descrstr: String;
    var emotestr: String;
    
    var body: some View {
        HStack
        {
            Text(emotestr).font(.system(size: 15));
            Text(":" + descrstr + ":").font(.custom("Chalkboard", size: 15))
            Spacer();
        }.padding([.top, .bottom], 5)
    }
}

struct SelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionView()
    }
}
