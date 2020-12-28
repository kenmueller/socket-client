/// A message sent to and from a `Socket`.
/// Contains a unique `id` that identifies this message and differentiates it from other messages.
///
/// ```
/// struct Greeting: SocketMessage {
///     static let id = "greeting"
///     let text: String
/// }
/// ```
public protocol SocketMessage: Codable {
	/// The unique ID of this message.
	/// If the message represents a greeting from the server, the `id` might be `"greeting"`.
	static var id: String { get }
}
