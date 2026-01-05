//
//  AppointmentsModel.swift
//  Physio_Connect
//
//  Created by user@8 on 02/01/26.
//

import Foundation
import Supabase

final class AppointmentsModel {

    private let client = SupabaseManager.shared.client

    // MARK: - Public API

    /// Returns the nearest upcoming "booked" appointment (future) for current user
    func fetchUpcomingAppointment() async throws -> UpcomingAppointment? {
        let session = try await client.auth.session
        let userID = session.user.id.uuidString

        let nowISO = ISO8601DateFormatter().string(from: Date())

        var rows: [AppointmentJoinedRow] = try await client
            .from("appointments")
            .select("""
                id,
                status,
                address_text,
                created_at,
                physio_id,
                slot:physio_availability_slots!appointments_slot_id_fkey(
                    start_time
                ),
                physio:physiotherapists!appointments_physio_id_fkey(
                    id,
                    name,
                    avg_rating,
                    reviews_count,
                    location_text,
                    consultation_fee,
                    physio_specializations(
                        specializations(name)
                    )
                )
            """)
            .eq("customer_id", value: userID)
            .or("status.eq.booked,status.eq.confirmed")
            .gte("physio_availability_slots.start_time", value: nowISO) // future only (works with embedded)
            .order("start_time", ascending: true, referencedTable: "physio_availability_slots")

            .limit(1)
            .execute()
            .value

        if rows.isEmpty {
            rows = try await client
                .from("appointments")
                .select("""
                    id,
                    status,
                    address_text,
                    created_at,
                    physio_id,
                    slot:physio_availability_slots!appointments_slot_id_fkey(
                        start_time
                    ),
                    physio:physiotherapists!appointments_physio_id_fkey(
                        id,
                        name,
                        avg_rating,
                        reviews_count,
                        location_text,
                        consultation_fee,
                        physio_specializations(
                            specializations(name)
                        )
                    )
                """)
                .eq("customer_id", value: userID)
                .or("status.eq.booked,status.eq.confirmed")
                .order("start_time", ascending: false, referencedTable: "physio_availability_slots")
                .limit(1)
                .execute()
                .value
        }

        guard let first = rows.first,
              let physio = first.physio
        else { return nil }
        let startTime = first.slot?.start_time ?? first.created_at
        guard startTime > Date() else { return nil }

        return UpcomingAppointment(
            appointmentID: first.id,
            physioID: physio.id,
            physioName: physio.name,
            startTime: startTime,
            address: first.address_text ?? "",
            specialization: physio.primarySpecialization ?? "Healthcare Professional",
            rating: physio.avg_rating,
            reviewsCount: physio.reviews_count,
            locationText: physio.location_text,
            fee: physio.consultation_fee
        )
    }

    func cancelAppointment(appointmentID: UUID) async throws {
        _ = try await client
            .from("appointments")
            .update(["status": "cancelled"])
            .eq("id", value: appointmentID.uuidString)
            .execute()
    }

    /// Returns past appointments for current user: completed + cancelled
    func fetchPastAppointments() async throws -> [PastAppointment] {
        let session = try await client.auth.session
        let userID = session.user.id.uuidString
        let nowISO = ISO8601DateFormatter().string(from: Date())

        // We'll do 2 queries (super safe with your current codebase),
        // then merge + sort desc by time.
        async let completedRows: [AppointmentJoinedRow] = client
            .from("appointments")
            .select(joinSelect)
            .eq("customer_id", value: userID)
            .eq("status", value: "completed")
            .order("start_time", ascending: true, referencedTable: "physio_availability_slots")

            .execute()
            .value

        async let cancelledRows: [AppointmentJoinedRow] = client
            .from("appointments")
            .select(joinSelect)
            .eq("customer_id", value: userID)
            .eq("status", value: "cancelled")
            .order("start_time", ascending: true, referencedTable: "physio_availability_slots")

            .execute()
            .value

        async let overdueRows: [AppointmentJoinedRow] = client
            .from("appointments")
            .select(joinSelect)
            .eq("customer_id", value: userID)
            .or("status.eq.booked,status.eq.confirmed")
            .lt("physio_availability_slots.start_time", value: nowISO)
            .order("start_time", ascending: false, referencedTable: "physio_availability_slots")
            .execute()
            .value

        let completed = try await completedRows
        let cancelled = try await cancelledRows
        let overdue = try await overdueRows
        let merged = completed + cancelled + overdue

        // map -> view models
        let mapped: [PastAppointment] = merged.compactMap { row in
            guard let physio = row.physio else { return nil }
            let startTime = row.slot?.start_time ?? row.created_at
            let status = ["booked", "confirmed"].contains(row.status.lowercased())
            ? "completed"
            : row.status
            return PastAppointment(
                appointmentID: row.id,
                physioID: physio.id,
                physioName: physio.name,
                status: status, // "completed" | "cancelled"
                startTime: startTime,
                specialization: physio.primarySpecialization ?? "Healthcare Professional",
                rating: physio.avg_rating,
                reviewsCount: physio.reviews_count,
                locationText: physio.location_text,
                fee: physio.consultation_fee
            )
        }

        if !overdue.isEmpty {
            let overdueIDs = overdue.map { $0.id.uuidString }
            _ = try await client
                .from("appointments")
                .update(["status": "completed"])
                .in("id", values: overdueIDs)
                .execute()
        }

        return mapped.sorted { $0.startTime > $1.startTime }
    }

    // MARK: - Private

    private var joinSelect: String {
        """
        id,
        status,
        address_text,
        created_at,
        physio_id,
        slot:physio_availability_slots!appointments_slot_id_fkey(
            start_time
        ),
        physio:physiotherapists!appointments_physio_id_fkey(
            id,
            name,
            avg_rating,
            reviews_count,
            location_text,
            consultation_fee,
            physio_specializations(
                specializations(name)
            )
        )
        """
    }
}

// MARK: - DTOs (Supabase decode)

private struct AppointmentJoinedRow: Decodable {
    let id: UUID
    let status: String
    let address_text: String?
    let created_at: Date
    let physio_id: UUID

    let slot: SlotRow?
    let physio: PhysioRow?

    struct SlotRow: Decodable {
        let start_time: Date
    }

    struct PhysioRow: Decodable {
        let id: UUID
        let name: String
        let avg_rating: Double?
        let reviews_count: Int?
        let location_text: String?
        let consultation_fee: Double?

        let physio_specializations: [SpecJoin]?

        struct SpecJoin: Decodable {
            let specializations: Spec?
            struct Spec: Decodable { let name: String }
        }

        var primarySpecialization: String? {
            physio_specializations?.first?.specializations?.name
        }
    }
}

// MARK: - Clean models for VC

struct UpcomingAppointment {
    let appointmentID: UUID
    let physioID: UUID
    let physioName: String
    let startTime: Date
    let address: String
    let specialization: String

    let rating: Double?
    let reviewsCount: Int?
    let locationText: String?
    let fee: Double?
}

struct PastAppointment {
    let appointmentID: UUID
    let physioID: UUID
    let physioName: String
    let status: String          // "completed" | "cancelled"
    let startTime: Date
    let specialization: String

    let rating: Double?
    let reviewsCount: Int?
    let locationText: String?
    let fee: Double?
}
