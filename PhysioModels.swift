//
//  PhysioModels.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 29/12/25.
//
import Foundation

struct Physiotherapist: Decodable {
    let id: UUID
    let name: String
    let gender: String?
    let consultation_fee: Double?
    let avg_rating: Double?
    let location_text: String?
}

