//
//  HomeModel.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 31/12/25.
//

import Foundation

// What Home screen needs to render
struct HomeUpcomingAppointment {
    let appointmentID: UUID
    let physioID: UUID
    let physioName: String
    let serviceMode: String        // "home"
    let startTime: Date
    let endTime: Date
    let address: String
    let status: String            // "booked", "completed", etc.
}

final class HomeModel {

    // Replace with your actual service(s)
    // Example: SupabaseManager + PhysioService
    func fetchUpcomingAppointment() async throws -> HomeUpcomingAppointment? {
        // ✅ TODO: connect to Supabase
        // Return nil if no appointment exists.

        return nil
    }
}
