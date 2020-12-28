import Foundation

public final class Socket {
	public typealias ErrorHandler = (Error) -> Void
	
	private static let PING_INTERVAL: TimeInterval = 10
	
	private let url: URL
	
	private var task: URLSessionWebSocketTask?
	private var pingTimer: Timer?
	
	private var listeners = [String: (Data) -> Void]()
	private var messageErrorHandler: ErrorHandler?
	private var pingErrorHandler: ErrorHandler?
	
	public private(set) var isConnected = false
	
	public init(url: URL) {
		self.url = url
	}
	
	public init<Query: SocketQuery>(url: URL, query: Query) throws {
		self.url = url
		try connect(query: query)
	}
	
	deinit {
		disconnect()
	}
	
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
	
	private func attachOnReceive() {
		task?.receive(completionHandler: onReceive)
	}
	
	private func onReceive(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
		attachOnReceive()
		
		switch result {
		case let .success(message): onMessage(message)
		case let .failure(error): messageErrorHandler?(error)
		}
	}
	
	private func onMessage(_ message: URLSessionWebSocketTask.Message) {
		guard case let .data(rawData) = message else { return }
		
		guard
			let message = try? decoder.decode(SocketRawMessage.self, from: rawData),
			let listener = self.listeners[message.id],
			let data = message.data.data(using: .utf8)
		else { return }
		
		listener(data)
	}
	
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
	
	public func onMessageError(_ handler: @escaping ErrorHandler) {
		messageErrorHandler = handler
	}
	
	public func onPingError(_ handler: @escaping ErrorHandler) {
		pingErrorHandler = handler
	}
	
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
	
	public func disconnect() {
		guard isConnected else { return }
		
		task?.cancel()
		pingTimer?.invalidate()
		
		isConnected = false
	}
}
