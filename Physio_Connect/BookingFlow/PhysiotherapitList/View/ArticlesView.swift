//
//  ArticlesView.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class ArticlesView: UIView {

    private let topBar = UIView()
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let filterButton = UIButton(type: .system)

    let searchBar = UISearchBar()
    let segmentStack = UIStackView()
    let segmentButtons: [UIButton] = [
        UIButton(type: .system),
        UIButton(type: .system),
        UIButton(type: .system)
    ]

    let resultsLabel = UILabel()
    let filterCollectionView: UICollectionView
    let tableView = UITableView(frame: .zero, style: .plain)

    private let refreshControl = UIRefreshControl()

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        filterCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "F2F6FB")
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSegmentSelection(_ index: Int) {
        for (idx, button) in segmentButtons.enumerated() {
            applySegmentStyle(button, selected: idx == index)
        }
    }

    func updateResults(count: Int) {
        resultsLabel.text = "\(count) article\(count == 1 ? "" : "s") found"
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

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 20
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOpacity = 0.08
        backButton.layer.shadowRadius = 6
        backButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        let backConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backConfig), for: .normal)
        backButton.tintColor = UIColor.black.withAlphaComponent(0.7)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Articles & Resources"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black

        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.backgroundColor = UIColor(hex: "E8F7FF")
        filterButton.layer.cornerRadius = 20
        let filterConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        filterButton.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: filterConfig), for: .normal)
        filterButton.tintColor = UIColor(hex: "1E6EF7")

        searchBar.placeholder = "Search articles, topics, conditions..."
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.layer.cornerRadius = 16
        searchBar.searchTextField.layer.masksToBounds = true

        segmentStack.axis = .horizontal
        segmentStack.spacing = 10
        segmentStack.translatesAutoresizingMaskIntoConstraints = false

        let segmentTitles = ["All", "For You", "Top Rated"]
        let segmentIcons = ["drop.fill", "sparkles", "star.fill"]
        for (index, button) in segmentButtons.enumerated() {
            configureSegmentButton(button, title: segmentTitles[index], icon: segmentIcons[index])
            segmentStack.addArrangedSubview(button)
        }
        setSegmentSelection(0)

        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        resultsLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        resultsLabel.text = "0 articles found"

        filterCollectionView.translatesAutoresizingMaskIntoConstraints = false
        filterCollectionView.backgroundColor = .clear
        filterCollectionView.showsHorizontalScrollIndicator = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl

        addSubview(topBar)
        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)
        topBar.addSubview(filterButton)

        addSubview(searchBar)
        addSubview(segmentStack)
        addSubview(resultsLabel)
        addSubview(filterCollectionView)
        addSubview(tableView)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 6),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            filterButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            filterButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 40),
            filterButton.heightAnchor.constraint(equalToConstant: 40),

            searchBar.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            segmentStack.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            segmentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            resultsLabel.topAnchor.constraint(equalTo: segmentStack.bottomAnchor, constant: 12),
            resultsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            resultsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            filterCollectionView.topAnchor.constraint(equalTo: resultsLabel.bottomAnchor, constant: 8),
            filterCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            filterCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            filterCollectionView.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: filterCollectionView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureSegmentButton(_ button: UIButton, title: String, icon: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowRadius = 6
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let image = UIImage(systemName: icon, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.setTitle(" \(title)", for: .normal)
    }

    private func applySegmentStyle(_ button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = UIColor(hex: "1E6EF7")
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
        } else {
            button.backgroundColor = .white
            button.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
            button.tintColor = UIColor.black.withAlphaComponent(0.6)
        }
    }
}
