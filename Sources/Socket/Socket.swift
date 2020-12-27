import Foundation

public final class Socket {
	public typealias ErrorHandler = (Error) -> Void
	
	private static let PING_INTERVAL: TimeInterval = 10
	
	private let task: URLSessionWebSocketTask
	private var pingTimer: Timer?
	
	private var listeners = [String: (Data) -> Void]()
	private var messageErrorHandler: ErrorHandler?
	private var pingErrorHandler: ErrorHandler?
	
	public private(set) var isConnected = false
	
	public init<Query: SocketQuery>(url: URL, query: Query, connect: Bool = true) throws {
		task = URLSession.shared.webSocketTask(
			with: try url.addQuery(query)
		)
		
		if connect {
			self.connect()
		}
	}
	
	deinit {
		disconnect()
	}
	
	public func connect() {
		if isConnected { return }
		
		attachOnReceive()
		task.resume()
		ping()
		
		isConnected = true
	}
	
	private func attachOnReceive() {
		task.receive(completionHandler: onReceive)
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
			
			self.task.sendPing { error in
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
	
	public func on<Message: SocketMessage>(_ listener: @escaping (Message) -> Void) {
		listeners[Message.id] = { data in
			guard let message = try? decoder.decode(Message.self, from: data) else {
				return
			}
			
			listener(message)
		}
	}
	
	public func send<Message: SocketMessage>(_ message: Message, completion: ((Error?) -> Void)? = nil) {
		do {
			task.send(.data(try encoder.encode(SocketRawMessage(message)))) {
				completion?($0)
			}
		} catch {
			completion?(error)
		}
	}
	
	public func disconnect() {
		guard isConnected else { return }
		
		task.cancel()
		pingTimer?.invalidate()
		
		isConnected = false
	}
}
