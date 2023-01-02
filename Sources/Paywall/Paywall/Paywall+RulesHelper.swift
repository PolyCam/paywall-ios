//
//  Paywall+RulesHelper.swift
//
//
//  Created by Bryan Dubno on 11/20/22.
//

import UIKit

public extension Paywall {
    static func meetsRequirements(event: String, isUserSubscribed: Bool) -> PaywallInfo? {
        let trackableEvent = UserInitiatedEvent.Track(
            rawName: event,
            canImplicitlyTriggerPaywall: false,
            customParameters: [:]
        )

        let result = Paywall.track(trackableEvent)
        let eventData = result.data

        let presentationInfo: PresentationInfo = .explicitTrigger(eventData)

        let triggerOutcome = PaywallResponseLogic.getTriggerResultAndConfirmAssignment(
          presentationInfo: presentationInfo,
          triggers: ConfigManager.shared.triggers
        )

        let identifiers: ResponseIdentifiers? = {
            switch triggerOutcome.info {
                case .paywall(let responseIdentifiers):
                    return responseIdentifiers
                default:
                    return nil
            }
        }()

        guard let identifiers = identifiers else {
            return nil
        }

        let paywallId = identifiers.paywallId
        let canDisplayPaywall = !InternalPresentationLogic.shouldNotDisplayPaywall(
            isUserSubscribed: isUserSubscribed,
            isDebuggerLaunched: false,
            shouldIgnoreSubscriptionStatus: false
        )

        guard canDisplayPaywall else {
            return nil
        }

        guard var paywallResponse = ConfigManager.shared.getStaticPaywallResponse(
            forPaywallId: paywallId
        ) else {
            print("WARNING: Meets requirements, but no static Paywall response has been cached.")
            return nil
        }
        paywallResponse.experiment = identifiers.experiment
        
        return paywallResponse.getPaywallInfo(fromEvent: eventData)
    }
}
