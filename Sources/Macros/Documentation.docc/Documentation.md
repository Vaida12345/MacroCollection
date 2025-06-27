# ``MacroCollection``

A collection of macros.

@Metadata {
    @PageColor(orange)
    
    @SupportedLanguage(swift)
    
    @Available(macOS,    introduced: 13.0)
    @Available(iOS,      introduced: 16.0)
    @Available(watchOS,  introduced: 9.0)
    @Available(tvOS,     introduced: 16.0)
    @Available(visionOS, introduced: 1.0)
}


## Overview

This package provides a collection of macros.


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

## Topics

### Extending Swift
A set of macros aiming to extend the functionality of Swift

- ``accessingAssociatedValues()``
- ``codable()``
- ``memberwiseInitializable()``

### SwiftUI
A set of macros to make coding in SwiftUI easier

- ``environment(_:)-9vdmv``
- ``environment(_:)-5v3gv``

### Compile time Constants
A set of macros offering compile time checking

- ``symbol(_:)``
- ``url(_:)``
- ``encrypt(_:)``
