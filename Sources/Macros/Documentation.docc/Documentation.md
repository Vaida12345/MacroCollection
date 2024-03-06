# ``StratumMacros``

A collection of macros.


## Overview

This package provides a collection of macros.


## Getting Started

`StratumMacros` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(name: "StratumMacros", 
             path: "~/Library/Mobile Documents/com~apple~CloudDocs/DataBase/Projects/Packages/StratumMacros")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
~/Library/Mobile Documents/com~apple~CloudDocs/DataBase/Projects/Packages/StratumMacros
```

## Topics

### Extending Swift
A set of macros aiming to extend the functionality of Swift

- ``accessingAssociatedValues()``
- ``codable()``
- ``customCodable()``
- ``memberwiseInitializable()``

### SwiftUI
A set of macros to make coding in SwiftUI easier

- ``dataProviding()``
- ``environment(_:)-72eo5``

### Compile time Constants
A set of macros offering compile time checking

- ``symbol(_:)``
- ``url(_:)``
