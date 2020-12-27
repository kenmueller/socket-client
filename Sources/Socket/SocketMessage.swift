public protocol SocketMessage: Codable {
	static var id: String { get }
}
