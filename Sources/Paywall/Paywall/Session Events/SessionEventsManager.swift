//
//  File.swift
//  
//
//  Created by Yusuf Tör on 27/05/2022.
//

import Foundation

protocol SessionEventsDelegate: AnyObject {
  var triggerSession: TriggerSessionManager { get }

  func enqueue(_ triggerSession: TriggerSession)
  func enqueue(_ triggerSessions: [TriggerSession])
  func enqueue(_ transaction: TransactionModel)
}

final class SessionEventsManager {
  /// The shared instance of the class
  static let shared = SessionEventsManager()

  /// The trigger session manager.
  lazy var triggerSession = TriggerSessionManager(delegate: self)

  /// The transaction manager.
  lazy var transactions = TransactionManager(delegate: self)

  /// A queue of trigger session events that get sent to the server.
  private let queue: SessionEventsQueue

  /// Network class. Can be injected via init for testing.
  private let network: Network

  /// Storage class. Can be injected via init for testing.
  private let storage: Storage

  /// Storage class. Can be injected via init for testing.
  private let configManager: ConfigManager

  /// Only instantiate this if you're testing. Otherwise use `SessionEvents.shared`.
  init(
    queue: SessionEventsQueue = SessionEventsQueue(),
    storage: Storage = .shared,
    network: Network = .shared,
    configManager: ConfigManager = .shared
  ) {
    self.queue = queue
    self.storage = storage
    self.network = network
    self.configManager = configManager

    postCachedSessionEvents()
  }

  /// Gets the last 20 cached trigger sessions and transactions from the last time the app was terminated,
  /// sends them back to the server, then clears cache.
  private func postCachedSessionEvents() {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    let cachedTriggerSessions = storage.getCachedTriggerSessions()
    let cachedTransactions = storage.getCachedTransactions()

    if cachedTriggerSessions.isEmpty,
      cachedTransactions.isEmpty {
      return
    }

    let sessionEvents = SessionEventsRequest(
      triggerSessions: cachedTriggerSessions,
      transactions: cachedTransactions
    )
    network.sendSessionEvents(sessionEvents)
    storage.clearCachedSessionEvents()
  }

  /// This only updates the app session in the trigger sessions.
  /// For transactions, the latest app session id is grabbed when the next transaction occurs.
  func updateAppSession(
    _ appSession: AppSession = AppSessionManager.shared.appSession
  ) {
    triggerSession.updateAppSession(to: appSession)
  }
}

// MARK: - SessionEventsDelegate
extension SessionEventsManager: SessionEventsDelegate {
  func enqueue(_ triggerSession: TriggerSession) {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    queue.enqueue(triggerSession)
  }

  func enqueue(_ triggerSessions: [TriggerSession]) {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    queue.enqueue(triggerSessions)
  }

  func enqueue(_ transaction: TransactionModel) {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    queue.enqueue(transaction)
  }
}
