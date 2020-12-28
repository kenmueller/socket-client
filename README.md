# Socket

Used on the client in conjuction with [socket-server](https://github.com/kenmueller/socket-server)

## Install

1. File -> Swift Packages -> Add Package Dependency
2. Enter `https://github.com/kenmueller/socket-client`

## Create a `Query`

A `Query` conforms to the `SocketQuery` protocol and represents the initial data that the client sends to the server. Every `Query` must contain an `id` which represents the client's unique ID.

```swift
struct UserQuery: SocketQuery {
    let id: UUID
	let name: String
}
```

## Create a `Socket`

```swift
let url = URL(string: "ws://127.0.0.1:8080")!

// Do not autoconnect
let socket = Socket(url: url)

// Autoconnect
let socket = try! Socket(
	url: url,
	query: UserQuery(id: UUID(), name: "Ken")
)
```

## Connect to the server

If you provided a `query` to the `Socket` initializer, you do not need to call `socket.connect` as the socket is already connected to the server.

```swift
try! socket.connect(
    query: UserQuery(id: UUID(), name: "Ken")
)
```

## Create a `Message`

A `Message` conforms to the `SocketMessage` protocol and represents a message that could be sent to and from a `Socket`. Every `Message` must contain a static property `id` which differentiates it from other messages.

```swift
struct Greeting: SocketMessage {
    static let id = "greeting"
    let text: String
}
```

## Listen to incoming messages

The parameter type inside of the listener dictates what kind of message triggers the listener. If the parameter is a `Greeting`, when the server sends `Greeting` messages to the client, the listener will be called.

```swift
socket.on { (greeting: Greeting) in
    print(greeting.text)
}

// Run on a different thread
socket.on(.global(qos: .background)) { (greeting: Greeting) in
	print(greeting.text)
}
```

## Send messages

```swift
struct Message: SocketMessage {
    static let id = "message"
    let text: String
}

socket.send(Message(text: "Hello!"))

// With callback
socket.send(Message(text: "Hello!")) { error in
    if let error = error { print(error) }
}
```

## Listen for errors

```swift
// Listen for incoming message errors
socket.onMessageError { error in
    print(error)
}

// Listen for keepalive errors
socket.onPingError { error in
    print(error)
}
```

## Disconnect

```swift
socket.disconnect()
```
