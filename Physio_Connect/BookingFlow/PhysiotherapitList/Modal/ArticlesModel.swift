//
//  ArticlesModel.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import Foundation
import Supabase

struct ArticleRow: Decodable {
    let id: UUID
    let title: String
    let summary: String?
    let content: String?
    let source_name: String?
    let source_url: String?
    let image_url: String?
    let image_path: String?
    let published_at: String?
    let rating: Double?
    let views_count: Int?
    let read_minutes: Int?
    let is_trending: Bool?
    let tags: [String]?
}

enum ArticleSort {
    case recent
    case topRated
    case forYou
}

final class ArticlesModel {
    private let client = SupabaseManager.shared.client
    private let imageBucket = "article_images"

    func signedImageURL(pathOrUrl: String) async throws -> URL {
        if let url = URL(string: pathOrUrl), url.scheme?.hasPrefix("http") == true {
            return url
        }
        let normalized = normalizeImagePath(pathOrUrl)
        do {
            return try await client.storage
                .from(imageBucket)
                .createSignedURL(path: normalized, expiresIn: 3600)
        } catch {
            if let base = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
               let url = URL(string: "\(base)/storage/v1/object/public/\(imageBucket)/\(normalized)") {
                return url
            }
            throw error
        }
    }

    private func normalizeImagePath(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let publicPrefix = "/storage/v1/object/public/\(imageBucket)/"
        if let range = trimmed.range(of: publicPrefix) {
            return String(trimmed[range.upperBound...])
        }
        if let range = trimmed.range(of: "\(imageBucket)/") {
            return String(trimmed[range.upperBound...])
        }
        return trimmed
    }

    func fetchArticles(search: String?, category: String?, sort: ArticleSort) async throws -> [ArticleRow] {
        var query: PostgrestFilterBuilder = client
            .from("articles_with_tags")
            .select("*")

        if let search = search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query = query.ilike("title", pattern: "%\(search)%")
        }

        if let category = category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            query = query.contains("tags", value: [category])
        }

        switch sort {
        case .recent:
            _ = query.order("published_at", ascending: false)
        case .topRated:
            _ = query.order("rating", ascending: false)
        case .forYou:
            _ = query.order("published_at", ascending: false)
        }

        let rows: [ArticleRow] = try await query.execute().value
        return rows
    }

    func submitRating(articleID: UUID, rating: Int) async throws {
        struct RatingUpsert: Encodable {
            let article_id: UUID
            let user_id: UUID
            let rating: Int
            let last_opened_at: String
        }

        let session = try await client.auth.session
        let userID = session.user.id
        let df = ISO8601DateFormatter()
        let payload = RatingUpsert(
            article_id: articleID,
            user_id: userID,
            rating: rating,
            last_opened_at: df.string(from: Date())
        )

        _ = try await client
            .from("article_interactions")
            .upsert(payload, onConflict: "article_id,user_id")
            .execute()
    }

    func fetchUserRating(articleID: UUID) async throws -> Int? {
        let session = try await client.auth.session
        let userID = session.user.id

        struct RatingRow: Decodable { let rating: Int? }

        let rows: [RatingRow] = try await client
            .from("article_interactions")
            .select("rating")
            .eq("article_id", value: articleID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first?.rating
    }

    func fetchArticle(id: UUID) async throws -> ArticleRow {
        let row: ArticleRow = try await client
            .from("articles_with_tags")
            .select("*")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return row
    }

    func incrementViews(articleID: UUID) async throws {
        struct Args: Encodable { let p_article_id: UUID }
        _ = try await client
            .rpc("increment_article_view", params: Args(p_article_id: articleID))
            .execute()
    }
}
