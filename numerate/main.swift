//
//  main.swift
//  numerate
//
//  Created by David Grigg on 26/10/17.
//  Copyright © 2017 Rightword Enterprises. All rights reserved.
//

import Foundation

struct Optional
{
    var Regexpression = "(\\d{1,10})"
    var Romanise = false
    var Lowercase = false
    var Increment = false
    var IncrementBy = 0
    var TargetResult = false
    var TargetResultNum = 0
    var ForceEnd = false
    var ForceEndAfter = 0
    var Output = false
    var OutputTo = ""
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

var pieces:[String] = []
var bulktext = ""

func decToRoman(dec: Int) -> String
{
    guard (dec > 0) else { return "!\(dec)!" }
    
    let units = ["","I","II","III","IV","V","VI","VII","VIII","IX"]
    let tens = ["","X","XX","XXX","XL","L","LX","LXX","LXXX","XC"]
    let hundreds = ["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM"]
    
    switch dec
    {
    case 0:
        return ""
    case 1..<10:
        return units[dec]
    case 10..<100:
        let u = dec % 10
        let t = Int(dec / 10)
        return tens[t] + units[u]
    case 100..<1000:
        let u = dec % 10
        let t = Int((dec - u)/10) % 10
        let h = Int((dec - u - t * 10) / 100)
        return hundreds[h] + tens[t] + units[u]
    default: //handles numbers above 1000
        let d = dec % 1000
        let u = d % 10
        let t = Int((d - u)/10) % 10
        let h = Int((d - u - t * 10) / 100)
        let m = Int(dec / 1000)
        var mstr = ""
        for _ in 1...m
        {
            mstr += "M"
        }
        return mstr + hundreds[h] + tens[t] + units[u]
    }
}

func substringBeforeRange(original:String, range:NSRange) -> String
{
    guard range.location > 1 else { return "" }
    
    let endIndex = original.index(original.startIndex, offsetBy: range.location - 1)
    return String(original[...endIndex])
}

func substringFromRange(original:String, range:NSRange) -> String
{
    let startIndex = original.index(original.startIndex, offsetBy: range.location)
    let endIndex = original.index(original.startIndex, offsetBy: range.location + range.length - 1)
    return String(original[startIndex...endIndex])
}

func substringAfterRange(original:String, range:NSRange) -> String
{
    guard (range.location  + range.length) <= original.count else { return "" }
    
    let startIndex = original.index(original.startIndex, offsetBy: range.location + range.length)
    return String(original[startIndex...])
}

func substringBetweenRanges(original:String, range1: NSRange, range2: NSRange) -> String
{
    guard ((range1.location < range2.location) && (range2.location >= (range1.location + range1.length))) else { return "" }
    
    let startIndex = original.index(original.startIndex, offsetBy: range1.location + range1.length)
    let endIndex = original.index(original.startIndex, offsetBy: range2.location - 1)
    return String(original[startIndex...endIndex])
}

func extractMatches(for regex: String, in text: String) -> [NSTextCheckingResult] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

func transform(_ changestr:String, options: Optional) -> String
{
    if let decnum = Int(changestr)
    {
        var retnum = decnum
        
        if options.Increment
        {
            retnum += options.IncrementBy //might be negative
        }
        
        //other possible transforms here if they pass current value to next

        //this has to be last transform
        if options.Romanise
        {
            return decToRoman(dec: retnum)
        }
        
        return "\(retnum)"
    }
    return changestr
}

func writeLineToFile(line:String, filename:String)
{
    do {
        let ddir = URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
        let url = ddir.appendingPathComponent(filename)
        try line.appendLineToURL(fileURL: url as URL)
    }
    catch {
        print("Could not write to file")
    }
}

func processFileWithOptions(filepath:String, options:Optional)
{
    var lines: [String] = []
    do
    {
        let wholetext = try String(contentsOfFile: filepath, encoding: String.Encoding.utf8)
        lines = wholetext.components(separatedBy: "\n")
    }
    catch let err as NSError {
        print(err.description)
    }
    
    let pattern = options.Regexpression
    var numFinds = 0
    
    for line in lines {
        
        if (options.ForceEnd && numFinds >= options.ForceEndAfter)
        {
            print(line)
            if (options.Output)
            {
                bulktext += line + "\n"
            }
            continue //skip to next line
        }
        
        let results = extractMatches(for: pattern,in: line)
        if results.count > 0 { numFinds += 1 }
        
        pieces.removeAll(keepingCapacity: false)
        
        //make an array of the ranges, for convenience
        var ranges: [NSRange] = []
        for result in results
        {
            ranges.append(result.range(at: 1))
        }
        
        if (options.TargetResult) && (options.TargetResultNum > 0)
        {
            if (options.TargetResultNum < ranges.count)
            {
                //just restrict ranges to the targeted item
                let temp = ranges[options.TargetResultNum - 1]
                ranges = [temp]
            }
            else
            {
                ranges = []
            }
        }
        
        switch ranges.count
        {
        case 0:
            pieces.append(line)
        case 1:
            pieces.append(substringBeforeRange(original: line, range: ranges[0]))
            pieces.append(transform(substringFromRange(original: line, range: ranges[0]), options: options))
            pieces.append(substringAfterRange(original: line, range: ranges[0]))
        default:
            pieces.append(substringBeforeRange(original: line, range: ranges[0]))
            
            for i in 0..<(ranges.count - 1)
            {
            pieces.append(transform(substringFromRange(original: line, range: ranges[i]), options: options))
            pieces.append(substringBetweenRanges(original: line, range1: ranges[i], range2: ranges[i + 1]))
            }
            
            pieces.append(transform(substringFromRange(original: line, range: ranges[ranges.count - 1]), options: options))
            pieces.append(substringAfterRange(original: line, range: ranges[ranges.count - 1]))
        }
        
        var mutatedLine = ""
        for piece in pieces
        {
            mutatedLine += piece
        }
        
        print(mutatedLine)
        
        if (options.Output)
        {
            bulktext += mutatedLine + "\n"
        }
    }
    if options.Output
    {
        do
        {
            try bulktext.write(toFile: options.OutputTo, atomically: true, encoding: String.Encoding.utf8)
        }
        catch
        {
            print("Unable to write to file")
        }
    }
}

func GetOptional(arguments:[String]) -> Optional
{
    var opts = Optional()
    var argnum = 2
    while argnum < args.count
    {
        if args[argnum].lowercased() == "-r"
        {
            opts.Romanise = true
        }
        
        if (argnum < args.count) && (args[argnum].lowercased() == "-a")
        {
            opts.Increment = true
            argnum += 1
            if (argnum < args.count)
            {
                if let dec = Int(args[argnum])
                {
                    opts.IncrementBy = dec
                }
            }
        }
        
        if (argnum < args.count) && (args[argnum].lowercased() == "-s")
        {
            opts.Increment = true
            argnum += 1
            if (argnum < args.count)
            {
                if let dec = Int(args[argnum])
                {
                    opts.IncrementBy = dec * -1
                }
            }
        }
        
        if (argnum < args.count) && (args[argnum].lowercased() == "-t")
        {
            argnum += 1
            if (argnum < args.count)
            {
                if let dec = Int(args[argnum])
                {
                    opts.TargetResult = true
                    opts.TargetResultNum = dec
                }
            }
        }
        
        if (argnum < args.count) && (args[argnum].lowercased() == "-e")
        {
            argnum += 1
            if (argnum < args.count)
            {
                if let dec = Int(args[argnum])
                {
                    opts.ForceEnd = true
                    opts.ForceEndAfter = dec
                }
            }
        }
        
        if (argnum < args.count) && (args[argnum].lowercased() == "-o")
        {
            opts.Output = true
            argnum += 1
            if (argnum < args.count)
            {
                opts.OutputTo = args[argnum]
            }
        }

        if (argnum < args.count) && (args[argnum].lowercased() == "-x")
        {
            argnum += 1
            if (argnum < args.count)
            {
                opts.Regexpression = args[argnum]
            }
        }
        
        argnum += 1
    } //end while
    return opts
}

let args = CommandLine.arguments

if args.count < 2
{
    print("Usage: filename [-r] [-a N] [-s N] [-t N] [-e N] [-o outfilename] [-x regex]")
    print(" Options: ")
    print(" -r: convert to Roman numerals ")
    print(" -a: add following integer number (N) ")
    print(" -s: subtract following integer number (N) ")
    print(" -t: target only Nth instance in each line")
    print(" -e: end transforms after Nth instance in file")
    print(" -o: send output to following filename")
    print(" -x: use the following regular expression")
    print ("    : must include capture group")
    print ("    : backslashes must be escaped ")
    print("     : eg \"<title>Chapter (\\\\d{1,3})</title>\"")
}
else
{
    //args[0] is the path to the executable
    
    let fileToProcess = args[1]
    
    let opts = GetOptional(arguments: args)

    processFileWithOptions(filepath: fileToProcess, options: opts)
}

