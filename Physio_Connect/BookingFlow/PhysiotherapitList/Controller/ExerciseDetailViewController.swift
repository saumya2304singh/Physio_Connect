//
//  ExerciseDetailViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit
import AVKit

final class ExerciseDetailViewController: UIViewController {

    private let videosModel = VideosModel()

    private let titleText: String
    private let subtitleText: String
    private let descriptionText: String?
    private let durationSeconds: Int?
    private let videoPath: String
    private let thumbnailPath: String?
    private let programID: UUID?
    private let exerciseID: UUID
    private let sets: Int?
    private let reps: Int?
    private let hold: Int?

    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let headerTitle = UILabel()
    private let videoCard = UIView()
    private let thumbnailImageView = UIImageView()
    private let playButton = UIButton(type: .system)
    private let metaTitle = UILabel()
    private let metaSub = UILabel()
    private let metaDesc = UILabel()
    private let metaExtra = UILabel()
    private let completeButton = UIButton(type: .system)

    init(titleText: String,
         subtitle: String,
         descriptionText: String?,
         durationSeconds: Int?,
         videoPath: String,
         thumbnailPath: String?,
         programID: UUID?,
         exerciseID: UUID,
         sets: Int?,
         reps: Int?,
         hold: Int?) {
        self.titleText = titleText
        self.subtitleText = subtitle
        self.descriptionText = descriptionText
        self.durationSeconds = durationSeconds
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
        self.programID = programID
        self.exerciseID = exerciseID
        self.sets = sets
        self.reps = reps
        self.hold = hold
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "E3F0FF")
        navigationItem.titleView = nil
        buildUI()
        loadThumbnail()
    }

    private func buildUI() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 14

        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.text = "Video"
        headerTitle.font = .boldSystemFont(ofSize: 20)
        headerTitle.textColor = .black
        view.addSubview(headerTitle)
        view.addSubview(scroll)
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            headerTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scroll.topAnchor.constraint(equalTo: headerTitle.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        videoCard.translatesAutoresizingMaskIntoConstraints = false
        videoCard.backgroundColor = .white
        videoCard.layer.cornerRadius = 24
        videoCard.layer.shadowColor = UIColor.black.cgColor
        videoCard.layer.shadowOpacity = 0.08
        videoCard.layer.shadowRadius = 12
        videoCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 24
        thumbnailImageView.backgroundColor = UIColor(hex: "E3F0FF")

        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = UIColor(hex: "1E6EF7")
        playButton.backgroundColor = .white
        playButton.layer.cornerRadius = 28
        playButton.layer.shadowColor = UIColor.black.cgColor
        playButton.layer.shadowOpacity = 0.12
        playButton.layer.shadowRadius = 10
        playButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        videoCard.addSubview(thumbnailImageView)
        videoCard.addSubview(playButton)
        NSLayoutConstraint.activate([
            videoCard.heightAnchor.constraint(equalToConstant: 220),
            thumbnailImageView.topAnchor.constraint(equalTo: videoCard.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: videoCard.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: videoCard.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: videoCard.bottomAnchor),
            playButton.centerXAnchor.constraint(equalTo: videoCard.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: videoCard.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 56),
            playButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        metaTitle.font = .systemFont(ofSize: 22, weight: .bold)
        metaTitle.textColor = .black
        metaTitle.numberOfLines = 0
        metaTitle.text = titleText

        metaSub.font = .systemFont(ofSize: 14, weight: .semibold)
        metaSub.textColor = .darkGray
        metaSub.numberOfLines = 0
        metaSub.text = subtitleText

        metaDesc.font = .systemFont(ofSize: 14, weight: .regular)
        metaDesc.textColor = .black
        metaDesc.numberOfLines = 0
        metaDesc.text = descriptionText ?? "Follow the guided video and maintain controlled movement throughout."

        let mins = max(1, (durationSeconds ?? 0) / 60)
        var extras = ["Duration: \(mins) min"]
        if let sets { extras.append("Sets: \(sets)") }
        if let reps { extras.append("Reps: \(reps)") }
        if let hold { extras.append("Hold: \(hold)s") }

        metaExtra.font = .systemFont(ofSize: 13, weight: .semibold)
        metaExtra.textColor = UIColor(hex: "1E6EF7")
        metaExtra.numberOfLines = 0
        metaExtra.text = extras.joined(separator: " - ")

        completeButton.translatesAutoresizingMaskIntoConstraints = false
        completeButton.setTitle("Mark as Completed", for: .normal)
        completeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        completeButton.backgroundColor = UIColor(hex: "1E6EF7")
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.layer.cornerRadius = 16
        completeButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)

        content.addArrangedSubview(videoCard)
        content.addArrangedSubview(metaTitle)
        content.addArrangedSubview(metaSub)
        content.addArrangedSubview(metaExtra)
        content.addArrangedSubview(metaDesc)
        content.addArrangedSubview(completeButton)
    }

    @objc private func playTapped() {
        Task {
            do {
                let url = try await videosModel.signedVideoURL(path: videoPath)
                let player = AVPlayer(url: url)
                let vc = AVPlayerViewController()
                vc.player = player
                present(vc, animated: true) {
                    player.play()
                }
            } catch {
                showError("Video error", error.localizedDescription)
            }
        }
    }

    private func loadThumbnail() {
        guard let thumbnailPath else { return }
        Task {
            do {
                let url = try await videosModel.signedThumbnailURL(path: thumbnailPath)
                await MainActor.run {
                    self.thumbnailImageView.image = UIImage(systemName: "photo")
                    let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                        guard let self, let data, let image = UIImage(data: data) else { return }
                        DispatchQueue.main.async {
                            self.thumbnailImageView.image = image
                        }
                    }
                    task.resume()
                }
            } catch {
                return
            }
        }
    }

    @objc private func completeTapped() {
        let ac = UIAlertController(title: "Log Pain (optional)",
                                   message: "How was your pain during the exercise? (0-10)",
                                   preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Pain level (0-10)"
            tf.keyboardType = .numberPad
        }
        ac.addAction(UIAlertAction(title: "Skip", style: .cancel) { [weak self] _ in
            self?.saveProgress(pain: nil)
        })
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let t = ac.textFields?.first?.text ?? ""
            let pain = Int(t)
            self?.saveProgress(pain: pain)
        })
        present(ac, animated: true)
    }

    private func saveProgress(pain: Int?) {
        Task {
            do {
                try await videosModel.upsertProgress(
                    exerciseID: exerciseID,
                    programID: programID,
                    isCompleted: true,
                    watchedSeconds: durationSeconds ?? 0,
                    painLevel: pain,
                    notes: nil
                )
                let done = UIAlertController(title: "Saved", message: "Progress updated.", preferredStyle: .alert)
                done.addAction(UIAlertAction(title: "OK", style: .default))
                present(done, animated: true)
            } catch {
                showError("Save failed", error.localizedDescription)
            }
        }
    }

    private func showError(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
