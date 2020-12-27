internal struct SocketRawMessage: Codable {
	internal let id: String
	internal let data: String
	
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
