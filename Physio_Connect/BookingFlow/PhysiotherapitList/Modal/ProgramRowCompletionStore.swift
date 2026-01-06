//
//  ProgramRowCompletionStore.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import Foundation

enum ProgramRowCompletionStore {
    static func completedRowKeys(programID: UUID) -> Set<String> {
        let defaults = UserDefaults.standard
        let key = storageKey(for: programID)
        guard let values = defaults.array(forKey: key) as? [String] else { return [] }
        return Set(values)
    }

    static func add(rowKey: String, programID: UUID) {
        var keys = completedRowKeys(programID: programID)
        keys.insert(rowKey)
        save(keys, programID: programID)
    }

    private static func save(_ keys: Set<String>, programID: UUID) {
        let defaults = UserDefaults.standard
        let key = storageKey(for: programID)
        defaults.set(Array(keys), forKey: key)
    }

    private static func storageKey(for programID: UUID) -> String {
        "completed_program_rows.\(programID.uuidString)"
    }
}
