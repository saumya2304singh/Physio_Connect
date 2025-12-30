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

// MARK: - List DTO with specialization join
struct PhysioListRow: Decodable {
    let id: UUID
    let name: String
    let consultation_fee: Double?
    let latitude: Double?
    let longitude: Double?
    let avg_rating: Double?
    let reviews_count: Int?
    let years_experience: Int?
    let patients_served: Int?

    let physio_specializations: [PhysioSpecJoin]?

    struct PhysioSpecJoin: Decodable {
        let specializations: Specialization?
        struct Specialization: Decodable {
            let name: String
        }
    }
}


    
    

extension PhysioService {

    func fetchPhysiotherapist(by id: UUID) async throws -> Physiotherapist {
        let rows: [Physiotherapist] = try await client
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
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        guard let first = rows.first else { throw NSError(domain: "PhysioService", code: 404) }
        return first
    }
    
    func fetchPhysiotherapistsForList() async throws -> [PhysioListRow] {
        try await client
            .from("physiotherapists")
            .select("""
                id,
                name,
                consultation_fee,
                latitude,
                longitude,
                avg_rating,
                reviews_count,
                years_experience,
                patients_served,
                physio_specializations(
                    specializations(name)
                )
            """)
            .execute()
            .value
    }


    /// physio_specializations -> embedded specializations(name)
    func fetchSpecializationNames(for physioID: UUID) async throws -> [String] {
        let rows: [PhysioSpecializationRow] = try await client
            .from("physio_specializations")
            .select("physio_id, specializations(name)")
            .eq("physio_id", value: physioID.uuidString)
            .execute()
            .value

        return rows.compactMap { $0.specializations?.name }
    }

    func fetchReviews(for physioID: UUID, limit: Int = 3) async throws -> [PhysioReviewRow] {
        try await client
            .from("physio_reviews")
            .select("id, physio_id, reviewer_name, rating, review_text, created_at")
            .eq("physio_id", value: physioID.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}

