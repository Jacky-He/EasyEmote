//
//  EmoteChoices.swift
//  EasyEmoteMacOS
//
//  Created by Jacky He on 2020-11-24.
//

import Foundation
import SwiftUI
import Combine

final class EmoteChoices: ObservableObject
{
    static let shared = EmoteChoices();
    @Published var choices : [(String, String, String)] = []; //first: string descr second: string code
}
