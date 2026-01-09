//
//  PhysioEditProfileView.swift
//  Physio_Connect
//
//  Created by Codex on 09/01/26.
//

import UIKit

final class PhysioEditProfileView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let saveButton = UIButton(type: .system)

    private let nameField = PhysioLabeledTextField(title: "Full Name", placeholder: "User")
    private let phoneField = PhysioLabeledTextField(title: "Phone", placeholder: "Phone number")
    private let genderField = PhysioLabeledTextField(title: "Gender", placeholder: "Gender")
    private let customGenderField = PhysioLabeledTextField(title: "Custom Gender", placeholder: "Enter your gender")
    private let dobField = PhysioLabeledTextField(title: "Date of Birth", placeholder: "YYYY-MM-DD")
    private let locationField = PhysioLabeledTextField(title: "Location", placeholder: "City")
    private let genderPicker = UIPickerView()
    private let dobPicker = UIDatePicker()
    private let genderOptions = ["male", "female"]
    private var selectedGenderIndex = 0
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E8EEF5")
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ data: ProfileViewData) {
        nameField.text = data.name == "—" ? "" : data.name
        locationField.text = data.location == "—" ? "" : data.location
        phoneField.text = data.phone == "—" ? "" : data.phone
        applyGenderText(data.gender == "—" ? "" : data.gender)
        if data.dateOfBirth != "—" {
            dobField.text = data.dateOfBirth
            if let date = Self.dateFormatter.date(from: data.dateOfBirth) {
                dobPicker.date = date
            }
        } else {
            dobField.text = ""
        }
    }

    func currentInput() -> PhysioProfileModel.UpdateInput {
        let resolvedGender: String = {
            let selection = genderField.text
            return selection
        }()
        return PhysioProfileModel.UpdateInput(
            name: nameField.text,
            gender: resolvedGender,
            location: locationField.text,
            placeOfWork: phoneField.text,
            phone: phoneField.text,
            dateOfBirth: dobField.text,
            profileImagePath: ""
        )
    }

    func setSaving(_ saving: Bool) {
        saveButton.isEnabled = !saving
        saveButton.alpha = saving ? 0.6 : 1
    }

    private func build() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        buildTopBar()
        buildForm()
    }

    private func buildTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.layer.cornerRadius = 0
        topBar.backgroundColor = .clear

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: "1E6EF7")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Edit Profile"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(UIColor(hex: "1E6EF7"), for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)
        topBar.addSubview(saveButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            backButton.widthAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            saveButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            saveButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])

        topBar.heightAnchor.constraint(equalToConstant: 52).isActive = true
        stackView.addArrangedSubview(topBar)
    }

    private func buildForm() {
        let card = makeCardView()
        let formStack = UIStackView()
        formStack.axis = .vertical
        formStack.spacing = 14
        formStack.translatesAutoresizingMaskIntoConstraints = false

        genderPicker.dataSource = self
        genderPicker.delegate = self
        genderField.setInputView(genderPicker, toolbarTitle: "Select Gender")
        customGenderField.isHidden = true
        phoneField.textField.keyboardType = .phonePad
        dobField.textField.keyboardType = .numbersAndPunctuation
        dobPicker.datePickerMode = .date
        dobPicker.preferredDatePickerStyle = .wheels
        dobPicker.maximumDate = Date()
        dobPicker.addTarget(self, action: #selector(dobChanged), for: .valueChanged)
        dobField.setInputView(dobPicker, toolbarTitle: "Select Date")

        formStack.addArrangedSubview(nameField)
        formStack.addArrangedSubview(phoneField)
        formStack.addArrangedSubview(genderField)
        formStack.addArrangedSubview(dobField)
        formStack.addArrangedSubview(locationField)

        card.addSubview(formStack)

        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            formStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            formStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(card)
    }

    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        return view
    }

    @objc private func backTapped() { onBack?() }
    @objc private func saveTapped() { onSave?() }
    @objc private func dobChanged() {
        dobField.text = Self.dateFormatter.string(from: dobPicker.date)
    }

    private func applyGenderText(_ text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            genderField.text = ""
            customGenderField.text = ""
            customGenderField.isHidden = true
            return
        }
        if let index = genderOptions.firstIndex(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            selectedGenderIndex = index
            genderPicker.selectRow(index, inComponent: 0, animated: false)
            genderField.text = genderOptions[index]
            customGenderField.text = ""
            customGenderField.isHidden = true
        } else {
            selectedGenderIndex = genderOptions.count - 1
            genderPicker.selectRow(selectedGenderIndex, inComponent: 0, animated: false)
            genderField.text = genderOptions[selectedGenderIndex]
            customGenderField.text = ""
            customGenderField.isHidden = true
        }
    }

    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { genderOptions.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { genderOptions[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderField.text = genderOptions[row]
        selectedGenderIndex = row
        customGenderField.isHidden = true
        customGenderField.text = ""
    }
}
