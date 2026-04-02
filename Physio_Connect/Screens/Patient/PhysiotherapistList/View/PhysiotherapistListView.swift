//
//  PhysiotherapistListView.swift
//  Physio_Connect
//
//  Created by user@8 on 30/12/25.
//
//
//  PhysiotherapistListView.swift
//  Physio_Connect
//

import UIKit

final class PhysiotherapistListView: UIView {

    // MARK: - Static Header
    let headerContainer = UIView()
    let backButton = UIButton(type: .system)
    let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Find a Physio"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textAlignment = .left
        return l
    }()

    // MARK: - Table
    let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Table Header (content)
    private let headerContentView = UIView()

    let locationIcon = UIImageView()
    let cityLabel: UILabel = {
        let l = UILabel()
        l.text = "Chennai"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .darkGray
        return l
    }()

    let searchBar = UISearchBar()
    let filterButton = UIButton(type: .system)
    let searchBottomButton = UIButton(type: .system)
    private var searchHeightConstraint: NSLayoutConstraint?
    private var headerHeightConstraint: NSLayoutConstraint?
    private var isSearchVisible = false

    let selectDateLabel: UILabel = {
        let l = UILabel()
        l.text = "Select date and time"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .darkGray
        return l
    }()

    let datePill = UIButton(type: .system)
    let timePill = UIButton(type: .system)

    // MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E3F0FF")
        setupHeader()
        setupTable()
        setupTableHeaderContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Header
    private func setupHeader() {
        addSubview(headerContainer)
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.backgroundColor = UIColor(hex: "E3F0FF")

        headerContainer.addSubview(backButton)
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(filterButton)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        filterButton.translatesAutoresizingMaskIntoConstraints = false

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        backButton.layer.cornerRadius = 22
        backButton.layer.cornerCurve = .continuous

        let filterConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        filterButton.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle.fill", withConfiguration: filterConfig), for: .normal)
        filterButton.tintColor = UIColor(hex: "1E6EF7")
        filterButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        filterButton.layer.cornerRadius = 22
        filterButton.layer.cornerCurve = .continuous
        filterButton.layer.borderWidth = 0.8
        filterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        filterButton.layer.shadowColor = UIColor.black.cgColor
        filterButton.layer.shadowOpacity = 0.08
        filterButton.layer.shadowRadius = 8
        filterButton.layer.shadowOffset = CGSize(width: 0, height: 2)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            backButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            filterButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            filterButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: filterButton.leadingAnchor, constant: -12)
        ])
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerHeightConstraint = headerContainer.heightAnchor.constraint(equalToConstant: 56)
        headerHeightConstraint?.isActive = true
    }

    // MARK: Table
    private func setupTable() {
        tableView.register(PhysiotherapistCardCell.self, forCellReuseIdentifier: PhysiotherapistCardCell.reuseID)
        addSubview(tableView)
        addSubview(searchBottomButton)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
        tableView.contentInsetAdjustmentBehavior = .always

        searchBottomButton.translatesAutoresizingMaskIntoConstraints = false
        NativeUIStyle.styleFloatingSearchButton(searchBottomButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            searchBottomButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            searchBottomButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -42),
            searchBottomButton.widthAnchor.constraint(equalToConstant: 60),
            searchBottomButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: Table Header Contents
    private func setupTableHeaderContents() {
        tableView.tableHeaderView = headerContentView
        headerContentView.translatesAutoresizingMaskIntoConstraints = false
        headerContentView.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        headerContentView.backgroundColor = .clear
        headerContentView.layoutIfNeeded()

        // Custom location icon from assets (fallback to SF Symbol)
        locationIcon.image = UIImage(named: "location_icon") ?? UIImage(systemName: "location.fill")
        locationIcon.tintColor = UIColor(hex: "1E6EF7")

        // Search bar
        NativeUIStyle.styleSearchBar(searchBar, placeholder: "name, neck, back...")
        searchBar.isHidden = true

        // CUSTOMIZE INNER TEXT FIELD
        let textField = searchBar.searchTextField
        textField.layer.borderWidth = 0
        textField.layer.cornerRadius = 20
        textField.clipsToBounds = true

        textField.attributedPlaceholder = NSAttributedString(
            string: "name, neck, back...",
            attributes: [.foregroundColor: UIColor.systemGray]
        )

        // Hugging priority
        searchBar.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Pills style
        [datePill, timePill].forEach {
            $0.setTitleColor(.label, for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            $0.backgroundColor = .white
            $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            $0.layer.cornerRadius = 8
            $0.layer.masksToBounds = true
        }
        datePill.setTitle("13 Nov 2025", for: .normal)
        timePill.setTitle("10:35 AM", for: .normal)

        [locationIcon, cityLabel,
         searchBar,
         selectDateLabel,
         datePill, timePill].forEach {
            headerContentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Location row
            locationIcon.topAnchor.constraint(equalTo: headerContentView.topAnchor, constant: 8),
            locationIcon.leadingAnchor.constraint(equalTo: headerContentView.leadingAnchor, constant: 16),
            locationIcon.widthAnchor.constraint(equalToConstant: 16),
            locationIcon.heightAnchor.constraint(equalToConstant: 16),

            cityLabel.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            cityLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 6),

            // Search bar
            searchBar.topAnchor.constraint(equalTo: locationIcon.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: headerContentView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: headerContentView.trailingAnchor, constant: -16),

            // Select date label
            selectDateLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            selectDateLabel.leadingAnchor.constraint(equalTo: headerContentView.leadingAnchor, constant: 16),

            // Date / Time pills
            datePill.topAnchor.constraint(equalTo: selectDateLabel.bottomAnchor, constant: 8),
            datePill.leadingAnchor.constraint(equalTo: headerContentView.leadingAnchor, constant: 16),
            datePill.heightAnchor.constraint(equalToConstant: 30),

            timePill.leadingAnchor.constraint(equalTo: datePill.trailingAnchor, constant: 8),
            timePill.centerYAnchor.constraint(equalTo: datePill.centerYAnchor),
            timePill.heightAnchor.constraint(equalToConstant: 30),
            timePill.bottomAnchor.constraint(equalTo: headerContentView.bottomAnchor, constant: -16)
        ])
        searchHeightConstraint = searchBar.heightAnchor.constraint(equalToConstant: 0)
        searchHeightConstraint?.isActive = true
    }

    // Resize header for AutoLayout
    func layoutHeaderIfNeeded() {
        headerContentView.setNeedsLayout()
        headerContentView.layoutIfNeeded()

        let width = tableView.bounds.width
        let size = headerContentView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        )

        headerContentView.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
        tableView.tableHeaderView = headerContentView
    }

    func setDateText(_ text: String) {
        datePill.setTitle(text, for: .normal)
    }

    func setTimeText(_ text: String) {
        timePill.setTitle(text, for: .normal)
    }

    func useNativeNavigationChrome() {
        headerContainer.isHidden = true
        headerHeightConstraint?.constant = 0
    }

    func toggleSearchVisibility() {
        setSearchVisible(!isSearchVisible)
    }

    func setSearchVisible(_ visible: Bool) {
        isSearchVisible = visible
        searchBar.isHidden = !visible
        searchHeightConstraint?.constant = visible ? 44 : 0
        if visible {
            searchBar.becomeFirstResponder()
        } else {
            searchBar.resignFirstResponder()
        }
        layoutHeaderIfNeeded()
    }

    var tableHeaderContentHeight: CGFloat {
        headerContentView.frame.height
    }
}
