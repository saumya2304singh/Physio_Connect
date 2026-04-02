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
    private var availableItems: [PhysiotherapistCardModel] = []
    private var filtered: [PhysiotherapistCardModel] = []
    private var availablePhysioIDs: Set<UUID>?
    private var searchQuery = ""
    private var selectedDate = Date()
    private let emptyStateView = NativeEmptyStateView()
    private let specialityOptions = ["Knee Physiotherapy", "Neck Physiotherapy", "Shoulder Physiotherapy"]
    private let genderOptions = ["Male", "Female", "Prefer not to say"]
    private let distanceOptions: [Double] = [5, 10, 15, 25, 50]
    private let ratingOptions: [Int] = [0, 1, 2, 3, 4, 5]

    var activeFilters = Filters()
    private lazy var navFilterItem = UIBarButtonItem(
        image: UIImage(systemName: "line.3.horizontal.decrease.circle.fill"),
        style: .plain,
        target: nil,
        action: nil
    )

    override func loadView() { view = listView }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        listView.layoutHeaderIfNeeded()
        updateEmptyStateLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyNavigationChrome()
        navigationController?.setNavigationBarHidden(false, animated: false)
        listView.useNativeNavigationChrome()
        rebuildFilterMenu()

        listView.tableView.dataSource = self
        listView.tableView.delegate = self
        listView.searchBar.delegate = self
        listView.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 110, right: 0)
        listView.tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 110, right: 0)
        emptyStateView.frame = CGRect(x: 0, y: 0, width: 0, height: 220)
        emptyStateView.configure(
            icon: "person.2.slash",
            title: "No Physiotherapists Found",
            message: "Try another time slot, update filters, or search with a different keyword."
        )
        listView.tableView.backgroundView = nil
        listView.tableView.tableFooterView = UIView(frame: .zero)

        listView.datePill.addTarget(self, action: #selector(datePillTapped), for: .touchUpInside)
        listView.timePill.addTarget(self, action: #selector(timePillTapped), for: .touchUpInside)
        listView.searchBottomButton.addTarget(self, action: #selector(searchBottomTapped), for: .touchUpInside)

        setupLocationUpdates()
        setInitialDatePills()
        fetchPhysios()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        applyNavigationChrome()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func applyNavigationChrome() {
        navigationItem.hidesBackButton = false
        navigationItem.title = "Find your Physio"
        navigationItem.titleView = nil
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftItemsSupplementBackButton = false
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = navFilterItem
    }

    private func rebuildFilterMenu() {
        let specialityActions = specialityOptions.map { speciality in
            UIAction(
                title: speciality,
                state: activeFilters.specialities.contains(speciality) ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }
                if self.activeFilters.specialities.contains(speciality) {
                    self.activeFilters.specialities.removeAll { $0 == speciality }
                } else {
                    self.activeFilters.specialities.append(speciality)
                }
                self.applyFilters()
                self.rebuildFilterMenu()
            }
        }

        let genderActions: [UIAction] = [
            UIAction(
                title: "Any",
                state: activeFilters.gender == nil ? .on : .off
            ) { [weak self] _ in
                self?.activeFilters.gender = nil
                self?.applyFilters()
                self?.rebuildFilterMenu()
            }
        ] + genderOptions.map { gender in
            UIAction(
                title: gender,
                state: activeFilters.gender == gender ? .on : .off
            ) { [weak self] _ in
                self?.activeFilters.gender = gender
                self?.applyFilters()
                self?.rebuildFilterMenu()
            }
        }

        let distanceActions = distanceOptions.map { km in
            UIAction(
                title: "within \(Int(km)) km",
                state: Int(activeFilters.maxDistance) == Int(km) ? .on : .off
            ) { [weak self] _ in
                self?.activeFilters.maxDistance = km
                self?.applyFilters()
                self?.rebuildFilterMenu()
            }
        }

        let ratingActions = ratingOptions.map { minRating in
            let title = minRating == 0 ? "Any Rating" : "\(minRating)+ Stars"
            return UIAction(
                title: title,
                state: activeFilters.minRating == minRating ? .on : .off
            ) { [weak self] _ in
                self?.activeFilters.minRating = minRating
                self?.applyFilters()
                self?.rebuildFilterMenu()
            }
        }

        let resetAction = UIAction(title: "Reset Filters", attributes: .destructive) { [weak self] _ in
            guard let self else { return }
            self.activeFilters = Filters()
            self.applyFilters()
            self.rebuildFilterMenu()
        }

        let menu = UIMenu(title: "Filter by", children: [
            UIMenu(title: "Speciality", options: .displayInline, children: specialityActions),
            UIMenu(title: "Gender", options: .displayInline, children: genderActions),
            UIMenu(title: "Distance", options: .displayInline, children: distanceActions),
            UIMenu(title: "Ratings", options: .displayInline, children: ratingActions),
            resetAction
        ])
        navFilterItem.menu = menu
    }

    private func setInitialDatePills() {
        let now = selectedDate
        let d = DateFormatter()
        d.dateFormat = "dd MMM yyyy"
        listView.setDateText(d.string(from: now))

        let t = DateFormatter()
        t.dateFormat = "h:mm a"
        listView.setTimeText(t.string(from: now))
    }

    // MARK: - Fetch from Supabase (NEW TABLE)
    private func fetchPhysios() {
        Task {
            do {
                let rows = try await PhysioService.shared.fetchPhysiotherapistsForList()
                var cards = rows.map { self.mapToCard($0) }

                if let loc = LocationService.shared.lastLocation {
                    for i in cards.indices { cards[i].updateDistance(from: loc) }
                }

                await MainActor.run {
                    self.items = cards
                    self.applyAvailabilityFilter()
                    self.applyFilters()
                }
                await refreshAvailability()
            } catch {
                print("❌ fetchPhysios error:", error)
                await MainActor.run {
                    self.items = []
                    self.availableItems = []
                    self.filtered = []
                    self.listView.tableView.reloadData()
                    self.updateEmptyStateLayout()
                }
            }
        }
    }

    // MARK: - Map DB model → UI model (IMPORTANT)
    private func mapToCard(_ p: PhysioListRow) -> PhysiotherapistCardModel
{

        // feeText must be STRING
        let fee = Int(p.consultation_fee ?? 0)
        let feeText = "₹\(fee)/hr"

        // TEMP: until specialization join, keep this line same style
        let spec =
        p.physio_specializations?
            .compactMap { $0.specializations?.name }
            .first
        ?? "Physiotherapy specialist"

        let placeOfWork = p.place_of_work?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            ?? "Workplace not available"

        return PhysiotherapistCardModel(
            id: p.id,
            name: p.name,
            gender: p.gender,
            rating: p.avg_rating ?? 0,
            reviewsCount: p.reviews_count ?? 0,
            specializationText: spec,
            feeText: feeText,
            metaText: placeOfWork,
            profileImagePath: p.profile_image_path,
            profileImageVersion: p.updated_at,
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
            self.applyAvailabilityFilter()
            self.applyFilters()
        }
        LocationService.shared.requestLocation()
    }

    // MARK: - Actions
    @objc private func searchBottomTapped() {
        listView.toggleSearchVisibility()
    }

    @objc private func datePillTapped() {
        presentDatePicker(mode: .date)
    }

    @objc private func timePillTapped() {
        presentDatePicker(mode: .time)
    }

    private func applyAvailabilityFilter() {
        if let ids = availablePhysioIDs {
            availableItems = items.filter { ids.contains($0.id) }
        } else {
            availableItems = items
        }
    }

    private func applyFilters() {
        var list = availableItems

        // NOTE: Your Filters struct might be "specialities" or "specialties"
        // Use whichever exists in YOUR project.
        if !activeFilters.specialities.isEmpty {
            let specials = activeFilters.specialities.map { $0.lowercased() }
            list = list.filter { model in
                let specialization = model.specializationText.lowercased()
                return specials.contains { specialization.contains($0) }
            }
        }

        list = list.filter { model in
            guard let km = extractKm(from: model.distanceText) else { return true }
            return km <= activeFilters.maxDistance
        }

        if activeFilters.minRating > 0 {
            list = list.filter { Int($0.rating) >= activeFilters.minRating }
        }

        if let gender = activeFilters.gender, gender != "Prefer not to say" {
            let target = gender.lowercased()
            list = list.filter { $0.gender?.lowercased() == target }
        }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedQuery.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(trimmedQuery) ||
                $0.specializationText.lowercased().contains(trimmedQuery) ||
                $0.metaText.lowercased().contains(trimmedQuery)
            }
        }

        filtered = list
        listView.tableView.reloadData()
        updateEmptyStateLayout()
        rebuildFilterMenu()
    }

    private func updateEmptyStateLayout() {
        guard isViewLoaded else { return }

        if filtered.isEmpty {
            let tableWidth = listView.tableView.bounds.width
            guard tableWidth > 0 else { return }

            let availableHeight = listView.bounds.height
                - listView.safeAreaInsets.top
                - listView.safeAreaInsets.bottom
                - listView.tableHeaderContentHeight
                - listView.tableView.adjustedContentInset.bottom
                - 16

            let footerHeight = max(220, availableHeight)
            let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableWidth, height: footerHeight))
            footer.backgroundColor = .clear
            footer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)

            emptyStateView.removeFromSuperview()
            footer.addSubview(emptyStateView)
            NSLayoutConstraint.activate([
                emptyStateView.topAnchor.constraint(equalTo: footer.layoutMarginsGuide.topAnchor),
                emptyStateView.leadingAnchor.constraint(equalTo: footer.layoutMarginsGuide.leadingAnchor),
                emptyStateView.trailingAnchor.constraint(equalTo: footer.layoutMarginsGuide.trailingAnchor),
                emptyStateView.heightAnchor.constraint(equalToConstant: 220)
            ])
            listView.tableView.tableFooterView = footer
        } else {
            listView.tableView.tableFooterView = UIView(frame: .zero)
        }
    }

    private func presentDatePicker(mode: UIDatePicker.Mode) {
        let picker = UIDatePicker()
        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        picker.datePickerMode = mode
        picker.date = selectedDate
        if mode == .date {
            picker.minimumDate = Date()
        }

        let title = mode == .date ? "Select Date" : "Select Time"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        let contentView = UIViewController()
        contentView.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: contentView.view.topAnchor),
            picker.leadingAnchor.constraint(equalTo: contentView.view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: contentView.view.trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: contentView.view.bottomAnchor),
            contentView.view.heightAnchor.constraint(equalToConstant: 216)
        ])

        alert.setValue(contentView, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] _ in
            self?.updateSelectedDate(with: picker.date, mode: mode)
        }))
        present(alert, animated: true)
    }

    private func updateSelectedDate(with value: Date, mode: UIDatePicker.Mode) {
        let calendar = Calendar.current
        switch mode {
        case .date:
            let newDate = calendar.startOfDay(for: value)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
            selectedDate = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: newDate
            ) ?? newDate
        case .time:
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: value)
            selectedDate = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: calendar.date(from: dateComponents) ?? selectedDate
            ) ?? selectedDate
        default:
            selectedDate = value
        }

        let d = DateFormatter()
        d.dateFormat = "dd MMM yyyy"
        listView.setDateText(d.string(from: selectedDate))

        let t = DateFormatter()
        t.dateFormat = "h:mm a"
        listView.setTimeText(t.string(from: selectedDate))

        Task { await refreshAvailability() }
    }

    private func refreshAvailability() async {
        do {
            let ids = try await PhysioService.shared.fetchAvailablePhysioIDs(at: selectedDate)
            await MainActor.run {
                self.availablePhysioIDs = ids.isEmpty ? nil : ids
                self.applyAvailabilityFilter()
                self.applyFilters()
            }
        } catch {
            print("❌ availability fetch error:", error)
        }
    }

    private func extractKm(from text: String) -> Double? {
        let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(digits)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Table
extension PhysiotherapistListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: PhysiotherapistCardCell.reuseID,
            for: indexPath
        ) as! PhysiotherapistCardCell

        let model = filtered[indexPath.row]
        cell.configure(with: model)
        cell.avatarPath = model.profileImagePath
        cell.setAvatarImage(nil)
        loadAvatar(path: model.profileImagePath, version: model.profileImageVersion, into: cell)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = filtered[indexPath.row]

        let vc = PhysiotherapistProfileViewController(physioID: model.id, preloadCard: model)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadAvatar(path: String?, version: String?, into cell: PhysiotherapistCardCell) {
        guard let path else { return }
        PhysioService.shared.loadProfileImage(pathOrUrl: path, version: version) { [weak cell] image in
            guard let cell else { return }
            if cell.avatarPath == path {
                cell.setAvatarImage(image)
            }
        }
    }
}


// MARK: - Search
extension PhysiotherapistListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText
        applyFilters()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchQuery = ""
        searchBar.text = ""
        applyFilters()
    }
}
