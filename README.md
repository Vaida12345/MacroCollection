# MacroCollection

A collection of macros.

## Macros

### Extending Swift
A set of macros aiming to extend the functionality of Swift

- ``accessingAssociatedValues()``
- ``codable()``
- ``memberwiseInitializable()``

### SwiftUI
A set of macros to make coding in SwiftUI easier

- ``environment(_:)``

### Compile time Constants
A set of macros offering compile time checking

- ``symbol(_:)``
- ``url(_:)``
- ``encrypt(_:)``


## Getting Started

`MacroCollection` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://www.github.com/Vaida12345/MacroCollection", from: "1.0.0")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://www.github.com/Vaida12345/MacroCollection
```


## Documentation

This package uses [DocC](https://www.swift.org/documentation/docc/) for documentation. [View on Github Pages](https://vaida12345.github.io/MacroCollection/documentation/macrocollection/)
