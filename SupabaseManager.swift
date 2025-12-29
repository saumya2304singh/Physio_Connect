import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String
        else {
            fatalError("Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY in Info.plist")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
