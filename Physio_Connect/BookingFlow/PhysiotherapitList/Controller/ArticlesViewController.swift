//
//  ArticlesViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 02/01/26.
//

import UIKit

final class ArticlesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let articlesView = ArticlesView()
    private let model = ArticlesModel()

    private var articles: [ArticleRow] = []
    private var isRefreshing = false
    private var bookmarkedIDs: Set<UUID> = []

    private let filterOptions = ["All", "Neck", "Upper Back", "Lower Back", "Shoulders"]
    private var selectedFilterIndex = 0
    private var selectedSegmentIndex = 0

    override func loadView() { view = articlesView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        articlesView.tableView.dataSource = self
        articlesView.tableView.delegate = self
        articlesView.searchBar.delegate = self
        articlesView.filterCollectionView.dataSource = self
        articlesView.filterCollectionView.delegate = self

        articlesView.tableView.register(ArticleCardCell.self, forCellReuseIdentifier: ArticleCardCell.reuseID)
        articlesView.filterCollectionView.register(ArticleFilterChipCell.self, forCellWithReuseIdentifier: ArticleFilterChipCell.reuseID)
        articlesView.tableView.rowHeight = UITableView.automaticDimension
        articlesView.tableView.estimatedRowHeight = 320
        articlesView.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 110, right: 0)
        articlesView.tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 110, right: 0)

        articlesView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        articlesView.filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        articlesView.setRefreshTarget(self, action: #selector(refreshPulled))

        for (index, button) in articlesView.segmentButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        }

        articlesView.filterCollectionView.selectItem(at: IndexPath(item: selectedFilterIndex, section: 0), animated: false, scrollPosition: [])
        Task { await reload() }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func filterTapped() {
        let ac = UIAlertController(title: "Filters", message: "Add advanced filters here.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(ac, animated: true)
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        selectedSegmentIndex = sender.tag
        articlesView.setSegmentSelection(selectedSegmentIndex)
        Task { await reload() }
    }

    @objc private func refreshPulled() {
        Task { await reload() }
    }

    private func currentSort() -> ArticleSort {
        switch selectedSegmentIndex {
        case 2: return .topRated
        case 1: return .forYou
        default: return .recent
        }
    }

    private func currentCategory() -> String? {
        guard selectedFilterIndex > 0 else { return nil }
        return filterOptions[selectedFilterIndex]
    }

    private func reload() async {
        if isRefreshing { return }
        isRefreshing = true
        await MainActor.run { self.articlesView.setRefreshing(true) }
        defer {
            Task { @MainActor in
                self.isRefreshing = false
                self.articlesView.setRefreshing(false)
            }
        }

        do {
            let rows = try await model.fetchArticles(
                search: articlesView.searchBar.text,
                category: currentCategory(),
                sort: currentSort()
            )
            await MainActor.run {
                self.articles = rows
                self.articlesView.updateResults(count: rows.count)
                self.articlesView.tableView.reloadData()
            }
        } catch {
            await MainActor.run { self.showError("Articles Error", error.localizedDescription) }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCardCell.reuseID, for: indexPath) as? ArticleCardCell else {
            return UITableViewCell()
        }
        let article = articles[indexPath.row]
        cell.configure(with: article)
        cell.setBookmarked(bookmarkedIDs.contains(article.id))
        cell.onBookmarkTapped = { [weak self] in
            self?.toggleBookmark(for: article, at: indexPath)
        }
        cell.onReadTapped = { [weak self] in
            self?.openDetail(for: article)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articles[indexPath.row]
        openDetail(for: article)
    }

    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        Task { await reload() }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Task { await reload() }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filterOptions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ArticleFilterChipCell.reuseID,
            for: indexPath
        ) as? ArticleFilterChipCell else {
            return UICollectionViewCell()
        }
        let title = filterOptions[indexPath.item]
        cell.configure(title: title, isSelected: indexPath.item == selectedFilterIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilterIndex = indexPath.item
        collectionView.reloadData()
        Task { await reload() }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = filterOptions[indexPath.item]
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let width = title.size(withAttributes: [.font: font]).width + 28
        return CGSize(width: max(60, width), height: 32)
    }

    private func showBookmarkToast(_ isBookmarked: Bool) {
        let title = isBookmarked ? "Saved" : "Removed"
        let message = isBookmarked ? "Added to your bookmarks." : "Removed from your bookmarks."
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(ac, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ac.dismiss(animated: true)
        }
    }

    private func toggleBookmark(for article: ArticleRow, at indexPath: IndexPath) {
        if bookmarkedIDs.contains(article.id) {
            bookmarkedIDs.remove(article.id)
        } else {
            bookmarkedIDs.insert(article.id)
        }
        let isBookmarked = bookmarkedIDs.contains(article.id)
        if let cell = articlesView.tableView.cellForRow(at: indexPath) as? ArticleCardCell {
            cell.setBookmarked(isBookmarked)
        }
        showBookmarkToast(isBookmarked)
    }

    private func openDetail(for article: ArticleRow) {
        let vc = ArticleDetailViewController(article: article)
        vc.onArticleUpdated = { [weak self] updated in
            guard let self = self else { return }
            guard let index = self.articles.firstIndex(where: { $0.id == updated.id }) else { return }
            self.articles[index] = updated
            self.articlesView.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showError(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
