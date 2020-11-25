//
//  ContentView.swift
//  EasyEmoteMacOS
//
//  Created by Jacky He on 2020-11-23.
//

import SwiftUI

struct SelectionView: View {
    @EnvironmentObject var emoteChoices: EmoteChoices;
    
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
        if (emoteChoices.choices.count > 0 && emoteChoices.choices[emoteChoices.chosenIdx].0 == descrstr)
        {
            HStack
            {
                Text(emotestr).font(.system(size: 15));
                Text(descrstr).font(.custom("Chalkboard", size: 15))
                Spacer();
            }.padding([.top, .bottom], 5)
            .padding([.leading, .trailing], 10)
            .background(Color.gray.opacity(0.5))
        }
        else
        {
            HStack
            {
                Text(emotestr).font(.system(size: 15));
                Text(descrstr).font(.custom("Chalkboard", size: 15))
                Spacer();
            }.padding([.top, .bottom], 5)
            .padding([.leading, .trailing], 10)
        }
    }
}

struct SelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionView()
    }
}
