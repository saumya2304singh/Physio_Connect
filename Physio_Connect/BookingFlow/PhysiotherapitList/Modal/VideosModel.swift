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

struct ExerciseProgressRow: Decodable {
    let exercise_id: UUID
    let program_id: UUID?
    let progress_date: String?
    let is_completed: Bool?
    let watched_seconds: Int?
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
        return try await signedURL(path: path, bucket: videoBucket)
    }

    func signedThumbnailURL(path: String) async throws -> URL {
        return try await signedURL(path: path, bucket: thumbnailBucket)
    }

    private func signedURL(path: String, bucket: String) async throws -> URL {
        let trimmed = path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { throw URLError(.badURL) }

        if let direct = URL(string: trimmed), direct.scheme?.hasPrefix("http") == true {
            return direct
        }

        var lastError: Error?
        let candidates = candidateKeys(for: trimmed, bucket: bucket)
        for key in candidates {
            do {
                return try await client.storage
                    .from(bucket)
                    .createSignedURL(path: key, expiresIn: 3600)
            } catch {
                lastError = error
                if let publicURL = makePublicURL(bucket: bucket, key: key) {
                    print("ℹ️ Falling back to public URL for bucket \(bucket), key \(key): \(error)")
                    return publicURL
                }
            }
        }
        print("❌ All candidate keys failed for bucket \(bucket) from raw path '\(path)': \(candidates)")
        throw lastError ?? URLError(.fileDoesNotExist)
    }

    private func candidateKeys(for raw: String, bucket: String) -> [String] {
        var cleaned = raw
        if let qIndex = cleaned.firstIndex(of: "?") {
            cleaned = String(cleaned[..<qIndex])
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        var keys: [String] = []
        let publicPrefix = "storage/v1/object/public/\(bucket)/"
        if let range = cleaned.range(of: publicPrefix) {
            keys.append(String(cleaned[range.upperBound...]))
        } else if cleaned.hasPrefix("\(bucket)/") {
            keys.append(String(cleaned.dropFirst(bucket.count + 1)))
        }
        keys.append(cleaned)
        keys.append("\(bucket)/\(cleaned)")

        var seen = Set<String>()
        let unique = keys.filter { key in
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
        return unique
    }

    private func supabaseBaseURL() -> String? {
        if let base = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String {
            return base
        }
        return SupabaseConfig.url
    }

    private func makePublicURL(bucket: String, key: String) -> URL? {
        guard let base = supabaseBaseURL() else { return nil }
        let path = key.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let encodedPath = path
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "\(base)/storage/v1/object/public/\(bucket)/\(encodedPath)")
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

    func fetchProgress(programID: UUID) async throws -> [ExerciseProgressRow] {
        let session = try await client.auth.session
        let customerID = session.user.id.uuidString

        let rows: [ExerciseProgressRow] = try await client
            .from("exercise_progress")
            .select("exercise_id, program_id, progress_date, is_completed, watched_seconds, pain_level, notes")
            .eq("customer_id", value: customerID)
            .eq("program_id", value: programID.uuidString)
            .execute()
            .value
        return rows
    }

    func fetchProgressForExercise(exerciseID: UUID, programID: UUID?) async throws -> ExerciseProgressRow? {
        let session = try await client.auth.session
        let customerID = session.user.id.uuidString

        var query = client
            .from("exercise_progress")
            .select("exercise_id, program_id, progress_date, is_completed, watched_seconds, pain_level, notes")
            .eq("customer_id", value: customerID)
            .eq("exercise_id", value: exerciseID.uuidString)

        if let programID {
            query = query.eq("program_id", value: programID.uuidString)
        }

        let rows: [ExerciseProgressRow] = try await query
            .order("progress_date", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}
