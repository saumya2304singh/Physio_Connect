//
//  LoginModel.swift
//  Physio_Connect
//
//  Created by user@8 on 06/01/26.
//

import Foundation

final class LoginModel {
    private let client = SupabaseManager.shared.client

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }
}
