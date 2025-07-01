//
//  TipSelectionView.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/29/25.
//

import SwiftUI
import StoreKit

struct TipSelectionView: View {
    @StateObject private var storeManager = TipStoreManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingCustomAmount = false
    @State private var customAmount = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Text("☕️")
                            .font(.system(size: 40))
                        
                        Text("Buy me a coffee!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your support helps keep this app running and caffeine flowing.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
                
                if storeManager.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading tip options...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                } else {
                    Section("Tip Options") {
                        ForEach(storeManager.products, id: \.id) { product in
                            Button {
                                Task {
                                    await storeManager.purchase(product)
                                }
                            } label: {
                                HStack {
                                    Text(storeManager.displayName(for: product))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(product.displayPrice)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                }
                            }
                            .disabled(storeManager.isLoading)
                        }
                    }
                }
                
                if let error = storeManager.purchaseError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Support the App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Custom Tip Amount", isPresented: $showingCustomAmount) {
                TextField("Amount (USD)", text: $customAmount)
                    .keyboardType(.decimalPad)
                
                Button("Cancel", role: .cancel) {
                    customAmount = ""
                }
                
                Button("Continue") {
                    handleCustomAmount()
                }
                .disabled(customAmount.isEmpty || Double(customAmount) == nil)
            } message: {
                Text("Enter a custom tip amount in USD. Note: Custom amounts may require additional verification.")
            }
            .onAppear {
                if storeManager.purchaseError != nil {
                    storeManager.clearError()
                }
            }
        }
    }
    
    private func handleCustomAmount() {
        guard let amount = Double(customAmount), amount > 0 else {
            storeManager.setError("Please enter a valid amount")
            return
        }
        
        // For custom amounts, we'd typically need a server-side implementation
        // or use StoreKit's consumable products with dynamic pricing
        storeManager.setError("Custom amounts are not yet supported. Please choose from the preset options.")
        
        customAmount = ""
    }
}

#Preview {
    TipSelectionView()
}
