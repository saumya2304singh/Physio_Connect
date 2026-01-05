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

            struct PhysioJoin: Decodable {
                let name: String
                let consultation_fee: Double?
                let avg_rating: Double?
                let reviews_count: Int?
                let physio_specializations: [PhysioSpecJoin]?

                struct PhysioSpecJoin: Decodable {
                    let specializations: Specialization?
                    struct Specialization: Decodable {
                        let name: String
                    }
                }
            }
            struct SlotJoin: Decodable {
                let start_time: Date
                let end_time: Date
            }
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowIso = formatter.string(from: Date())

        let rows: [ApptJoinRow] = try await SupabaseManager.shared.client
            .from("appointments")
            .select("""
                id,
                physio_id,
                service_mode,
                address_text,
                status,
                physiotherapists(
                    name,
                    consultation_fee,
                    avg_rating,
                    reviews_count,
                    physio_specializations(
                        specializations(name)
                    )
                ),
                physio_availability_slots(start_time,end_time)
            """)
            .eq("customer_id", value: userId.uuidString)
            .or("status.eq.booked,status.eq.confirmed")
            .gt("physio_availability_slots.start_time", value: nowIso)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        guard let r = rows.first else { return nil }
        guard r.physio_availability_slots.start_time > Date() else { return nil }
        guard r.physio_availability_slots.start_time > Date() else { return nil }
        let specialization = r.physiotherapists.physio_specializations?
            .compactMap { $0.specializations?.name }
            .first ?? "Physiotherapist Specialist"
        let feeText: String
        if let fee = r.physiotherapists.consultation_fee {
            feeText = "₹\(Int(fee))/hr"
        } else {
            feeText = "TBD"
        }
        let ratingText: String
        if let avg = r.physiotherapists.avg_rating, let count = r.physiotherapists.reviews_count {
            ratingText = "⭐️ \(String(format: "%.1f", avg)) | \(count) reviews"
        } else {
            ratingText = "N/A"
        }

        return HomeUpcomingAppointment(
            appointmentID: r.id,
            physioID: r.physio_id,
            physioName: r.physiotherapists.name,
            serviceMode: r.service_mode,
            specializationText: specialization,
            consultationFeeText: feeText,
            ratingText: ratingText,
            startTime: r.physio_availability_slots.start_time,
            endTime: r.physio_availability_slots.end_time,
            address: r.address_text ?? "",
            status: r.status
        )
    }
}
