//
//  VideosModel.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import Foundation
import Supabase

struct ExerciseVideoRow: Decodable {
    let id: UUID
    let physio_id: UUID?
    let video_path: String
    let title: String
    let description: String?
    let duration_seconds: Int?
    let thumbnail_path: String?
    let target_area: String?
    let purpose: String?
    let difficulty: String?
    let is_free: Bool
    let is_active: Bool
    let access_type: String?
}

struct MyProgramExerciseRow: Decodable {
    let exercise_id: UUID
    let title: String
    let target_area: String?
    let purpose: String?
    let description: String?
    let duration_seconds: Int?
    let difficulty: String?
    let thumbnail_path: String?
    let video_path: String
    let sets: Int?
    let reps: Int?
    let hold_seconds: Int?
    let notes: String?
    let sort_order: Int?
    let program_id: UUID
    let program_title: String
}

struct ExerciseProgressUpsert: Encodable {
    let customer_id: UUID
    let exercise_id: UUID
    let program_id: UUID?
    let progress_date: String
    let is_completed: Bool
    let watched_seconds: Int
    let pain_level: Int?
    let notes: String?
}

final class VideosModel {
    private let client = SupabaseManager.shared.client

    private let videoBucket = "exercise_videos"
    private let thumbnailBucket = "exercise_thumbnails"

    func fetchFreeExercises(search: String?) async throws -> [ExerciseVideoRow] {
        var query = client
            .from("physio_videos")
            .select("*")
            .eq("is_free", value: true)
            .eq("is_active", value: true)

        if let search = search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query = query.ilike("title", pattern: "%\(search)%")
        }

        let rows: [ExerciseVideoRow] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows
    }

    func fetchMyProgramExercises() async throws -> [MyProgramExerciseRow] {
        let rows: [MyProgramExerciseRow] = try await client
            .rpc("get_my_program_exercises")
            .execute()
            .value
        return rows
    }

    func redeemProgram(code: String) async throws -> UUID {
        struct Args: Encodable { let p_code: String }
        let response: UUID = try await client
            .rpc("redeem_program_code", params: Args(p_code: code))
            .execute()
            .value
        return response
    }

    func signedVideoURL(path: String) async throws -> URL {
        let normalized = path.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return try await client.storage
            .from(videoBucket)
            .createSignedURL(path: normalized, expiresIn: 3600)
    }

    func signedThumbnailURL(path: String) async throws -> URL {
        let normalized = path.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return try await client.storage
            .from(thumbnailBucket)
            .createSignedURL(path: normalized, expiresIn: 3600)
    }

    func upsertProgress(exerciseID: UUID,
                        programID: UUID?,
                        isCompleted: Bool,
                        watchedSeconds: Int,
                        painLevel: Int?,
                        notes: String?) async throws {
        let session = try await client.auth.session
        let customerID = session.user.id

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())

        let payload = ExerciseProgressUpsert(
            customer_id: customerID,
            exercise_id: exerciseID,
            program_id: programID,
            progress_date: today,
            is_completed: isCompleted,
            watched_seconds: watchedSeconds,
            pain_level: painLevel,
            notes: notes
        )

        _ = try await client
            .from("exercise_progress")
            .upsert(payload, onConflict: "customer_id,exercise_id,progress_date")
            .execute()
    }
}
