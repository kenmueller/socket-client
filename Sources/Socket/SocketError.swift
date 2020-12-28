/// An error thrown by a `Socket`.
public enum SocketError: Error {
	/// The `Socket` is disconnected.
	case disconnected
	
	/// The data provided is invalid.
	case invalidData
}
