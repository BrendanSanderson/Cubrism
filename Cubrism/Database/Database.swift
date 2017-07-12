import MongoKitten

class Database {
    static let database = Database(username: Env.MongoUsername, password: Env.MongoPassword, host: Env.MongoHost, port: Env.MongoPort)!
    
    var server: MongoKitten.Server
    var db: MongoKitten.Database
    var config: MongoKitten.Collection
    
    init?(username: String, password: String, host: String, port: String) {
        do {
            server = try Server("mongodb://\(username):\(password)@\(host):\(port)", automatically: true)
            db = server[Env.MongoDbName]
            config = db["config"]
            
        } catch {
            print("MongoDB is not available on the given host and port")
            return nil
        }
    }
}

struct Env {
    static let file = Bundle.main.url(forResource: "config", withExtension: "json")
    static let data = try Data(contentsOf: file!)
    static let json = try JSONSerialization.jsonObject(with: data, options: [])
    static let configDict = json as? [String: Any]
    static let MongoUsername = app.config["app", "MONGO_USERNAME"].string!
    static let MongoPassword = app.config["app", "MONGO_PASSWORD"].string!
    static let MongoHost = app.config["app", "MONGO_HOST"].string!
    static let MongoPort = app.config["app", "MONGO_PORT"].string!
    static let MongoDbName = app.config["app", "MONGO_DB_NAME"].string!
}
