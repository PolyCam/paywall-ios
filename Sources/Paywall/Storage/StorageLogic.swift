//
//  StoreLogic.swift
//  Paywall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation

enum StorageLogic {
  enum IdentifyOutcome {
    case reset
    case loadAssignments
  }

  static func generateAlias() -> String {
    return "$SuperwallAlias:\(UUID().uuidString)"
  }

  static func mergeAttributes(
    _ newAttributes: [String: Any],
    with oldAttributes: [String: Any]
  ) -> [String: Any] {
    var mergedAttributes = oldAttributes

    for key in newAttributes.keys {
      if key == "$is_standard_event" {
        continue
      }
      if key == "$application_installed_at" {
        continue
      }

      var key = key

      if key.starts(with: "$") { // replace dollar signs
        key = key.replacingOccurrences(of: "$", with: "")
      }

      if let value = newAttributes[key] {
        mergedAttributes[key] = value
      } else {
        mergedAttributes[key] = nil
      }
    }

    // we want camel case
    mergedAttributes["applicationInstalledAt"] = DeviceHelper.shared.appInstalledAtString

    return mergedAttributes
  }

  static func identify(
    newUserId: String?,
    oldUserId: String?
  ) -> IdentifyOutcome? {
    let hasNewUserId = newUserId != nil
    let hasOldUserId = oldUserId != nil

    if hasNewUserId,
      hasOldUserId {
      if newUserId == oldUserId {
        return nil
      } else {
        return .reset
      }
    }

    if newUserId == nil {
      // this can only happen from a configure call that doesn't pass
      // in an app user id if the dev calls identify later in the app
      // lifecycle, oldUserId will be set
      return nil
    }

    return .loadAssignments
  }
}
