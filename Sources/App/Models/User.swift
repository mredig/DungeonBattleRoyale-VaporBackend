import Authentication
import FluentSQLite
import Vapor

/// A registered user, capable of owning todo items.
final class User: SQLiteModel {
	/// User's unique identifier.
	/// Can be `nil` if the user has not been saved yet.
	var id: Int?
	var username: String
	var password: String
	var avatar = 0
	var playerID: String = UUID().uuidString
	var roomID = -1

	private var xLocation: Double = 0
	private var yLocation: Double = 0
	var location: CGPoint {
		get { CGPoint(x: xLocation, y: yLocation) }
		set {
			xLocation = Double(newValue.x)
			yLocation = Double(newValue.y)
		}
	}
	lazy var destination: CGPoint = {
		location
	}()

	lazy var webSocket: WebSocket? = nil


	/// Creates a new `User`.
	init(id: Int? = nil, username: String, passwordHash: String) {
		self.id = id
		self.password = passwordHash
		self.username = username
		self.xLocation = 0
		self.yLocation = 0
	}

	convenience init?(id: Int? = nil, username: String, password: String) {
		guard let pwhash = try? BCrypt.hash(password) else { return nil }
		self.init(id: id, username: username, passwordHash: pwhash)
	}
}

extension User {
	enum CodingKeys: String, CodingKey  {
		case id
		case username
		case password
		case avatar
		case playerID
		case xLocation
		case yLocation
		case roomID
	}
}


extension User: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(username)
	}

	static func == (lhs: User, rhs: User) -> Bool {
		rhs.username == lhs.username
	}
}

/// Allows users to be verified by basic / password auth middleware.
extension User: PasswordAuthenticatable {
	/// See `PasswordAuthenticatable`.
	static var usernameKey: WritableKeyPath<User, String> {
		return \.username
	}
	
	/// See `PasswordAuthenticatable`.
	static var passwordKey: WritableKeyPath<User, String> {
		return \.password
	}
}

/// Allows users to be verified by bearer / token auth middleware.
extension User: TokenAuthenticatable {
	/// See `TokenAuthenticatable`.
	typealias TokenType = UserToken
}

/// Allows `User` to be used as a Fluent migration.
extension User: Migration {
	/// See `Migration`.
	static func prepare(on conn: SQLiteConnection) -> Future<Void> {
		return SQLiteDatabase.create(User.self, on: conn) { builder in
			builder.field(for: \.id, isIdentifier: true)
			builder.field(for: \.username)
			builder.field(for: \.password)
			builder.field(for: \.roomID)
			builder.field(for: \.xLocation)
			builder.field(for: \.yLocation)
			builder.field(for: \.avatar)
			builder.field(for: \.playerID)
			builder.unique(on: \.playerID)
			builder.unique(on: \.username)
		}
	}
}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }
