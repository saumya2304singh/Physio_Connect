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
            let profile_image_path: String?
        }

        let rows: [Row] = try await client
            .from("physiotherapists")
            .select("id,name,email,gender,location_text,place_of_work,profile_image_path")
            .eq("id", value: userID)
            .limit(1)
            .execute()
            .value

        let row = rows.first
        return ProfileViewData(
            name: row?.name ?? "Physiotherapist",
            email: row?.email ?? (session.user.email ?? "—"),
            phone: row?.place_of_work ?? "—",
            address: row?.location_text ?? "—",
            gender: row?.gender ?? "—",
            dateOfBirth: "—",
            healthIdentifier: "—",
            location: row?.location_text ?? "—",
            notificationsEnabled: true,
            avatarURL: row?.profile_image_path
        )
    }
}
