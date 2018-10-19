//
//  main.swift
//  IconMaker
//
//  Created by kekeke on 2018/10/03.
//  Copyright © 2018 kekeke. All rights reserved.
//

import Foundation
import Cocoa


func convertIcon(image:NSImage,size:NSSize,path:String) -> Bool {
    let convertImg = NSImage(size: size)
    image.size = size
    
    convertImg.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(at: NSPoint.zero, from: NSRect(origin: CGPoint.zero, size: size), operation: .copy, fraction: 1.0)
    convertImg.unlockFocus()
    
    guard let tiffData = convertImg.tiffRepresentation else {return false}
    guard let bitmap = NSBitmapImageRep(data: tiffData) else {return false}
    guard let imgData = bitmap.representation(using: .png, properties: [:]) else {
        return false
    }
    do {
        try imgData.write(to: URL(fileURLWithPath: path))
    }catch{
        return false
    }
    return true
}



//Icon size list

enum IdiomType {
    case iphone
    case ipad
    case iosMarketing
}

struct IconSet {
    let size: Double
    let idiom: IdiomType
    let scale: Double
}

let dict: [IconSet] = [
    IconSet(size: 20, idiom: .iphone, scale: 2),
    IconSet(size: 20, idiom: .iphone, scale: 3),
    IconSet(size: 29, idiom: .iphone, scale: 1),
    IconSet(size: 29, idiom: .iphone, scale: 2),
    IconSet(size: 29, idiom: .iphone, scale: 3),
    IconSet(size: 40, idiom: .iphone, scale: 2),
    IconSet(size: 40, idiom: .iphone, scale: 3),
    IconSet(size: 57, idiom: .iphone, scale: 1),
    IconSet(size: 57, idiom: .iphone, scale: 2),
    IconSet(size: 60, idiom: .iphone, scale: 2),
    IconSet(size: 60, idiom: .iphone, scale: 3),
    IconSet(size: 20, idiom: .ipad, scale: 1),
    IconSet(size: 20, idiom: .ipad, scale: 2),
    IconSet(size: 29, idiom: .ipad, scale: 1),
    IconSet(size: 29, idiom: .ipad, scale: 2),
    IconSet(size: 40, idiom: .ipad, scale: 1),
    IconSet(size: 40, idiom: .ipad, scale: 2),
    IconSet(size: 50, idiom: .ipad, scale: 1),
    IconSet(size: 50, idiom: .ipad, scale: 2),
    IconSet(size: 72, idiom: .ipad, scale: 1),
    IconSet(size: 72, idiom: .ipad, scale: 2),
    IconSet(size: 76, idiom: .ipad, scale: 1),
    IconSet(size: 76, idiom: .ipad, scale: 2),
    IconSet(size: 83.5, idiom: .ipad, scale: 2),
    IconSet(size: 1024, idiom: .iosMarketing, scale: 1)
]

let fm = FileManager.default

//Get and check arguments
var orgIconPath = ""
var exportPath = "AppIcon.appiconset"
if CommandLine.argc == 2 {
    orgIconPath = CommandLine.arguments[1]
} else if CommandLine.argc == 3 {
    orgIconPath = CommandLine.arguments[1]
    exportPath = CommandLine.arguments[2]
} else {
    print("Usage: \(CommandLine.arguments[0]) [IconFile] ([IconSetDirectory])")
    exit(1)
}


//Check orgIconPath exists, and exportPath doesn't exist.
guard fm.fileExists(atPath: orgIconPath) else {
    print("No such file: \(orgIconPath)")
    exit(1)
}
guard !fm.fileExists(atPath: exportPath) else {
    print("Already exists: \(exportPath)")
    exit(1)
}

//Load and check icon file
guard let orgIcon = NSImage(contentsOfFile: orgIconPath) else {
    print("Failed to load icon file: \(orgIconPath)")
    exit(1)
}
//Make icon directory
try fm.createDirectory(atPath: exportPath, withIntermediateDirectories: false, attributes: nil)

//Make icon files for required size
let nameswithoutext = URL(fileURLWithPath: orgIconPath).deletingPathExtension().absoluteString.split(separator: "/")
let namewithoutext = nameswithoutext[nameswithoutext.count-1]

for i in dict {
    var sizet = ""
    if Int(i.size * 10) % 10 == 5 {
        sizet = "\(i.size)"
    } else {
        sizet = "\(Int(i.size))"
    }
    guard convertIcon(image: orgIcon,
                size: NSSize(width: i.size*i.scale/2,height: i.size*i.scale/2),
                path: "\(exportPath)/\(namewithoutext)_\(sizet)pt@\(Int(i.scale)).png") else {
        print("Failed to convert")
        exit(1)
    }
}

//Make json file
var imglist:[Dictionary<String,String>] = []
for i in dict{
    var idiomt = ""
    if i.idiom == .iphone {
        idiomt = "iphone"
    } else if i.idiom == .ipad {
        idiomt = "ipad"
    } else if i.idiom == .iosMarketing {
        idiomt = "ios-marketing"
    }
    var sizet = ""
    if Int(i.size * 10) % 10 == 5 {
        sizet = "\(i.size)"
    } else {
        sizet = "\(Int(i.size))"
    }
    let imginfo = [
        "size": "\(sizet)x\(sizet)",
        "idiom": idiomt,
        "filename": "\(namewithoutext)_\(sizet)pt@\(Int(i.scale)).png",
        "scale": "\(Int(i.scale))x"
    ]
    imglist.append(imginfo)
}

//Prepare json data
let dat = [
    "images": imglist,
    "info": [
        "version": 1,
        "author": "xcode"
    ]
] as [String : Any]

do {
    let jsondat = try JSONSerialization.data(withJSONObject: dat, options: [.prettyPrinted])
    try jsondat.write(to: URL(fileURLWithPath: "\(exportPath)/Contents.json"))
} catch {
    print("Failed to write JSON file")
}
