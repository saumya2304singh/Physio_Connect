//
//  PhysioAuthModel.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import Foundation
import Supabase

struct PhysioAuthModel {
    private let client = SupabaseManager.shared.client
    
    struct PhysioAuthError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    struct PhysioSignupInput {
        let name: String
        let email: String
        let password: String
    }

    func login(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(email: email, password: password)
        let user = session.user

        // Ensure physiotherapist profile exists; otherwise block login
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = try await client
            .from("physiotherapists")
            .select("id")
            .eq("id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value

        let customerRows: [Row] = (try? await client
            .from("customers")
            .select("id")
            .eq("id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value) ?? []

        guard rows.first != nil else {
            // No physio record => sign out and reject login
            try? await client.auth.signOut()
            throw PhysioAuthError(message: "No physiotherapist account found for this email.")
        }

        if customerRows.first != nil {
            try? await client.auth.signOut()
            throw PhysioAuthError(message: "This account is registered as a patient. Please log in on the user side.")
        }

        return user
    }

    func signup(input: PhysioSignupInput) async throws -> User {
        let result = try await client.auth.signUp(email: input.email, password: input.password)
        let user = result.user

        // Best effort: create/update physiotherapist profile row if schema supports it.
        try? await upsertPhysioProfile(userID: user.id, name: input.name, email: input.email)
        _ = try await client.auth.signIn(email: input.email, password: input.password)
        return user
    }

    private func upsertPhysioProfile(userID: UUID, name: String, email: String) async throws {
        struct PhysioUpsert: Encodable {
            let id: UUID
            let name: String
            let email: String
            let updated_at: String
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let payload = PhysioUpsert(
            id: userID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.lowercased(),
            updated_at: formatter.string(from: Date())
        )

        _ = try await client
            .from("physiotherapists")
            .upsert(payload, onConflict: "id")
            .execute()
    }
}
