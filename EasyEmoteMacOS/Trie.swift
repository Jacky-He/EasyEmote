//
//  Trie.swift
//  EasyEmoteMacOS
//
//  Created by Jacky He on 2020-11-24.
//

import Foundation

class TrieNode<T:Hashable>
{
    var value: T?;
    weak var parent: TrieNode?;
    var children: [T: TrieNode] = [:];
    var codestr: String = "";
    var unicodestr: String = "";
    var cnt:Int = 0;
    var isTerminating : Bool = false;
    
    init(value: T? = nil, parent: TrieNode? = nil)
    {
        self.value = value;
        self.parent = parent;
    }
    
    func add(child: T)
    {
        guard children[child] == nil else {return;}
        children[child] = TrieNode(value: child, parent: self);
    }
}

class Trie
{
    fileprivate let root: TrieNode <Character>
    typealias Node = TrieNode<Character>
    
    init()
    {
        root = Node();
    }
}

extension Trie
{
    func insert(word: String, codestr: String, unicodestr: String)
    {
        guard !word.isEmpty else {return;}
        if (contains(word: word)) {return;}
        var curr = root;
        let characters = Array(word);
        curr.cnt += 1;
        for i in 0..<characters.count
        {
            let char = characters[i];
            if let child = curr.children[char]{curr = child;}
            else
            {
                curr.add(child: char);
                curr = curr.children[char]!;
            }
            curr.cnt += 1;
        }
        curr.isTerminating = true;
        curr.codestr = codestr;
        curr.unicodestr = unicodestr;
    }
    
    func contains(word: String) -> Bool
    {
        guard !word.isEmpty else {return false;}
        var curr = root;
        let characters = Array(word);
        var idx = 0;
        while idx < characters.count, let child = curr.children[characters[idx]]
        {
            idx += 1;
            curr = child;
        }
        return idx == characters.count && curr.isTerminating;
    }
    
    func get_code_str(descr: String) -> String?
    {
        guard !descr.isEmpty else {return nil;}
        var curr = root;
        let characters = Array(descr);
        var idx = 0;
        while idx < characters.count, let child = curr.children[characters[idx]]
        {
            idx += 1;
            curr = child;
        }
        if (idx == characters.count && curr.isTerminating) {return curr.codestr;}
        return nil;
    }
    
    func get_unicode_str(descr: String) -> String?
    {
        guard !descr.isEmpty else {return nil;}
        var curr = root;
        let characters = Array(descr);
        var idx = 0;
        while idx < characters.count, let child = curr.children[characters[idx]]
        {
            idx += 1;
            curr = child;
        }
        if (idx == characters.count && curr.isTerminating) {return curr.unicodestr;}
        return nil;
    }
    
    private func shortest_five (node: Node) -> [(String, String, String)]
    {
        return []; //bogus
    }
    
    
    private func recurse(node: Node, num: Int) -> [(String, String, String)]
    {
        //@requires num > 0;
        var remain = num;
        var res: [(String, String, String)] = [];
        if (node.isTerminating)
        {
            remain -= 1;
            res.append(("", node.codestr, node.unicodestr));
        }
        for (_ , value) in node.children
        {
            if (remain <= 0) {break;}
            let sub = min(remain, value.cnt);
            res.append(contentsOf: recurse(node: value, num: sub));
            remain -= sub;
        }
        for i in 0..<res.count
        {
            res[i].0 = String(node.value!) + res[i].0;
        }
        return res;
    }
    
    private func random_n(node: Node, maxlength: Int) -> [(String, String, String)]
    {
        return recurse(node: node, num: maxlength);
    }
    
    func get_most_relevant(input: String) -> [(String, String, String)] //first: emojidescr, second: code str, third: unicode str
    {
        guard !input.isEmpty else {return [];}
        var curr = root;
        let characters = Array(input);
        var idx = 0;
        while idx < characters.count, let child = curr.children[characters[idx]]
        {
            idx += 1;
            curr = child;
        }
        if (idx < characters.count) {return [];}
        var temp = random_n(node: curr, maxlength: 10);
        var inputcopy = input;
        inputcopy.removeLast();
        for i in 0..<temp.count {temp[i].0 = inputcopy + temp[i].0;}
        return temp;
    }
}
