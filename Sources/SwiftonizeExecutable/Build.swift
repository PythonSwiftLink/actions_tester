//
//  Build.swift
//  SwiftonizeCLI
//
//  Created by MusicMaker on 04/04/2023.
//

import Foundation
import ArgumentParser
import Swiftonize
import WrapContainers
import PythonSwiftCore
import PathKit
import PythonLib

public let astorToSource: PyPointer = pythonImport(from: "astor", import_name: "to_source")!

public enum BuildWrapSpecType {
	
}

public struct BuildWrapSpec: Decodable {
	
	//public var type: BuildWrapSpecType
	var paths: [Path]
	
	
	
	public init(from decoder: Decoder) throws {
		var c = try decoder.unkeyedContainer()
		paths = []
		while !c.isAtEnd {
			paths.append(.init(try c.decode(String.self)))
		}
	}
}

public class BuildWrapFolder {
	
	var path: Path
	
	var pyiFiles: [Path] = []
	var pyFiles: [Path] = []
	var swiftFiles: [Path] = []
	var subFolders: [BuildWrapFolder] = []
	var specs: [BuildWrapSpec] = []
	var excluded: [Path] = []
	
	init(path: Path) {
		self.path = path
		if path.isDirectory {
			for subPath in path {
				if subPath.isDirectory {
					subFolders.append(.init(path: subPath))
				} else {
					if let ext = path.extension {
						switch ext {
						case "py": pyFiles.append(subPath)
						case "pyi": pyiFiles.append(subPath)
						case "swift": swiftFiles.append(subPath)
						case "json": break
						default: break
						}
					}
					
				}
			}
		}
		
	}
}

public enum BuildWrapSourceType {
	case pyi(pyi: Path)
	case py(py: Path)
	case swift(swift: Path)
	case spec(spec: BuildWrapSpec)
	case folder(folder: BuildWrapFolder)
}

public class BuildWrapConfig {
	var source: BuildWrapSourceType
	var destination: Path
	
	
	public var beeware: Bool
	
	init(source: BuildWrapSourceType, destination: Path, beeware: Bool) {
		self.source = source
		self.destination = destination
		self.beeware = beeware
	}
}


fileprivate extension PyPointer {
    
    func callAsFunction(_ string: String) throws -> String {
        //PyObject_Vectorcall(self, args, arg_count, nil)
        let _string = string.pyPointer
        guard let rtn = PyObject_CallOneArg(self, _string) else { throw PythonError.call }
        
        return (try? .init(object: rtn)) ?? ""
    }
}

func build_wrapper(src: Path, dst: Path, site: Path?, beeware: Bool = true) async throws {
    
    //let filename = src.lastPathComponent.replacingOccurrences(of: ".py", with: "")
    let filename = src.lastComponentWithoutExtension
    //let code = try String(contentsOf: src)
    let code = try src.read(.utf8)
    
    let module = await WrapModule(fromAst: filename, string: code, swiftui: beeware)
//    let module = await buildWrapModule(name: filename, code: code, swiftui: beeware)
//    /try module.pySwiftCode.write(to: dst, atomically: true, encoding: .utf8)
    let module_code = module.code.formatted().description
        .replacingOccurrences(of: "Unmanaged < ", with: "Unmanaged<")
        .replacingOccurrences(of: " > .fromOpaque", with: ">.fromOpaque")
    
//    return
    try dst.write(module_code)
    
    if let site = site {
		
		let pyi: String = try astorToSource(module.ast)
		
		try (site + "\(filename).pyi").write(pyi, encoding: .utf8)
		
		
		
		return
        guard let test_parse: PyPointer = pythonImport(from: "pure_py_parser", import_name: "testParse") else { throw PythonError.attribute }
        do {
            try (site + "\(filename).py").write(test_parse(code), encoding: .utf8)
        }
        
        catch let err as PythonError {
            print(err.localizedDescription)
            err.triggerError("")
        }
        catch let other {
            print(other.localizedDescription)
        }
    }
}



func build_wrapper(config: BuildWrapConfig) async throws {
	let source = config.source
	switch source {
	case .pyi(let pyi):
		try await build_wrapper(src: pyi, dst: config.destination, site: nil, beeware: config.beeware)
	case .py(let py):
		try await build_wrapper(src: py, dst: config.destination, site: nil, beeware: config.beeware)
	case .swift(let swift):
		let mod = WrapModule(filename: swift.lastComponentWithoutExtension, file: try! swift.read(.utf8))
		let dst = (config.destination + "_\(swift.lastComponent)")
		try dst.write(mod.code.formatted().description, encoding: .utf8)
		
	case .spec(_):
		break
	case .folder(_):
		break
	}
	
}

