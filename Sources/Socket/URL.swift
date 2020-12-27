import Foundation

internal extension URL {
	enum Error: Swift.Error {
		case invalidQueryParameter
		case invalidQuery
	}
	
	func addQuery(_ key: String, _ value: String) throws -> Self {
		guard var components = URLComponents(string: absoluteString) else {
			throw Error.invalidQueryParameter
		}
		
		components.queryItems = (components.queryItems ?? []) + [
			.init(name: key, value: value)
		]
		
		guard let url = components.url else {
			throw Error.invalidQueryParameter
		}
		
		return url
	}
	
	func addQuery<Query: SocketQuery>(_ query: Query) throws -> Self {
		guard let value = String(data: try encoder.encode(query), encoding: .utf8) else {
			throw Error.invalidQuery
		}
		
		return try addQuery("data", value)
	}
}
