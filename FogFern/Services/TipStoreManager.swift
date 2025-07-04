//
//  TipStoreManager.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/29/25.
//

import StoreKit
import SwiftUI

// Error for verification failures
enum VerificationError: Error {
    case unverified
}

@MainActor
class TipStoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseError: String?
    
    private let productIdentifiers = [
        "com.kyleolivo.FogFern.tip.small",
        "com.kyleolivo.FogFern.tip.medium", 
        "com.kyleolivo.FogFern.tip.large"
    ]
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    func loadProducts() async {
        isLoading = true
        purchaseError = nil
        
        do {
            print("Loading products with identifiers: \(productIdentifiers)")
            let products = try await Product.products(for: productIdentifiers)
            print("Loaded \(products.count) products")
            
            if products.isEmpty {
                purchaseError = "No tip options available. Please check your internet connection and try again."
            } else {
                self.products = products.sorted { product1, product2 in
                    // Sort by price: small, medium, large
                    let price1 = product1.price
                    let price2 = product2.price
                    if price1 != price2 {
                        return price1 < price2
                    }
                    return product1.id < product2.id
                }
                print("Products sorted successfully")
            }
        } catch {
            print("Error loading products: \(error)")
            purchaseError = "Failed to load tip options: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                do {
                    let transaction = try checkVerified(verification)
                    // Successfully purchased - tip transactions are consumable so just finish them
                    await transaction.finish()
                } catch {
                    purchaseError = "Purchase could not be verified"
                }
            case .userCancelled:
                // User cancelled, no action needed
                break
            case .pending:
                purchaseError = "Purchase is pending approval"
            @unknown default:
                purchaseError = "Unknown purchase result"
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }
    
    func displayName(for product: Product) -> String {
        switch product.id {
        case "com.kyleolivo.FogFern.tip.small":
            return "💚 Small Tip"
        case "com.kyleolivo.FogFern.tip.medium":
            return "🌿 Medium Tip"
        case "com.kyleolivo.FogFern.tip.large":
            return "🌲 Large Tip"
        default:
            return product.displayName
        }
    }
    
    func setError(_ message: String) {
        purchaseError = message
    }
    
    func clearError() {
        purchaseError = nil
    }
    
    // MARK: - Transaction Monitoring
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            // Iterate through any transactions that didn't come from a direct call to `purchase()`
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    await transaction?.finish()
                } catch {
                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw VerificationError.unverified
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
}
