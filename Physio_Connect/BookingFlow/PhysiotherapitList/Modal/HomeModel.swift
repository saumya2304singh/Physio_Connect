//
//  HomeModel.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 31/12/25.
//
import Foundation

final class HomeModel {

    func fetchUpcomingAppointment() async throws -> HomeUpcomingAppointment? {

        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id

        struct ApptJoinRow: Decodable {
            let id: UUID
            let physio_id: UUID
            let service_mode: String
            let address_text: String?
            let status: String

            let physiotherapists: PhysioJoin
            let physio_availability_slots: SlotJoin

            struct PhysioJoin: Decodable { let name: String }
            struct SlotJoin: Decodable {
                let start_time: Date
                let end_time: Date
            }
        }

        let rows: [ApptJoinRow] = try await SupabaseManager.shared.client
            .from("appointments")
            .select("""
                id,
                physio_id,
                service_mode,
                address_text,
                status,
                physiotherapists(name),
                physio_availability_slots(start_time,end_time)
            """)
            .eq("customer_id", value: userId.uuidString)
            .eq("status", value: "booked")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        guard let r = rows.first else { return nil }

        return HomeUpcomingAppointment(
            appointmentID: r.id,
            physioID: r.physio_id,
            physioName: r.physiotherapists.name,
            serviceMode: r.service_mode,
            startTime: r.physio_availability_slots.start_time,
            endTime: r.physio_availability_slots.end_time,
            address: r.address_text ?? "",
            status: r.status
        )
    }
}

