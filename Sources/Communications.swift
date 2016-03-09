import Result

public final class Subscriber {
    private let client: Client

    private var topicMessages: [String: Result<UnsafeBufferPointer<UInt8>, PhobosError> -> Void] = [:]

    public init(client: Client) {
        self.client = client
    }

    public func listen<T: Serializable>(topic: String, callback: Result<T, PhobosError> -> Void) {
        self.topicMessages[topic] = { result in
            switch result {
            case let .Success(bytes):
                if let object = T(bytes: bytes) {
                    callback(.Success(object))
                } else {
                    callback(.Failure(.Deserialize))
                }
            case let .Failure(error):
                callback(.Failure(error))
            }
        }

        self.client.subscribe(topic, subscriber: self)
    }

    public func stopListening(topic: String){
        self.client.unsubscribe(topic, subscriber: self)
    }
}

public struct Publisher<T: Serializable> {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    func publish(topic: String, message: T) {
        self.client.publish(topic, data: message.serialize())
    }
}

public protocol Client {
    func publish(topic: String, data: UnsafeBufferPointer<UInt8>)

    func subscribe(topic: String, subscriber: Subscriber)
    func unsubscribe(topic: String, subscriber: Subscriber)
}