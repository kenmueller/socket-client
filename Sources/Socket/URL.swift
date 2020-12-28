import Foundation

internal extension URL {
	/// An error that can be thrown from `URL` operations.
	enum Error: Swift.Error {
		/// The query parameter is invalid.
		case invalidQueryParameter
		
		/// The `SocketQuery` is invalid.
		case invalidQuery
	}
	
	/// Add a query parameter to a `URL`.
	///
	/// - Parameters:
	/// 	- key: The key of the query parameter.
	/// 	- value: The value of the query parameter.
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
	
	/// Add a `data` query parameter containing a `SocketQuery` to a `URL`.
	///
	/// - Parameters:
	/// 	- query: The `SocketQuery` to add to the `URL`.
	func addQuery<Query: SocketQuery>(_ query: Query) throws -> Self {
		guard let value = String(data: try encoder.encode(query), encoding: .utf8) else {
			throw Error.invalidQuery
		}
		
		return try addQuery("data", value)
	}
}
