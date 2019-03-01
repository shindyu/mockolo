
//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SourceKittenFramework

let MockAnnotation = "@CreateMock"
let MockTypeString = "protocol"
let StaticKindString = "static"
let ImportString = "import "
let PoundIfMock = "#if MOCK"
let PoundEndIf = "#endif"
let HeaderDoc = """
//  Copyright © Uber Technologies, Inc. All rights reserved.
//
//  @generated by SwiftMockGen
//  swiftlint:disable custom_rules

"""

extension File {
    func lines(starting keyword: String) -> [String] {
        let imports = lines.filter { (line: Line) -> Bool in
            return line.content.trimmingCharacters(in: CharacterSet.whitespaces).starts(with: keyword)
            }.map { (line: Line) -> String in
                return line.content
        }
        return imports
    }
}

extension String {
    func capitlizeFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    func shouldParse(with exclusionList: [String]? = nil) -> Bool {
        guard hasSuffix(".swift") else { return false }
        if let filtered = exclusionList?.filter ({
            return components(separatedBy: ".swift").first?.hasSuffix($0) ?? false
        }) {
            return filtered.count == 0
        }
        return false
    }
}

extension Structure {
    func isAnnotated(with annotation: String, in content: String) -> Bool {
        return extractDocComment(content).contains(annotation)
    }
    
    func extractDocComment(_ content: String) -> String {
        let len = dictionary["key.doclength"] as? Int64 ?? 0
        let offset = dictionary["key.docoffset"] as? Int64 ?? -1
        
        return extract(offset: offset, length: len, content: content)
    }
    
    func extractAttributes(_ content: String, filterOn: String? = nil) -> [String] {
        guard let attributeDict = dictionary["key.attributes"] as? [SourceKitRepresentable]  else {
            return []
        }

        return attributeDict.compactMap { (attr: SourceKitRepresentable) -> String? in
            if let attribute = attr as? [String: SourceKitRepresentable], let attributeVal = attribute["key.attribute"] as? String {
                if let filterAttribute = filterOn, attributeVal != filterAttribute {
                    return nil
                }
                return extract(attribute, startOffset: -1, from: content)
            }
            return nil
        }
    }
    
    func extract(_ source: [String: SourceKitRepresentable], startOffset: Int64, from content: String) -> String {
        if let offset = source[SwiftDocKey.offset.rawValue] as? Int64,
            let len = source[SwiftDocKey.length.rawValue] as? Int64 {

            return extract(offset: offset, startOffset: startOffset, length: len, content: content)
        }
        return ""
    }
}

func defaultVal(typeName: String) -> String? {
    if typeName.hasSuffix("?") {
        return "nil"
    }
    if (typeName.hasPrefix("[") && typeName.hasSuffix("]")) ||
        typeName.hasPrefix("Array") ||
        typeName.hasPrefix("Dictionary") {
        return "\(typeName)()"
    }
    if typeName == "Bool" {
        return "false"
    }
    if typeName == "String" ||
        typeName == "Character" {
        return "\"\""
    }
    
    if typeName == "Int" ||
        typeName == "Int8" ||
        typeName == "Int16" ||
        typeName == "Int32" ||
        typeName == "Int64" ||
        typeName == "Double" ||
        typeName == "CGFloat" ||
        typeName == "Float" {
        return "0"
    }
    return nil
}
