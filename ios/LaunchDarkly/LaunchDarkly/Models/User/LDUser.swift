//
//  LDUser.swift
//  LaunchDarkly
//
//  Created by Mark Pokorny on 7/11/17. +JMJ
//  Copyright © 2017 Catamorphic Co. All rights reserved.
//

import Foundation

/**
 LDUser allows clients to collect information about users in order to refine the feature flag values sent to the SDK. For example, the client app may launch with the SDK defined anonymous user. As the user works with the client app, information may be collected as needed and sent to LaunchDarkly. The client app controls the information collected, which LaunchDarkly does not use except as the client directs to refine feature flags. Client apps should follow [Apple's Privacy Policy](apple.com/legal/privacy) when collecting user information.

 The SDK caches last known feature flags for use on app startup to provide continuity with the last app run. Provided the LDClient is online and can establish a connection with LaunchDarkly servers, cached information will only be used a very short time. Once the latest feature flags arrive at the SDK, the SDK no longer uses cached feature flags. The SDK retains feature flags on the last 5 client defined users. The SDK will retain feature flags until they are overwritten by a different user's feature flags, or until the user removes the app from the device.

 The SDK does not cache user information collected, except for the user key. The user key is used to identify the cached feature flags for that user. Client app developers should use caution not to use sensitive user information as the user-key.
 */
public struct LDUser {
    
    ///String keys associated with LDUser properties.
    public enum CodingKeys: String, CodingKey {
        ///Key names match the corresponding LDUser property
        case key, name, firstName, lastName, country, ipAddress = "ip", email, avatar, custom, isAnonymous = "anonymous", device, operatingSystem = "os", lastUpdated = "updatedAt", config, privateAttributes = "privateAttrs"
    }

    /**
     LDUser attributes that can be marked private.

     The SDK will not include private attribute values in analytics events, but private attribute names will be sent.

     See Also: `LDConfig.allUserAttributesPrivate`, `LDConfig.privateUserAttributes`, and `privateAttributes`.
    */
    public static var privatizableAttributes: [String] {
        return [CodingKeys.name.rawValue, CodingKeys.firstName.rawValue, CodingKeys.lastName.rawValue, CodingKeys.country.rawValue, CodingKeys.ipAddress.rawValue, CodingKeys.email.rawValue, CodingKeys.avatar.rawValue, CodingKeys.custom.rawValue]
    }
    static var sdkSetAttributes: [String] {
        return [CodingKeys.device.rawValue, CodingKeys.operatingSystem.rawValue]
    }

    ///Client app defined string that uniquely identifies the user. If the client app does not define a key, the SDK will assign an identifier associated with the anonymous user. The key cannot be made private.
    public var key: String
    ///Client app defined name for the user. (Default: nil)
    public var name: String?
    ///Client app defined first name for the user. (Default: nil)
    public var firstName: String?
    ///Client app defined last name for the user. (Default: nil)
    public var lastName: String?
    ///Client app defined country for the user. (Default: nil)
    public var country: String?
    ///Client app defined ipAddress for the user. (Default: nil)
    public var ipAddress: String?
    ///Client app defined email address for the user. (Default: nil)
    public var email: String?
    ///Client app defined avatar for the user. (Default: nil)
    public var avatar: String?
    ///Client app defined dictionary for the user. The client app may declare top level dictionary items as private. If the client app defines custom as private, the SDK considers the dictionary private except for device & operatingSystem (which cannot be made private). See `privateAttributes` for details. (Default: nil)
    public var custom: [String: Any]?
    ///Client app defined isAnonymous for the user. If the client app does not define isAnonymous, the SDK will use the `key` to set this attribute. isAnonymous cannot be made private. (Default: true)
    public var isAnonymous: Bool
    ///Client app defined device for the user. The SDK will determine the device automatically, however the client app can override the value. The SDK will insert the device into the `custom` dictionary. The device cannot be made private. (Default: the system identified device)
    public var device: String?
    ///Client app defined operatingSystem for the user. The SDK will determine the operatingSystem automatically, however the client app can override the value. The SDK will insert the operatingSystem into the `custom` dictionary. The operatingSystem cannot be made private. (Default: the system identified operating system)
    public var operatingSystem: String?
    /**
     Client app defined privateAttributes for the user.

     The SDK will not include private attribute values in analytics events, but private attribute names will be sent.

     This attribute is ignored if `LDConfig.allUserAttributesPrivate` is true. Combined with `LDConfig.privateUserAttributes`. The SDK considers attributes appearing in either list as private. Client apps may define attributes found in `privatizableAttributes` and top level `custom` dictionary keys here. (Default: nil)

     See Also: `LDConfig.allUserAttributesPrivate` and `LDConfig.privateUserAttributes`.

    */
    public var privateAttributes: [String]?
    
    ///An NSObject wrapper for the Swift LDUser struct. Intended for use in mixed apps when Swift code needs to pass a user into an Objective-C method.
    public var objcLdUser: ObjcLDUser {
        return ObjcLDUser(self)
    }

    internal fileprivate(set) var lastUpdated: Date
    internal var flagStore: FlagMaintaining = FlagStore()
    
    /**
     Initializer to create a LDUser. Client configurable attributes each have an optional parameter to facilitate setting user information into the LDUser. The SDK will automatically set `key`, `device`, `operatingSystem`, and `isAnonymous` attributes if the client does not provide them. The SDK embeds `device` and `operatingSystem` into the `custom` dictionary for transmission to LaunchDarkly.

     - parameter key: String that uniquely identifies the user. If the client app does not define a key, the SDK will assign an identifier associated with the anonymous user.
     - parameter name: Client app defined name for the user. (Default: nil)
     - parameter firstName: Client app defined first name for the user. (Default: nil)
     - parameter lastName: Client app defined last name for the user. (Default: nil)
     - parameter country: Client app defined country for the user. (Default: nil)
     - parameter ipAddress: Client app defined ipAddress for the user. (Default: nil)
     - parameter email: Client app defined email address for the user. (Default: nil)
     - parameter avatar: Client app defined avatar for the user. (Default: nil)
     - parameter custom: Client app defined dictionary for the user. The client app may declare top level dictionary items as private. If the client app defines custom as private, the SDK considers the dictionary private except for device & operatingSystem (which cannot be made private). See `privateAttributes` for details. (Default: nil)
     - parameter isAnonymous: Client app defined isAnonymous for the user. If the client app does not define isAnonymous, the SDK will use the `key` to set this attribute. (Default: nil)
     - parameter device: Client app defined device for the user. The SDK will determine the device automatically, however the client app can override the value. The SDK will insert the device into the `custom` dictionary. (Default: nil)
     - parameter operatingSystem: Client app defined operatingSystem for the user. The SDK will determine the operatingSystem automatically, however the client app can override the value. The SDK will insert the operatingSystem into the `custom` dictionary. (Default: nil)
     - parameter privateAttributes: Client app defined privateAttributes for the user. (Default: nil)
     */
    public init(key: String? = nil,
                name: String? = nil,
                firstName: String? = nil,
                lastName: String? = nil,
                country: String? = nil,
                ipAddress: String? = nil,
                email: String? = nil,
                avatar: String? = nil,
                custom: [String: Any]? = nil,
                isAnonymous: Bool? = nil,
                device: String? = nil,
                operatingSystem: String? = nil,
                privateAttributes: [String]? = nil) {
        let environmentReporter = EnvironmentReporter()
        let selectedKey = key ?? LDUser.defaultKey(environmentReporter: environmentReporter)
        self.key = selectedKey
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.country = country
        self.ipAddress = ipAddress
        self.email = email
        self.avatar = avatar
        self.custom = custom
        self.isAnonymous = isAnonymous ?? (selectedKey == LDUser.defaultKey(environmentReporter: environmentReporter))
        self.device = device ?? custom?[CodingKeys.device.rawValue] as? String ?? environmentReporter.deviceModel
        self.operatingSystem = operatingSystem ?? custom?[CodingKeys.operatingSystem.rawValue] as? String ?? environmentReporter.systemVersion
        self.privateAttributes = privateAttributes
        lastUpdated = Date()
        Log.debug(typeName(and: #function) + "user: \(self)")
    }
    
    /**
     Failable Initializer that takes any object and attempts to create a LDUser from the object. If the object is a [String: Any], constructs the LDUser via `init(userDictionary:)`

     - parameter object: Any object. The initializer will attempt to convert the object into [String: Any] and construct the LDUser
    */
    public init?(object: Any?) {
        guard let userDictionary = object as? [String: Any]
        else {
            return nil
        }
        self = LDUser(userDictionary: userDictionary)
    }

    /**
     Initializer that takes a [String: Any] and creates a LDUser from the contents. Uses any keys present to define corresponding attribute values. Initializes attributes not present in the dictionary to their default value. Attempts to set `device` and `operatingSystem` from corresponding values embedded in `custom`. Attempts to set feature flags from values set in `config`.

     - parameter userDictionary: Dictionary with LDUser attribute keys and values.
     */
    public init(userDictionary: [String: Any]) {
        key = userDictionary[CodingKeys.key.rawValue] as? String ?? LDUser.defaultKey(environmentReporter: EnvironmentReporter())
        isAnonymous = userDictionary[CodingKeys.isAnonymous.rawValue] as? Bool ?? false
        lastUpdated = (userDictionary[CodingKeys.lastUpdated.rawValue] as? String)?.dateValue ?? Date()

        name = userDictionary[CodingKeys.name.rawValue] as? String
        firstName = userDictionary[CodingKeys.firstName.rawValue] as? String
        lastName = userDictionary[CodingKeys.lastName.rawValue] as? String
        country = userDictionary[CodingKeys.country.rawValue] as? String
        ipAddress = userDictionary[CodingKeys.ipAddress.rawValue] as? String
        email = userDictionary[CodingKeys.email.rawValue] as? String
        avatar = userDictionary[CodingKeys.avatar.rawValue] as? String
        privateAttributes = userDictionary[CodingKeys.privateAttributes.rawValue] as? [String]

        custom = userDictionary[CodingKeys.custom.rawValue] as? [String: Any]
        device = custom?[CodingKeys.device.rawValue] as? String
        operatingSystem = custom?[CodingKeys.operatingSystem.rawValue] as? String

        flagStore = FlagStore(featureFlagDictionary: userDictionary[CodingKeys.config.rawValue] as? [String: Any], flagValueSource: .cache)
        Log.debug(typeName(and: #function) + "user: \(self)")
    }

    /**
     Internal initializer that accepts an environment reporter, used for testing
    */
    init(environmentReporter: EnvironmentReporting) {
        self.init(key: LDUser.defaultKey(environmentReporter: environmentReporter), isAnonymous: true, device: environmentReporter.deviceModel, operatingSystem: environmentReporter.systemVersion)
    }

    //swiftlint:disable:next cyclomatic_complexity
    private func value(for attribute: String) -> Any? {
        switch attribute {
        case CodingKeys.key.rawValue: return key
        case CodingKeys.lastUpdated.rawValue: return lastUpdated
        case CodingKeys.isAnonymous.rawValue: return isAnonymous
        case CodingKeys.name.rawValue: return name
        case CodingKeys.firstName.rawValue: return firstName
        case CodingKeys.lastName.rawValue: return lastName
        case CodingKeys.country.rawValue: return country
        case CodingKeys.ipAddress.rawValue: return ipAddress
        case CodingKeys.email.rawValue: return email
        case CodingKeys.avatar.rawValue: return avatar
        case CodingKeys.custom.rawValue: return custom
        case CodingKeys.device.rawValue: return device
        case CodingKeys.operatingSystem.rawValue: return operatingSystem
        case CodingKeys.config.rawValue: return flagStore.featureFlags
        case CodingKeys.privateAttributes.rawValue: return privateAttributes
        default: return nil
        }
    }
    ///Returns the custom dictionary without the SDK set device and operatingSystem attributes
    var customWithoutSdkSetAttributes: [String: Any]? {
        return custom?.filter { (key, _) in
            !LDUser.sdkSetAttributes.contains(key)
        }
    }

    ///Dictionary with LDUser attribute keys and values, with options to include feature flags and private attributes. LDConfig object used to help resolving what attributes should be private.
    /// - parameter includeFlagConfig: Controls whether the resulting dictionary includes feature flags under the `config` key
    /// - parameter includePrivateAttributes: Controls whether the resulting dictionary includes private attributes
    /// - parameter config: Provides supporting information for defining private attributes
    func dictionaryValue(includeFlagConfig: Bool, includePrivateAttributes includePrivate: Bool, config: LDConfig) -> [String: Any] {
        var dictionary = [String: Any]()
        var redactedAttributes = [String]()
        let combinedPrivateAttributes = config.allUserAttributesPrivate ? LDUser.privatizableAttributes
            : (privateAttributes ?? []) + (config.privateUserAttributes ?? [])

        dictionary[CodingKeys.key.rawValue] = key

        let optionalAttributes = LDUser.privatizableAttributes.filter { (attribute) in
            attribute != CodingKeys.custom.rawValue
        }
        optionalAttributes.forEach { (attribute) in
            let value = self.value(for: attribute)
            if !includePrivate && combinedPrivateAttributes.isPrivate(attribute) && value != nil {
                redactedAttributes.append(attribute)
            } else {
                dictionary[attribute] = value
            }
        }

        var customDictionary = [String: Any]()
        if !includePrivate && combinedPrivateAttributes.isPrivate(CodingKeys.custom.rawValue) && !customWithoutSdkSetAttributes.isNilOrEmpty {
            redactedAttributes.append(CodingKeys.custom.rawValue)
        } else {
            if let custom = customWithoutSdkSetAttributes, !custom.isEmpty {
                custom.keys.forEach { (customAttribute) in
                    if !includePrivate && combinedPrivateAttributes.isPrivate(customAttribute) && custom[customAttribute] != nil {
                        redactedAttributes.append(customAttribute)
                    } else {
                        customDictionary[customAttribute] = custom[customAttribute]
                    }
                }
            }
        }
        customDictionary[CodingKeys.device.rawValue] = device
        customDictionary[CodingKeys.operatingSystem.rawValue] = operatingSystem
        dictionary[CodingKeys.custom.rawValue] = customDictionary.isEmpty ? nil : customDictionary

        if !includePrivate && !redactedAttributes.isEmpty {
            let redactedAttributeSet: Set<String> = Set(redactedAttributes)
            dictionary[CodingKeys.privateAttributes.rawValue] = redactedAttributeSet.sorted()
        }

        dictionary[CodingKeys.isAnonymous.rawValue] = isAnonymous
        dictionary[CodingKeys.lastUpdated.rawValue] = DateFormatter.ldDateFormatter.string(from: lastUpdated)

        if includeFlagConfig {
            dictionary[CodingKeys.config.rawValue] = flagStore.featureFlags
        }

        return dictionary
    }

    ///Default key is the LDUser.key the SDK provides when any intializer is called without defining the key. The key should be constant with respect to the client app installation on a specific device. (The key may change if the client app is uninstalled and then reinstalled on the same device.)
    ///- parameter environmentReporter: The environmentReporter provides selected information that varies between OS regarding how it's determined
    static func defaultKey(environmentReporter: EnvironmentReporting) -> String {
        //For iOS & tvOS, this should be UIDevice.current.identifierForVendor.UUIDString
        //For macOS & watchOS, this should be a UUID that the sdk creates and stores so that the value returned here should be always the same
        return environmentReporter.vendorUUID ?? UserDefaults.standard.installationKey
    }
}

extension UserDefaults {
    struct Keys {
        fileprivate static let deviceIdentifier = "ldDeviceIdentifier"
    }

    fileprivate var installationKey: String {
        if let key = self.string(forKey: Keys.deviceIdentifier) {
            return key
        }

        let key = UUID().uuidString
        self.set(key, forKey: Keys.deviceIdentifier)
        return key
    }
}

extension LDUser: Equatable {
    ///Compares users by comparing their user keys only, to allow the client app to collect user information over time
    public static func == (lhs: LDUser, rhs: LDUser) -> Bool {
        return lhs.key == rhs.key
    }
}

extension DateFormatter {
    ///Date formatter configured to format dates to/from the format 2018-08-13T19:06:38.123Z
    class var ldDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}

extension Date {
    ///Date string using the format 2018-08-13T19:06:38.123Z
    var stringValue: String {
        return DateFormatter.ldDateFormatter.string(from: self)
    }

    //When a date is converted to JSON, the resulting string is not as precise as the original date (only to the nearest .001s)
    //By converting the date to json, then back into a date, the result can be compared with any date re-inflated from json
    ///Date truncated to the nearest millisecond, which is the precision for string formatted dates
    var stringEquivalentDate: Date {
        return stringValue.dateValue
    }
}

extension String {
    ///Date converted from a string using the format 2018-08-13T19:06:38.123Z
    var dateValue: Date {
        return DateFormatter.ldDateFormatter.date(from: self) ?? Date()
    }
}

extension Array where Element == String {
    fileprivate func isPrivate(_ attribute: String) -> Bool {
        return contains(attribute)
    }
}

///Class providing ObjC interoperability with the LDUser struct
@objc final class LDUserWrapper: NSObject {
    let wrapped: LDUser

    init(user: LDUser) {
        wrapped = user
        super.init()
    }
}

extension LDUserWrapper: NSCoding {
    struct Keys {
        fileprivate static let featureFlags = "featuresJsonDictionary"
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(wrapped.key, forKey: LDUser.CodingKeys.key.rawValue)
        encoder.encode(wrapped.name, forKey: LDUser.CodingKeys.name.rawValue)
        encoder.encode(wrapped.firstName, forKey: LDUser.CodingKeys.firstName.rawValue)
        encoder.encode(wrapped.lastName, forKey: LDUser.CodingKeys.lastName.rawValue)
        encoder.encode(wrapped.country, forKey: LDUser.CodingKeys.country.rawValue)
        encoder.encode(wrapped.ipAddress, forKey: LDUser.CodingKeys.ipAddress.rawValue)
        encoder.encode(wrapped.email, forKey: LDUser.CodingKeys.email.rawValue)
        encoder.encode(wrapped.avatar, forKey: LDUser.CodingKeys.avatar.rawValue)
        encoder.encode(wrapped.custom, forKey: LDUser.CodingKeys.custom.rawValue)
        encoder.encode(wrapped.isAnonymous, forKey: LDUser.CodingKeys.isAnonymous.rawValue)
        encoder.encode(wrapped.device, forKey: LDUser.CodingKeys.device.rawValue)
        encoder.encode(wrapped.operatingSystem, forKey: LDUser.CodingKeys.operatingSystem.rawValue)
        encoder.encode(wrapped.lastUpdated, forKey: LDUser.CodingKeys.lastUpdated.rawValue)
        encoder.encode(wrapped.privateAttributes, forKey: LDUser.CodingKeys.privateAttributes.rawValue)
        encoder.encode([Keys.featureFlags: wrapped.flagStore.featureFlags.dictionaryValue.withNullValuesRemoved], forKey: LDUser.CodingKeys.config.rawValue)
    }

    convenience init?(coder decoder: NSCoder) {
        var user = LDUser(key: decoder.decodeObject(forKey: LDUser.CodingKeys.key.rawValue) as? String,
                          name: decoder.decodeObject(forKey: LDUser.CodingKeys.name.rawValue) as? String,
                          firstName: decoder.decodeObject(forKey: LDUser.CodingKeys.firstName.rawValue) as? String,
                          lastName: decoder.decodeObject(forKey: LDUser.CodingKeys.lastName.rawValue) as? String,
                          country: decoder.decodeObject(forKey: LDUser.CodingKeys.country.rawValue) as? String,
                          ipAddress: decoder.decodeObject(forKey: LDUser.CodingKeys.ipAddress.rawValue) as? String,
                          email: decoder.decodeObject(forKey: LDUser.CodingKeys.email.rawValue) as? String,
                          avatar: decoder.decodeObject(forKey: LDUser.CodingKeys.avatar.rawValue) as? String,
                          custom: decoder.decodeObject(forKey: LDUser.CodingKeys.custom.rawValue) as? [String: Any],
                          isAnonymous: decoder.decodeBool(forKey: LDUser.CodingKeys.isAnonymous.rawValue),
                          privateAttributes: decoder.decodeObject(forKey: LDUser.CodingKeys.privateAttributes.rawValue) as? [String]
        )
        user.device = decoder.decodeObject(forKey: LDUser.CodingKeys.device.rawValue) as? String
        user.operatingSystem = decoder.decodeObject(forKey: LDUser.CodingKeys.operatingSystem.rawValue) as? String
        user.lastUpdated = decoder.decodeObject(forKey: LDUser.CodingKeys.lastUpdated.rawValue) as? Date ?? Date()
        let wrappedFlags = decoder.decodeObject(forKey: LDUser.CodingKeys.config.rawValue) as? [String: Any]
        user.flagStore = FlagStore(featureFlagDictionary: wrappedFlags?[Keys.featureFlags] as? [String: Any], flagValueSource: .cache)
        self.init(user: user)
    }

    ///Method to configure NSKeyed(Un)Archivers to convert version 2.3.0 and older user caches to 2.3.1 and later user cache formats. Note that the v3 SDK no longer caches LDUsers, rather only feature flags and the LDUser.key are cached.
    class func configureKeyedArchiversToHandleVersion2_3_0AndOlderUserCacheFormat() {
        NSKeyedUnarchiver.setClass(LDUserWrapper.self, forClassName: "LDUserModel")
        NSKeyedArchiver.setClassName("LDUserModel", for: LDUserWrapper.self)
    }
}

extension LDUser: TypeIdentifying { }

#if DEBUG
    extension LDUser {
        ///Testing method to get the user attribute value from a LDUser struct
        func value(forAttribute attribute: String) -> Any? {
            return value(for: attribute)
        }

        //Compares all user properties except lastUpdated. Excludes the composed FlagStore, which contains the users feature flags
        func isEqual(to otherUser: LDUser) -> Bool {
            return key == otherUser.key
                && name == otherUser.name
                && firstName == otherUser.firstName
                && lastName == otherUser.lastName
                && country == otherUser.country
                && ipAddress == otherUser.ipAddress
                && email == otherUser.email
                && avatar == otherUser.avatar
                && AnyComparer.isEqual(custom, to: otherUser.custom)
                && isAnonymous == otherUser.isAnonymous
                && device == otherUser.device
                && operatingSystem == otherUser.operatingSystem
                && AnyComparer.isEqual(privateAttributes, to: otherUser.privateAttributes)
        }
    }
#endif
