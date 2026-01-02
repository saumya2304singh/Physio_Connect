//
//  VideosViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 02/01/26.
//

import UIKit

final class VideosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let videosView = VideosView()
    private let model = VideosModel()

    private var freeExercises: [ExerciseVideoRow] = []
    private var programExercises: [MyProgramExerciseRow] = []
    private var isRefreshing = false
    private let filterOptions = ["All", "Neck", "Back", "Shoulders", "Knees"]
    private var selectedFilterIndex = 0

    private var isProgramTab: Bool { videosView.segmented.selectedSegmentIndex == 1 }
    private var filteredFreeExercises: [ExerciseVideoRow] {
        guard selectedFilterIndex > 0 else { return freeExercises }
        let filter = filterOptions[selectedFilterIndex].lowercased()
        return freeExercises.filter { row in
            let area = row.target_area?.lowercased() ?? ""
            return area.contains(filter)
        }
    }

    override func loadView() { view = videosView }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Videos"
        navigationController?.navigationBar.prefersLargeTitles = true

        videosView.tableView.dataSource = self
        videosView.tableView.delegate = self
        videosView.searchBar.delegate = self
        videosView.tableView.register(ExerciseCell.self, forCellReuseIdentifier: ExerciseCell.reuseID)
        videosView.tableView.rowHeight = UITableView.automaticDimension
        videosView.tableView.estimatedRowHeight = 300
        videosView.filterCollectionView.dataSource = self
        videosView.filterCollectionView.delegate = self
        videosView.filterCollectionView.register(ExerciseFilterChipCell.self, forCellWithReuseIdentifier: ExerciseFilterChipCell.reuseID)
        videosView.filterCollectionView.allowsMultipleSelection = false
        videosView.filterCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])

        videosView.segmented.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        videosView.redeemButton.addTarget(self, action: #selector(redeemTapped), for: .touchUpInside)
        videosView.setRefreshTarget(self, action: #selector(refreshPulled))

        Task { await reload() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await reload() }
    }

    @objc private func tabChanged() {
        Task { await reload() }
    }

    @objc private func refreshPulled() {
        Task { await reload() }
    }

    private func reload() async {
        if isRefreshing { return }
        isRefreshing = true
        await MainActor.run { self.videosView.setRefreshing(true) }
        defer {
            Task { @MainActor in
                self.isRefreshing = false
                self.videosView.setRefreshing(false)
            }
        }

        do {
            if isProgramTab {
                videosView.searchBar.isHidden = true
                videosView.filterCollectionView.isHidden = true
                let rows = try await model.fetchMyProgramExercises()
                programExercises = rows
                await MainActor.run {
                    self.videosView.showEmptyState(rows.isEmpty)
                    self.videosView.tableView.reloadData()
                }
            } else {
                videosView.searchBar.isHidden = false
                videosView.filterCollectionView.isHidden = false
                let rows = try await model.fetchFreeExercises(search: videosView.searchBar.text)
                freeExercises = rows
                await MainActor.run {
                    self.videosView.showEmptyState(false)
                    self.videosView.filterCollectionView.reloadData()
                    self.videosView.tableView.reloadData()
                }
            }
        } catch {
            await MainActor.run {
                if self.isProgramTab { self.videosView.showEmptyState(true) }
                self.showError("Videos Error", error.localizedDescription)
            }
        }
    }

    @objc private func redeemTapped() {
        let ac = UIAlertController(
            title: "Redeem Program Code",
            message: "Enter the code provided by your physiotherapist.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "e.g., PHYSIO-2026"
            tf.autocapitalizationType = .allCharacters
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Redeem", style: .default) { [weak self] _ in
            guard let self else { return }
            let code = ac.textFields?.first?.text ?? ""
            Task {
                do {
                    _ = try await self.model.redeemProgram(code: code.trimmingCharacters(in: .whitespacesAndNewlines))
                    await self.reload()
                } catch {
                    await MainActor.run {
                        self.showError("Redeem failed", error.localizedDescription)
                    }
                }
            }
        })

        present(ac, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Task {
            do {
                let rows = try await model.fetchFreeExercises(search: searchText)
                freeExercises = rows
                await MainActor.run { self.videosView.tableView.reloadData() }
            } catch {
                await MainActor.run { self.showError("Search error", error.localizedDescription) }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isProgramTab ? programExercises.count : filteredFreeExercises.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseCell.reuseID, for: indexPath) as! ExerciseCell
        cell.selectionStyle = .none

        if isProgramTab {
            let row = programExercises[indexPath.row]
            cell.configure(
                title: row.title,
                subtitle: "\(row.target_area ?? "General") - \(row.purpose ?? "Program")",
                description: row.description,
                durationSeconds: row.duration_seconds,
                badgeText: row.difficulty ?? "Program",
                thumbnailPath: row.thumbnail_path
            )
            loadThumbnail(for: row.thumbnail_path, in: cell)
        } else {
            let row = filteredFreeExercises[indexPath.row]
            cell.configure(
                title: row.title,
                subtitle: "\(row.target_area ?? "General") - \(row.purpose ?? "Free")",
                description: row.description,
                durationSeconds: row.duration_seconds,
                badgeText: row.difficulty ?? "Free",
                thumbnailPath: row.thumbnail_path
            )
            loadThumbnail(for: row.thumbnail_path, in: cell)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isProgramTab {
            let r = programExercises[indexPath.row]
            let vc = ExerciseDetailViewController(
                titleText: r.title,
                subtitle: "\(r.target_area ?? "General") - \(r.purpose ?? "Program")",
                descriptionText: r.description,
                durationSeconds: r.duration_seconds,
                videoPath: r.video_path,
                programID: r.program_id,
                exerciseID: r.exercise_id,
                sets: r.sets,
                reps: r.reps,
                hold: r.hold_seconds
            )
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let r = filteredFreeExercises[indexPath.row]
            let vc = ExerciseDetailViewController(
                titleText: r.title,
                subtitle: "\(r.target_area ?? "General") - \(r.purpose ?? "Free")",
                descriptionText: r.description,
                durationSeconds: r.duration_seconds,
                videoPath: r.video_path,
                programID: nil,
                exerciseID: r.id,
                sets: nil,
                reps: nil,
                hold: nil
            )
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filterOptions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExerciseFilterChipCell.reuseID, for: indexPath) as! ExerciseFilterChipCell
        cell.configure(title: filterOptions[indexPath.item])
        cell.isSelected = indexPath.item == selectedFilterIndex
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilterIndex = indexPath.item
        collectionView.reloadData()
        videosView.tableView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = filterOptions[indexPath.item]
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let width = title.size(withAttributes: [.font: font]).width + 32
        return CGSize(width: max(64, width), height: 32)
    }

    private func loadThumbnail(for path: String?, in cell: ExerciseCell) {
        guard let path else { return }
        Task { [weak self, weak cell] in
            guard let self, let cell else { return }
            do {
                let url = try await self.model.signedThumbnailURL(path: path)
                await MainActor.run {
                    if cell.thumbnailPath == path {
                        cell.setThumbnail(url: url)
                    }
                }
            } catch {
                return
            }
        }
    }

    private func showError(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
