//
//  VideosView.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class VideosView: UIView {

    private let topBar = UIView()
    let titleLabel = UILabel()
    let profileButton = UIButton(type: .system)
    let segmented = UISegmentedControl(items: ["Free Exercises", "My Program"])
    let searchBar = UISearchBar()
    let filterCollectionView: UICollectionView
    let tableView = UITableView(frame: .zero, style: .plain)

    private var searchHeightConstraint: NSLayoutConstraint?
    private var filterHeightConstraint: NSLayoutConstraint?

    private let emptyCard = UIView()
    private let emptyTitle = UILabel()
    private let emptySub = UILabel()
    let redeemButton = UIButton(type: .system)

    private let refreshControl = UIRefreshControl()

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        filterCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E3F0FF")
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showEmptyState(_ show: Bool) {
        emptyCard.isHidden = !show
        tableView.isHidden = show
    }

    func configureEmptyState(title: String, message: String, showRedeem: Bool) {
        emptyTitle.text = title
        emptySub.text = message
        redeemButton.isHidden = !showRedeem
    }

    func setProgramMode(_ enabled: Bool) {
        searchBar.isHidden = enabled
        filterCollectionView.isHidden = enabled
        searchHeightConstraint?.constant = enabled ? 0 : 44
        filterHeightConstraint?.constant = enabled ? 0 : 40
        layoutIfNeeded()
    }

    func setRefreshing(_ refreshing: Bool) {
        if refreshing {
            if !refreshControl.isRefreshing {
                refreshControl.beginRefreshing()
            }
        } else {
            refreshControl.endRefreshing()
        }
    }

    func setRefreshTarget(_ target: Any?, action: Selector) {
        refreshControl.addTarget(target, action: action, for: .valueChanged)
    }

    private func build() {
        topBar.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Exercises"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center

        profileButton.translatesAutoresizingMaskIntoConstraints = false
        let profileConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        profileButton.setImage(UIImage(systemName: "person.circle", withConfiguration: profileConfig), for: .normal)
        profileButton.tintColor = UIColor.black.withAlphaComponent(0.65)

        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentTintColor = UIColor(hex: "1E6EF7")
        segmented.backgroundColor = .white
        segmented.layer.cornerRadius = 16
        segmented.layer.masksToBounds = true
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .selected
        )
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.black.withAlphaComponent(0.65), .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .normal
        )

        searchBar.placeholder = "Search exercises"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.layer.cornerRadius = 16
        searchBar.searchTextField.layer.masksToBounds = true

        filterCollectionView.translatesAutoresizingMaskIntoConstraints = false
        filterCollectionView.backgroundColor = .clear
        filterCollectionView.showsHorizontalScrollIndicator = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl

        emptyCard.translatesAutoresizingMaskIntoConstraints = false
        emptyCard.backgroundColor = .white
        emptyCard.layer.cornerRadius = 22
        emptyCard.layer.shadowColor = UIColor.black.cgColor
        emptyCard.layer.shadowOpacity = 0.08
        emptyCard.layer.shadowRadius = 10
        emptyCard.layer.shadowOffset = CGSize(width: 0, height: 6)
        emptyCard.isHidden = true

        emptyTitle.translatesAutoresizingMaskIntoConstraints = false
        emptyTitle.text = "No Program Yet"
        emptyTitle.font = .systemFont(ofSize: 20, weight: .bold)
        emptyTitle.textColor = .black

        emptySub.translatesAutoresizingMaskIntoConstraints = false
        emptySub.text = "Redeem your physiotherapist's code to unlock your personalized program."
        emptySub.font = .systemFont(ofSize: 14, weight: .regular)
        emptySub.textColor = .darkGray
        emptySub.numberOfLines = 0

        redeemButton.translatesAutoresizingMaskIntoConstraints = false
        redeemButton.setTitle("Redeem Code", for: .normal)
        redeemButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        redeemButton.backgroundColor = UIColor(hex: "1E6EF7")
        redeemButton.setTitleColor(.white, for: .normal)
        redeemButton.layer.cornerRadius = 14
        redeemButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        addSubview(topBar)
        topBar.addSubview(titleLabel)
        topBar.addSubview(profileButton)
        addSubview(segmented)
        addSubview(searchBar)
        addSubview(filterCollectionView)
        addSubview(tableView)
        addSubview(emptyCard)

        emptyCard.addSubview(emptyTitle)
        emptyCard.addSubview(emptySub)
        emptyCard.addSubview(redeemButton)

        searchHeightConstraint = searchBar.heightAnchor.constraint(equalToConstant: 44)
        filterHeightConstraint = filterCollectionView.heightAnchor.constraint(equalToConstant: 40)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 6),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            profileButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40),

            segmented.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            segmented.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 44),

            searchBar.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            filterCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            filterCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            filterCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: filterCollectionView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            emptyCard.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            emptyCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            emptyTitle.topAnchor.constraint(equalTo: emptyCard.topAnchor, constant: 18),
            emptyTitle.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 18),
            emptyTitle.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -18),

            emptySub.topAnchor.constraint(equalTo: emptyTitle.bottomAnchor, constant: 10),
            emptySub.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 18),
            emptySub.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -18),

            redeemButton.topAnchor.constraint(equalTo: emptySub.bottomAnchor, constant: 16),
            redeemButton.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 18),
            redeemButton.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -18),
            redeemButton.bottomAnchor.constraint(equalTo: emptyCard.bottomAnchor, constant: -18)
        ])

        searchHeightConstraint?.isActive = true
        filterHeightConstraint?.isActive = true
    }
}
