//
//  PhysioReportsModel.swift
//  Physio_Connect
//
//  Created by Codex on 21/01/26.
//

import Foundation
import Supabase

struct PatientReportRow {
    let id: UUID
    let name: String
    let ageText: String
    let location: String
    let contact: String
    let programTitles: [String]
    let lastInteraction: Date?
}

struct PhysioReportsSnapshot {
    let patients: [PatientReportRow]
    let totalPrograms: Int
    let totalAssignments: Int
}

final class PhysioReportsModel {
    private let client = SupabaseManager.shared.client

    func resolvePhysioID() async throws -> String {
        let session = try await client.auth.session
        let userID = session.user.id.uuidString

        struct Row: Decodable { let id: UUID }

        let direct: [Row] = try await client
            .from("physiotherapists")
            .select("id")
            .eq("id", value: userID)
            .limit(1)
            .execute()
            .value

        if let match = direct.first {
            return match.id.uuidString
        }

        guard let email = session.user.email?.lowercased() else {
            return userID
        }

        let byEmail: [Row] = try await client
            .from("physiotherapists")
            .select("id")
            .eq("email", value: email)
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return byEmail.first?.id.uuidString ?? userID
    }

    func fetchReport(physioID: String) async throws -> PhysioReportsSnapshot {
        let programs = try await fetchPrograms(physioID: physioID)
        let programIDs = programs.map(\.id)
        let redemptions = try await fetchRedemptions(programIDs: programIDs)
        let appointments = try await fetchAppointmentCustomers(physioID: physioID)

        let customerIDs = Set(redemptions.map(\.customer_id))
            .union(appointments.compactMap(\.customer_id))
        let customers = try await fetchCustomers(ids: Array(customerIDs))

        let programByID = Dictionary(uniqueKeysWithValues: programs.map { ($0.id, $0.title) })
        let appointmentsByCustomer = Dictionary(grouping: appointments.compactMap { row -> (UUID, Date)? in
            guard let id = row.customer_id, let created = row.created_at else { return nil }
            return (id, created)
        }, by: { $0.0 })

        let patients: [PatientReportRow] = customers.map { customer in
            let programsForPatient = redemptions
                .filter { $0.customer_id == customer.id }
                .compactMap { programByID[$0.program_id] }
            let ageText = ageString(from: customer.date_of_birth) ?? "—"
            let contact = Self.firstNonEmpty(
                values: [customer.phone, customer.email],
                fallback: "No contact"
            )
            let location = Self.firstNonEmpty(
                values: [customer.location],
                fallback: "Location unavailable"
            )
            let appointmentLatest = appointmentsByCustomer[customer.id]?.map { $0.1 }.max()
            let redemptionLatest = redemptions
                .filter { $0.customer_id == customer.id }
                .compactMap { parseDate($0.redeemed_at ?? $0.created_at ?? "") }
                .max()
            let lastInteraction = [appointmentLatest, redemptionLatest].compactMap { $0 }.max()
            return PatientReportRow(
                id: customer.id,
                name: Self.firstNonEmpty(values: [customer.full_name], fallback: "Patient"),
                ageText: ageText,
                location: location,
                contact: contact,
                programTitles: programsForPatient,
                lastInteraction: lastInteraction
            )
        }

        return PhysioReportsSnapshot(
            patients: patients.sorted { $0.name.lowercased() < $1.name.lowercased() },
            totalPrograms: programs.count,
            totalAssignments: redemptions.count
        )
    }

    private func fetchPrograms(physioID: String) async throws -> [ProgramRow] {
        let rows: [ProgramRow] = try await client
            .from("physio_programs")
            .select("id,title,is_active")
            .eq("physio_id", value: physioID)
            .eq("is_active", value: true)
            .execute()
            .value
        return rows
    }

    private func fetchRedemptions(programIDs: [UUID]) async throws -> [RedemptionRow] {
        guard !programIDs.isEmpty else { return [] }
        let rows: [RedemptionRow] = try await client
            .from("program_redemptions")
            .select("program_id,customer_id,redeemed_at,created_at")
            .in("program_id", values: programIDs.map { $0.uuidString })
            .execute()
            .value
        return rows
    }

    private func fetchAppointmentCustomers(physioID: String) async throws -> [AppointmentCustomerRow] {
        let rows: [AppointmentCustomerRow] = try await client
            .from("appointments")
            .select("customer_id,created_at")
            .eq("physio_id", value: physioID)
            .order("created_at", ascending: false)
            .limit(180)
            .execute()
            .value
        return rows
    }

    private func fetchCustomers(ids: [UUID]) async throws -> [CustomerRow] {
        let unique = Array(Set(ids))
        guard !unique.isEmpty else { return [] }
        let rows: [CustomerRow] = try await client
            .from("customers")
            .select("id,full_name,email,phone,location,date_of_birth")
            .in("id", values: unique.map { $0.uuidString })
            .execute()
            .value
        return rows
    }

    private func ageString(from dob: String?) -> String? {
        guard let dob else { return nil }
        let trimmed = dob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let date = parseDate(trimmed) else { return nil }
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return years > 0 ? "\(years) yrs" : nil
    }

    private static func firstNonEmpty(values: [String?], fallback: String) -> String {
        for value in values {
            if let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
                return trimmed
            }
        }
        return fallback
    }

    private func parseDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        if let d = df.date(from: raw) { return d }

        df.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
        if let d = df.date(from: raw) { return d }

        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: raw)
    }
}

private struct ProgramRow: Decodable {
    let id: UUID
    let title: String
    let is_active: Bool
}

private struct RedemptionRow: Decodable {
    let program_id: UUID
    let customer_id: UUID
    let redeemed_at: String?
    let created_at: String?
}

private struct AppointmentCustomerRow: Decodable {
    let customer_id: UUID?
    let created_at: Date?
}

private struct CustomerRow: Decodable {
    let id: UUID
    let full_name: String?
    let email: String?
    let phone: String?
    let location: String?
    let date_of_birth: String?

    enum CodingKeys: String, CodingKey {
        case id
        case full_name
        case email
        case phone
        case location
        case date_of_birth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        full_name = try container.decodeIfPresent(String.self, forKey: .full_name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date_of_birth = try container.decodeIfPresent(String.self, forKey: .date_of_birth)
        phone = Self.decodeFlexibleString(from: container, forKey: .phone)
    }

    private static func decodeFlexibleString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
            if doubleValue.rounded() == doubleValue {
                return String(Int(doubleValue))
            }
            return String(doubleValue)
        }
        return nil
    }
}
