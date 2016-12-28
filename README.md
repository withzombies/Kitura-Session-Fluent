# Kitura-Session-Fluent
A extension of [Kitura-Session](https://github.com/IBM-Swift/Kitura-Session) that stores session data in an existing Fluent database.

This is a 3rdParty library! This project is not an official Swift@IBM project, nor is it affiliated with Swift@IBM.
## API
In order to use the Kitura-Session-Fluent library, create an instance of `FluentSessionStore` and pass it to the `Session` constructor:

```swift
import KituraSession
import FluentSessionStore
import FluentSQLite

try! driver = SQLiteDriver()
database = Database(driver)

let sessionstore = FluentSessionStore(database: database)
let session = Session(secret: <secret>, store: sesionstore)
```

The constructor requires a Fluent.Database such as those provided by [FluentSQLite](https://github.com/vapor/sqlite-driver) or [FluentPostgreSQL](https://github.com/vapor/postgresql-driver).

## License
This library is licensed under Apache 2.0, Copyright 2016 Ryan Stortz. Full license text is available in [LICENSE](LICENSE.txt).
