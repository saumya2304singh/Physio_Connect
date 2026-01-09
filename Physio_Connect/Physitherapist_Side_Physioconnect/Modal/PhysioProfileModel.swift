//
//  PhysioProfileModel.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import Foundation
import Supabase

struct PhysioProfileModel {
    private let client = SupabaseManager.shared.client

    struct UpdateInput {
        let name: String
        let gender: String
        let location: String
        let placeOfWork: String
        let phone: String
        let dateOfBirth: String
        let profileImagePath: String
    }

    func fetchProfile() async throws -> ProfileViewData {
        let session = try await client.auth.session
        let userID = session.user.id.uuidString

        struct Row: Decodable {
            let id: UUID
            let name: String?
            let email: String?
            let gender: String?
            let location_text: String?
            let place_of_work: String?
            let phone: String?
            let date_of_birth: String?
            let profile_image_path: String?
        }

        let rows: [Row] = try await client
            .from("physiotherapists")
            .select("id,name,email,gender,location_text,place_of_work,phone,date_of_birth,profile_image_path")
            .eq("id", value: userID)
            .limit(1)
            .execute()
            .value

        let row = rows.first
        return ProfileViewData(
            name: row?.name ?? "Physiotherapist",
            email: row?.email ?? (session.user.email ?? "—"),
            phone: row?.phone ?? row?.place_of_work ?? "—",
            address: row?.location_text ?? "—",
            gender: row?.gender ?? "—",
            dateOfBirth: row?.date_of_birth ?? "—",
            healthIdentifier: "—",
            location: row?.location_text ?? "—",
            notificationsEnabled: true,
            avatarURL: row?.profile_image_path
        )
    }

    func updateProfile(_ input: UpdateInput) async throws {
        let session = try await client.auth.session
        let userID = session.user.id.uuidString

        struct Payload: Encodable {
            let id: UUID
            let name: String?
            let email: String?
            let gender: String?
            let location_text: String?
            let place_of_work: String?
            let phone: String?
            let date_of_birth: String?
            let profile_image_path: String?
            let updated_at: String
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let payload = Payload(
            id: UUID(uuidString: userID) ?? UUID(),
            name: input.name.trimmedOrNil,
            email: session.user.email,
            gender: input.gender.trimmedOrNil?.lowercased(),
            location_text: input.location.trimmedOrNil,
            place_of_work: input.placeOfWork.trimmedOrNil,
            phone: input.phone.trimmedOrNil,
            date_of_birth: input.dateOfBirth.trimmedOrNil,
            profile_image_path: input.profileImagePath.trimmedOrNil,
            updated_at: formatter.string(from: Date())
        )

        _ = try await client
            .from("physiotherapists")
            .upsert(payload, onConflict: "id")
            .execute()
    }
}

private extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
