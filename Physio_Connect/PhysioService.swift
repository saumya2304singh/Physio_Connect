//
//  PhysioService.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 29/12/25.

import Foundation
import Supabase

final class PhysioService {
    static let shared = PhysioService()
    private init() {}

    private let client = SupabaseManager.shared.client

    func fetchPhysiotherapists() async throws -> [Physiotherapist] {
        try await client
            .from("physiotherapists")
            .select("""
                id,
                name,
                gender,
                about,
                years_experience,
                place_of_work,
                consultation_fee,
                latitude,
                longitude,
                location_text,
                patients_served,
                avg_rating,
                reviews_count,
                created_at,
                updated_at
            """)
            .execute()
            .value
    }
}


