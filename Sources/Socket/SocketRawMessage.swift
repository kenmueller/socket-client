/// The raw message sent to and from a `Socket`.
internal struct SocketRawMessage: Codable {
	/// The message ID.
	internal let id: String
	
	/// The stringified message data.
	internal let data: String
	
	/// Create a new raw message from a `SocketMessage`.
	///
	/// - Parameters:
	/// 	- message: A `SocketMessage`.
	internal init<Message: SocketMessage>(_ message: Message) throws {
		guard let data = String(
			data: try encoder.encode(message),
			encoding: .utf8
		) else {
			throw SocketError.invalidData
		}
		
		id = Message.id
		self.data = data
	}
}
