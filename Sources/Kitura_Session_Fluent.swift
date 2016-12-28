/**
 * Copyright Ryan Stortz 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import KituraSession
import Fluent

public class FluentSessionStore : Store {
    
    public class SessionData : Entity {
        public var id : Node?
        public var exists : Bool = false
        
        public var session : String
        public var data : Data
        var alive_var : Bool = true
        
        var expires : Date
        
        public init(id: Node?, session: String, data: Data, ttl: TimeInterval = 3600) {
            self.id = id
            self.session = session
            self.data = data
            
            self.expires = Date(timeIntervalSinceNow: ttl)
        }
        
        public init(session: String, data: Data, ttl: TimeInterval = 3600)
        {
            self.session = session
            self.data = data
            self.expires = Date(timeIntervalSinceNow: ttl)
        }
        
        public required init(node: Node, in context: Context) throws {
            id = try node.extract("id")
            session = try node.extract("session")
            expires = try Date(timeIntervalSince1970: node.extract("expires"))
            data = try Data(base64Encoded:node.extract("data"))!
            alive_var = try node.extract("alive")
        }
        
        public func makeNode(context: Context) throws -> Node {
            return try Node(node: [
                "id": id,
                "session" : session,
                "expires": expires.timeIntervalSince1970,
                "data" : data.base64EncodedString(),
                "alive" : alive_var,
                ])
        }
        
        public static func prepare(_ database: Database) throws {
            try database.create(entity) { users in
                users.id()
                users.string("session")
                users.double("expires")
                users.data("data")
                users.bool("alive")
            }
        }
        
        public static func revert(_ database: Database) throws {
            try database.delete(entity)
        }
        
        public func touch(ttl: TimeInterval = 3600) {
            expires = Date(timeIntervalSinceNow: ttl)
        }
        
        public func alive() -> Bool {
            if expires.compare(Date.init()) == .orderedAscending {
                alive_var = false
            }
            return alive_var
        }
        
        public func expire() {
            alive_var = false
        }
    }
    
    
    
    public init(database: Fluent.Database) {
        try? SessionData.prepare(database)
        SessionData.database = database
    }
    
    func createError(errorMessage: String) -> NSError {
        #if os(Linux)
            let userInfo: [String: Any]
        #else
            let userInfo: [String: String]
        #endif
        userInfo = [NSLocalizedDescriptionKey: errorMessage]
        return NSError(domain: "FluentSessionDomain", code: 0, userInfo: userInfo)
        
    }
    
    func loadSession(sessionId: String) throws -> SessionData? {
        do {
            
            guard let first = try SessionData.query()
                .filter("session", sessionId)
                .filter("alive", true)
                .filter("expires", Filter.Comparison.greaterThanOrEquals, Date().timeIntervalSince1970)
                .sort("id", Sort.Direction.descending)
                .first() else {
                    return nil
            }
            
            return first
        } catch {
            return nil
        }
        
    }
    
    public func load(sessionId: String, callback: @escaping (Data?, NSError?) -> Void) {
        
        do {
            guard let first = try loadSession(sessionId: sessionId) else {
                print("Could not retrieve session data...")
                callback(nil, nil)
                return
            }
            
            callback(first.data, nil)
            return
            
        } catch {
            callback(nil, createError(errorMessage: "Could not load session data"))
        }
        
        
    }
    
    public func save(sessionId: String, data: Data, callback: @escaping (NSError?) -> Void) {
        do {
            let first = try loadSession(sessionId: sessionId)

            var sess : SessionData
            if first == nil {
                sess = SessionData(session: sessionId, data: data)
            } else {
                sess = first!
                sess.data = data
            }
            
            try sess.save()
            
            callback(nil)
            
        } catch {
            callback(createError(errorMessage: "Could not save session data"))
            return
        }
    }
    
    public func touch(sessionId: String, callback: @escaping (NSError?) -> Void) {
        
        guard var first = try? loadSession(sessionId: sessionId) else {
            callback(createError(errorMessage: "Could not load session data"))
            return
        }
        
        first?.touch()
        try? first?.save()
        
        callback(nil)
        return
        
    }
    
    public func delete(sessionId: String, callback: @escaping (NSError?) -> Void) {
        guard var first = try? loadSession(sessionId: sessionId) else {
            callback(createError(errorMessage: "Could not load session data"))
            return
        }
        
        first?.expire()
        try? first?.save()
        
        // Kill any that have expired
        try? SessionData.query()
            .filter("expires", Filter.Comparison.lessThan, Date().timeIntervalSince1970)
            .modify(Node.object(["alive" : false]))
        
        callback(nil)
        return
        
    }
}
