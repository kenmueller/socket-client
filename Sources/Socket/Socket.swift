import Foundation

/// A WebSocket instance.
public final class Socket {
	/// Used as a callback to handle errors thrown by a `Socket` instance.
	public typealias ErrorHandler = (Error) -> Void
	
	/// The interval in seconds to keep the connection alive.
	private static let PING_INTERVAL: TimeInterval = 10
	
	/// The base URL of the `Socket` instance.
	private let url: URL
	
	/// The internal `URLSessionWebSocketTask` that the `Socket` instance uses.
	private var task: URLSessionWebSocketTask?
	
	/// The timer that keeps the connection alive.
	private var pingTimer: Timer?
	
	/// Inbound message listeners.
	private var listeners = [String: (Data) -> Void]()
	
	/// Handles incoming message errors.
	private var messageErrorHandler: ErrorHandler?
	
	/// Handles ping errors.
	private var pingErrorHandler: ErrorHandler?
	
	/// Checks if the `Socket` is connected or not.
	public private(set) var isConnected = false
	
	/// Prepare a new `Socket`, but do not connect to the server.
	/// You must call `.connect(query:)` in order to establish a connection.
	///
	/// - Parameters:
	/// 	- url: Starts with `ws://`.
	public init(url: URL) {
		self.url = url
	}
	
	/// Prepare a new `Socket` and connect to the server with the provided `Query`.
	///
	/// - Parameters:
	/// 	- url: Starts with `ws://`.
	/// 	- query: The initial data to be sent to the server.
	///
	/// - Throws: If the `query` or `url` is invalid.
	public init<Query: SocketQuery>(url: URL, query: Query) throws {
		self.url = url
		try connect(query: query)
	}
	
	deinit {
		disconnect()
	}
	
	/// Connect to the server. Only use if you did not initialize the `Socket` with a `Query`.
	///
	/// - Parameters:
	/// 	- query: The initial data to be sent to the server.
	///
	/// - Throws: If the `query` or `url` is invalid.
	public func connect<Query: SocketQuery>(query: Query) throws {
		if isConnected { return }
		
		task = URLSession.shared.webSocketTask(
			with: try url.addQuery(query)
		)
		
		guard let task = task else { return }
		
		attachOnReceive()
		task.resume()
		ping()
		
		isConnected = true
	}
	
	/// Handle the next incoming message.
	private func attachOnReceive() {
		task?.receive(completionHandler: onReceive)
	}
	
	/// Handle a server response.
	private func onReceive(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
		attachOnReceive()
		
		switch result {
		case let .success(message): onMessage(message)
		case let .failure(error): messageErrorHandler?(error)
		}
	}
	
	/// Handle a successful server response.
	private func onMessage(_ message: URLSessionWebSocketTask.Message) {
		guard case let .data(rawData) = message else { return }
		
		guard
			let message = try? decoder.decode(SocketRawMessage.self, from: rawData),
			let listener = self.listeners[message.id],
			let data = message.data.data(using: .utf8)
		else { return }
		
		listener(data)
	}
	
	/// Start the ping cycle to keep the connection alive.
	private func ping() {
		pingTimer = Timer.scheduledTimer(
			withTimeInterval: Self.PING_INTERVAL,
			repeats: true
		) { [weak self] _ in
			guard let self = self else { return }
			
			self.task?.sendPing { error in
				guard let error = error else { return }
				self.pingErrorHandler?(error)
			}
		}
	}
	
	/// Handle incoming message errors.
	///
	/// - Parameters:
	/// 	- handler: The `ErrorHandler` to be used.
	public func onMessageError(_ handler: @escaping ErrorHandler) {
		messageErrorHandler = handler
	}
	
	/// Handle outbound ping errors.
	///
	/// - Parameters:
	/// 	- handler: The `ErrorHandler` to be used.
	public func onPingError(_ handler: @escaping ErrorHandler) {
		pingErrorHandler = handler
	}
	
	/// Listen for incoming messages from the server.
	///
	/// - Parameters:
	/// 	- queue: The `DispatchQueue` to run the listener on.
	/// 	- listener: Inputs the `Message` received from the server.
	///
	/// ```
	/// socket.on { (greeting: Greeting) in
	///     print(greeting.message)
	/// }
	/// ```
	public func on<Message: SocketMessage>(
		_ queue: DispatchQueue = .main,
		_ listener: @escaping (Message) -> Void
	) {
		listeners[Message.id] = { data in
			guard let message = try? decoder.decode(Message.self, from: data) else {
				return
			}
			
			queue.async {
				listener(message)
			}
		}
	}
	
	/// Send a message to the server.
	///
	/// - Parameters:
	/// 	- message: The `SocketMessage` to be sent.
	/// 	- completion: Called when the message is sent, might contain an `Error` if something didn't go right.
	///
	/// ```
	/// socket.send(Message(text: "Hello, world!"))
	/// ```
	public func send<Message: SocketMessage>(_ message: Message, completion: ((Error?) -> Void)? = nil) {
		do {
			guard let task = task else {
				completion?(SocketError.disconnected)
				return
			}
			
			task.send(.data(try encoder.encode(SocketRawMessage(message)))) {
				completion?($0)
			}
		} catch {
			completion?(error)
		}
	}
	
	/// Disconnect from the server.
	public func disconnect() {
		guard isConnected else { return }
		
		task?.cancel()
		pingTimer?.invalidate()
		
		isConnected = false
	}
}
