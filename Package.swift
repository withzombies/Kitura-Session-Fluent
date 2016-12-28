import PackageDescription

let package = Package(
    name: "KituraSessionFluent",
    dependencies: [
      .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-Session.git", majorVersion: 1),
    ]
)
