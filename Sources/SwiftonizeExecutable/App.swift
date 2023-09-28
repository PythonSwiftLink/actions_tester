

import Foundation
import Swiftonize
import PythonSwiftCore
import PathKit
import ArgumentParser
//import XcodeEdit

@main
struct App: AsyncParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: "swiftonize",
		abstract: "Generate static references for autocompleted resources like images, fonts and localized strings in Swift projects",
		version: "0.2",
		subcommands: [Generate.self]
	)
}

extension App {
	struct Generate: AsyncParsableCommand {
		static var configuration = CommandConfiguration(abstract: "Generates swiftonized file")
		@Argument(transform: { p -> PathKit.Path in .init(p) }) var source
		@Argument(transform: { p -> PathKit.Path in .init(p) }) var destination

		@Option var stdlib: String?
		@Option var pyextra: String?

		@Option(transform: { p -> PathKit.Path? in .init(p) }) var site
		
		func run() async throws {
			print(source)
			let processInfo = ProcessInfo()
			
			
			var lib: String = ""
			var extra: String = ""
			if let stdlib = stdlib, let pyextra = pyextra {
				lib = stdlib
				extra = pyextra
			}
			else if let call = processInfo.arguments.first {
				let callp = PathKit.Path(call)
				if callp.isSymlink {
					let real = try callp.symlinkDestination()
					let root = real.parent()
					lib = (root + "python_stdlib").string
					extra = (root + "python-extra").string
					
				}
			}
			let python = PythonHandler.shared
			if !python.defaultRunning {
				python.start(stdlib: lib, app_packages: [extra], debug: true)
			}
			
			let wrappers = try SourceFilter(root: source)
			
			for file in wrappers.sources {
				
				switch file {
				case .pyi(let path):
					try await build_wrapper(src: path, dst: file.swiftFile(destination), site: site)
				case .py(let path):
					try await build_wrapper(src: path, dst: file.swiftFile(destination), site: site)
				case .both(_, let pyi):
					try await build_wrapper(src: pyi, dst: file.swiftFile(destination), site: site)
				}
			}
			
		}
	}
}
