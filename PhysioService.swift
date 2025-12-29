//
//  PhysioService.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 29/12/25.
//
import Foundation
import Supabase

final class PhysioService {
    private let client = SupabaseManager.shared.client

    func fetchPhysiotherapists() async throws -> [Physiotherapist] {
        let data: [Physiotherapist] = try await client
            .from("physiotherapists")
            .select("id,name,gender,consultation_fee,avg_rating,location_text")
            .order("avg_rating", ascending: false)
            .execute()
            .value
        return data
    }
}

