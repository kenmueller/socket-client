import Foundation

public protocol SocketQuery: Encodable {
	var id: UUID { get }
}
