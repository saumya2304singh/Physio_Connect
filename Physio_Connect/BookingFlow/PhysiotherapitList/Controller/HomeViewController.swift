//
//  HomeViewController.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 31/12/25.
//

import UIKit

final class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {

    private let homeView = HomeView()
    private let model = HomeModel()
    private let videosModel = VideosModel()
    private let articlesModel = ArticlesModel()
    private var currentUpcoming: HomeUpcomingAppointment?
    private var upcomingTimer: Timer?
    private var freeVideos: [ExerciseVideoRow] = []
    private var thumbnailImages: [UUID: UIImage] = [:]
    private var nextProgramExercise: MyProgramExerciseRow?
    private var programExercises: [MyProgramExerciseRow] = []
    private var articles: [ArticleRow] = []
    private var articleImages: [UUID: UIImage] = [:]
    private var selectedArticlesSort: ArticleSort = .topRated

    override func loadView() { view = homeView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        homeView.profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        homeView.videosCollectionView.dataSource = self
        homeView.videosCollectionView.delegate = self
        homeView.videosCollectionView.register(HomeVideoCardCell.self, forCellWithReuseIdentifier: HomeVideoCardCell.reuseID)
        homeView.videosActionButton.addTarget(self, action: #selector(viewAllVideos), for: .touchUpInside)
        homeView.articlesTableView.dataSource = self
        homeView.articlesTableView.delegate = self
        homeView.articlesTableView.register(HomeArticleCell.self, forCellReuseIdentifier: HomeArticleCell.reuseID)
        homeView.articlesSegmented.addTarget(self, action: #selector(articleSegmentChanged), for: .valueChanged)

        homeView.carousel.onViewDetailsTapped = { [weak self] appt in
            guard let self else { return }
            let appointment = self.makeAppointment(from: appt)
            let vc = AppointmentDetailsViewController(appointment: appointment)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        homeView.carousel.onBookTapped = { [weak self] in
            guard let self else { return }
            let vc = PhysiotherapistListViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        homeView.upNextCard.primaryButton.addTarget(self, action: #selector(startNextExercise), for: .touchUpInside)

        Task { await refreshCards() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await refreshCards() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        upcomingTimer?.invalidate()
        upcomingTimer = nil
    }

    private func refreshCards() async {
        do {
            let upcoming = try await model.fetchUpcomingAppointment()
            let videos = try await videosModel.fetchFreeExercises(search: nil)
            let progress = try await model.fetchProgressSummary()
            let fetchedArticles = try await articlesModel.fetchArticles(search: nil, category: nil, sort: selectedArticlesSort)
            let programRows = try await videosModel.fetchMyProgramExercises()
            let nextExercise = try await resolveNextExercise(from: programRows)
            await MainActor.run {
                self.applyUpcoming(upcoming)
                self.freeVideos = Array(videos.prefix(4))
                self.thumbnailImages = [:]
                self.homeView.videosCollectionView.reloadData()
                self.homeView.updateVideosHeight(rows: self.freeVideos.count)
                self.homeView.painCard.configure(
                    painSeries: progress.painSeries,
                    averagePain: progress.averagePain,
                    percentChange: progress.painDeltaPercent
                )
                self.homeView.adherenceCard.configure(
                    adherenceSeries: progress.adherenceSeries,
                    weeklyPercent: progress.weeklyAdherencePercent
                )
                self.programExercises = programRows
                self.nextProgramExercise = nextExercise
                self.applyUpNext()
                self.articles = Array(fetchedArticles.prefix(4))
                self.articleImages = [:]
                self.homeView.articlesTableView.reloadData()
                self.homeView.updateArticlesHeight(rows: self.articles.count)
                DispatchQueue.main.async {
                    self.homeView.updateArticlesHeightToFit()
                }
            }
            loadThumbnails(for: Array(videos.prefix(4)))
            loadArticleImages(for: Array(fetchedArticles.prefix(4)))
        } catch {
            await MainActor.run {
                self.applyUpcoming(nil)
                self.homeView.setUpNextVisible(false)
            }
            print("❌ Home refresh error:", error)
        }
    }

    private func applyUpNext() {
        guard let nextProgramExercise else {
            homeView.setUpNextVisible(false)
            return
        }
        homeView.setUpNextVisible(true)
        let totalExercises = programExercises.count
        let totalMinutes = max(1, programExercises.reduce(0) { $0 + (($1.duration_seconds ?? 0) / 60) })
        let meta = "\(totalExercises) exercises • \(totalMinutes) minutes"
        let vm = HomeUpNextCardView.ViewModel(
            timeText: "Next in your program",
            title: nextProgramExercise.title,
            metaText: meta,
            primaryTitle: "Start Session"
        )
        homeView.upNextCard.configure(with: vm)
    }

    private func resolveNextExercise(from rows: [MyProgramExerciseRow]) async throws -> MyProgramExerciseRow? {
        guard let programID = rows.first?.program_id else { return nil }
        let progressRows = try await videosModel.fetchProgress(programID: programID)
        let completed = Set(progressRows.filter { $0.is_completed == true }.map { $0.exercise_id })
        if let next = rows.first(where: { !completed.contains($0.exercise_id) }) {
            return next
        }
        return rows.last
    }

    private func applyUpcoming(_ appt: HomeUpcomingAppointment?) {
        upcomingTimer?.invalidate()
        upcomingTimer = nil
        currentUpcoming = nil

        guard let appt, appt.startTime > Date() else {
            homeView.setUpcoming(nil)
            return
        }

        currentUpcoming = appt
        homeView.setUpcoming(appt)

        let interval = appt.startTime.timeIntervalSinceNow
        guard interval > 0 else { return }
        upcomingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.currentUpcoming = nil
            self.homeView.setUpcoming(nil)
        }
    }

    private func makeAppointment(from appt: HomeUpcomingAppointment) -> Appointment {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd MMM"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let status: AppointmentStatus
        switch appt.status.lowercased() {
        case "completed":
            status = .completed
        case "cancelled", "canceled":
            status = .cancelled
        default:
            status = .upcoming
        }

        return Appointment(
            id: appt.appointmentID,
            doctorName: appt.physioName,
            specialization: appt.specializationText,
            ratingText: appt.ratingText,
            dateText: dateFormatter.string(from: appt.startTime),
            timeText: timeFormatter.string(from: appt.startTime),
            status: status,
            sessionNotes: "",
            phoneNumber: nil,
            locationText: appt.address,
            feeText: appt.consultationFeeText,
            profileImagePath: appt.profileImagePath,
            profileImageVersion: appt.profileImageVersion
        )
    }

    @objc private func profileTapped() {
        let vc = ProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func viewAllVideos() {
        guard let tabs = tabBarController else { return }
        let targetIndex = 2
        if let nav = tabs.viewControllers?[targetIndex] as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
        tabs.selectedIndex = targetIndex
    }

    @objc private func articleSegmentChanged() {
        selectedArticlesSort = homeView.articlesSegmented.selectedSegmentIndex == 0 ? .topRated : .forYou
        Task { await refreshCards() }
    }

    @objc private func startNextExercise() {
        guard let exercise = nextProgramExercise else { return }
        let vc = ExerciseDetailViewController(
            headerTitleText: exercise.program_title,
            titleText: exercise.title,
            subtitle: exercise.target_area ?? "Upper Body",
            descriptionText: exercise.description,
            durationSeconds: exercise.duration_seconds,
            videoPath: exercise.video_path,
            thumbnailPath: exercise.thumbnail_path,
            programID: exercise.program_id,
            exerciseID: exercise.exercise_id,
            sets: exercise.sets,
            reps: exercise.reps,
            hold: exercise.hold_seconds,
            nextUpItems: []
        )
        navigationController?.pushViewController(vc, animated: true)
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        freeVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeVideoCardCell.reuseID, for: indexPath) as? HomeVideoCardCell else {
            return UICollectionViewCell()
        }
        let video = freeVideos[indexPath.item]
        let thumbnail = thumbnailImages[video.id]
        cell.configure(with: video, thumbnail: thumbnail)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = freeVideos[indexPath.item]
        let vc = ExerciseDetailViewController(
            headerTitleText: "Free Exercise",
            titleText: video.title,
            subtitle: video.target_area ?? "Upper Body",
            descriptionText: video.description,
            durationSeconds: video.duration_seconds,
            videoPath: video.video_path,
            thumbnailPath: video.thumbnail_path,
            programID: nil,
            exerciseID: video.id,
            sets: nil,
            reps: nil,
            hold: nil,
            nextUpItems: []
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let itemWidth = (width - 12) / 2
        return CGSize(width: itemWidth, height: 160)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeArticleCell.reuseID, for: indexPath) as? HomeArticleCell else {
            return UITableViewCell()
        }
        let article = articles[indexPath.row]
        let image = articleImages[article.id]
        cell.configure(with: article, thumbnail: image)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articles[indexPath.row]
        let vc = ArticleDetailViewController(article: article)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadThumbnails(for videos: [ExerciseVideoRow]) {
        for video in videos {
            guard let path = video.thumbnail_path, !path.isEmpty else { continue }
            Task {
                do {
                    let signedURL = try await videosModel.signedThumbnailURL(path: path)
                    ImageLoader.shared.load(signedURL) { [weak self] image in
                        guard let self, let image else { return }
                        self.thumbnailImages[video.id] = image
                        if let index = self.freeVideos.firstIndex(where: { $0.id == video.id }) {
                            self.homeView.videosCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                        }
                    }
                } catch {
                    print("❌ Thumbnail error:", error)
                }
            }
        }
    }

    private func loadArticleImages(for articles: [ArticleRow]) {
        for article in articles {
            let pathOrUrl = article.image_path ?? article.image_url
            guard let pathOrUrl, !pathOrUrl.isEmpty else { continue }
            Task {
                do {
                    let url = try await articlesModel.signedImageURL(pathOrUrl: pathOrUrl)
                    ImageLoader.shared.load(url) { [weak self] image in
                        guard let self, let image else { return }
                        self.articleImages[article.id] = image
                        if let index = self.articles.firstIndex(where: { $0.id == article.id }) {
                            self.homeView.articlesTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                    }
                } catch {
                    print("❌ Article image error:", error)
                }
            }
        }
    }
}
