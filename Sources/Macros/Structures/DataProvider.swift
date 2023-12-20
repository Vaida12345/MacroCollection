//
//  DataProvider.swift
//  The Nucleus Module
//
//  Created by Vaida on 6/13/22.
//  Copyright © 2019 - 2023 Vaida. All rights reserved.
//


import Foundation
import SwiftData
import Nucleus


/// The provider for the main storable workflow of data.
///
/// - Important: Do not inherit from this protocol directly, use the ``dataProviding()`` macro.
///
/// **Example**
///
/// Create a `final class` that inherits from this protocol.
///
/// ```swift
/// @dataProviding
/// @Obsersable
/// final class Provider {
///
///     var stories: [Story] = []
/// }
/// ```
///
/// In the `@main App`, pass the created `instance`.
///
/// In this way, this structure can be accessed across the app, and any mutation is observed in all views.
///
/// ```swift
/// @main
/// struct StoryApp: App {
///
///     @State private var provider = Provider.instance
///     @Environment(\.scenePhase) private var scenePhase
///
///     var body: some Scene {
///         EntryView()
///             .environmentObject(provider)
///             .onChange(of: scenePhase) { newPhase in
///                 if newPhase == .background {
///                     try? provider.save()
///                 }
///             }
///     }
///
/// }
/// ```
///
/// In this way, an instance can be created or loaded from disk by calling ``instance``. The instance can be saved using ``save()``, which stores the encoded instance into ``storageItem`` using `.plist`.
///
/// In the example app, the loading and saving progress is automated, where the file is loaded on setup, and saved when the app enters background.
public protocol DataProvider: Codable, Identifiable {
    
    /// The main ``DataProvider`` to work with.
    ///
    /// In the `@main App` declaration, declare a `StateObject` of `instance`. In this way, this structure can be accessed across the app, and any mutation is observed in all views.
    static var instance: Self { get set }
    
}

public extension DataProvider {
    
    /// The name of the class.
    private static var className: String {
        "\(Self.self)"
    }
    
    /// The `FinderItem` indicating the location where this ``DataProvider`` is persisted on disk.
    static var storageItem: FinderItem {
        get throws {
            try .dataProviderDirectory.with(subPath: "\(className)\(".plist")")
        }
    }
    
    /// Save the encoded provider to ``storageItem`` using `.plist`.
    @inlinable
    func save() throws {
        try Self.storageItem.removeIfExists()
        try self.write(to: Self.storageItem, using: .plist)
    }
    
}
