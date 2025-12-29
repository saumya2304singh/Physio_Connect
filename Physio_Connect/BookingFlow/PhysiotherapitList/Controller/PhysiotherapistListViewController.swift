//
//  PhysiotherapistListViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 30/12/25.
//

import UIKit
import CoreLocation

final class PhysiotherapistListViewController: UIViewController {

    private let listView = PhysiotherapistListView()

    private var items: [PhysiotherapistCardModel] = []
    private var filtered: [PhysiotherapistCardModel] = []
    private var isSearching = false

    var activeFilters = Filters()

    override func loadView() { view = listView }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        listView.layoutHeaderIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        listView.tableView.dataSource = self
        listView.tableView.delegate = self
        listView.searchBar.delegate = self

        listView.calendarButton.addTarget(self, action: #selector(openCalendar), for: .touchUpInside)
        listView.backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        listView.datePicker.addTarget(self, action: #selector(dateSelected(_:)), for: .valueChanged)
        listView.filterButton.addTarget(self, action: #selector(openFilters), for: .touchUpInside)

        setupLocationUpdates()
        setInitialDatePills()
        fetchPhysios()
    }

    private func setInitialDatePills() {
        let now = Date()
        let d = DateFormatter()
        d.dateFormat = "dd MMM yyyy"
        listView.datePill.text = d.string(from: now)

        let t = DateFormatter()
        t.dateFormat = "h:mm a"
        listView.timePill.text = t.string(from: now)
    }

    // MARK: - Fetch from Supabase (NEW TABLE)
    private func fetchPhysios() {
        Task {
            do {
                let rows = try await PhysioService.shared.fetchPhysiotherapists()
                var cards = rows.map { self.mapToCard($0) }

                if let loc = LocationService.shared.lastLocation {
                    for i in cards.indices { cards[i].updateDistance(from: loc) }
                }

                await MainActor.run {
                    self.items = cards
                    self.filtered = cards
                    self.listView.tableView.reloadData()
                }
            } catch {
                print("❌ fetchPhysios error:", error)
            }
        }
    }

    // MARK: - Map DB model → UI model (IMPORTANT)
    private func mapToCard(_ p: Physiotherapist) -> PhysiotherapistCardModel {

        // feeText must be STRING
        let fee = Int(p.consultation_fee ?? 0)
        let feeText = "₹\(fee)/hr"

        // TEMP: until specialization join, keep this line same style
        let spec = (p.place_of_work?.isEmpty == false) ? p.place_of_work! : "Physiotherapy specialist"

        return PhysiotherapistCardModel(
            id: p.id,
            name: p.name,
            rating: p.avg_rating ?? 0,
            reviewsCount: p.reviews_count ?? 0,
            specializationText: spec,
            feeText: feeText,
            latitude: p.latitude,
            longitude: p.longitude,
            distanceText: "Calculating..."
        )
    }

    // MARK: - Location
    private func setupLocationUpdates() {
        LocationService.shared.onLocationUpdate = { [weak self] city, location in
            guard let self else { return }
            self.listView.cityLabel.text = city

            guard let loc = location else { return }

            for i in self.items.indices { self.items[i].updateDistance(from: loc) }
            for i in self.filtered.indices { self.filtered[i].updateDistance(from: loc) }
            self.listView.tableView.reloadData()
        }
        LocationService.shared.requestLocation()
    }

    // MARK: - Actions
    @objc private func openCalendar() { listView.showDatePicker() }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    @objc private func dateSelected(_ sender: UIDatePicker) {
        let d = DateFormatter()
        d.dateFormat = "dd MMM yyyy"
        listView.datePill.text = d.string(from: sender.date)

        let t = DateFormatter()
        t.dateFormat = "h:mm a"
        listView.timePill.text = t.string(from: sender.date)
    }

    @objc private func openFilters() {
        tabBarController?.tabBar.isHidden = true

        let vc = FiltersOverlayViewController()
        vc.selectedFilters = activeFilters

        vc.onApply = { [weak self] newFilters in
            guard let self else { return }
            self.activeFilters = newFilters
            self.applyFilters()
            self.tabBarController?.tabBar.isHidden = false
        }

        vc.onDismiss = { [weak self] in
            self?.tabBarController?.tabBar.isHidden = false
        }

        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: false)
    }

    private func applyFilters() {
        var list = items

        // NOTE: Your Filters struct might be "specialities" or "specialties"
        // Use whichever exists in YOUR project.
        if !activeFilters.specialities.isEmpty {
            list = list.filter { activeFilters.specialities.contains($0.specializationText) }
        }

        list = list.filter { extractKm(from: $0.distanceText) <= activeFilters.maxDistance }

        if activeFilters.minRating > 0 {
            list = list.filter { Int($0.rating) >= activeFilters.minRating }
        }

        filtered = list
        listView.tableView.reloadData()
    }

    private func extractKm(from text: String) -> Double {
        let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(digits) ?? 999
    }
}

// MARK: - Table
extension PhysiotherapistListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSearching ? filtered.count : items.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: PhysiotherapistCardCell.reuseID,
            for: indexPath
        ) as! PhysiotherapistCardCell

        let model = isSearching ? filtered[indexPath.row] : items[indexPath.row]
        cell.configure(with: model)
        return cell
    }
}

// MARK: - Search
extension PhysiotherapistListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
            isSearching = false
            filtered = items
        } else {
            isSearching = true
            let q = searchText.lowercased()
            filtered = items.filter {
                $0.name.lowercased().contains(q) ||
                $0.specializationText.lowercased().contains(q) ||
                $0.distanceText.lowercased().contains(q)
            }
        }

        listView.tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        filtered = items
        searchBar.text = ""
        listView.tableView.reloadData()
    }
}
