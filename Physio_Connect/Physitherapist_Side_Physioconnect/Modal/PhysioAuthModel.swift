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

    struct PhysioSignupInput {
        let name: String
        let email: String
        let password: String
    }

    func login(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user
    }

    func signup(input: PhysioSignupInput) async throws -> User {
        let result = try await client.auth.signUp(email: input.email, password: input.password)
        let user = result.user

        // Best effort: create/update physiotherapist profile row if schema supports it.
        try? await upsertPhysioProfile(userID: user.id, name: input.name, email: input.email)
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
