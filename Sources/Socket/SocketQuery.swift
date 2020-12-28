import Foundation

/// The initial data sent from the client to the server.
/// Must contain an `id` which represents the client ID.
public protocol SocketQuery: Encodable {
	/// The client ID.
	var id: UUID { get }
}
