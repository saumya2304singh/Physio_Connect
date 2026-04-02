//
//  EditProfileView.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class EditProfileView: UIView {

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private var topBarHeightConstraint: NSLayoutConstraint?

    private let nameField = LabeledTextField(title: "Full Name", placeholder: "Your name")
    private let phoneField = LabeledTextField(title: "Phone", placeholder: "Phone number")
    private let genderField = LabeledSelectionField(title: "Gender", placeholder: "Select Gender")
    private let customGenderField = LabeledTextField(title: "Custom Gender", placeholder: "Your gender")
    private let dobField = LabeledSelectionField(title: "Date of Birth", placeholder: "Select Date of Birth")
    private let dobInlineContainer = UIView()
    private let addressLine1Field = LabeledTextField(title: "Address Line 1", placeholder: "House no, street")
    private let addressLine2Field = LabeledTextField(title: "Address Line 2", placeholder: "Area, landmark (optional)")
    private let pinCodeField = LabeledTextField(title: "Pincode", placeholder: "6-digit pincode")
    private let locationField = LabeledSelectionField(title: "Location", placeholder: "Select Location")
    private let dobPicker = UIDatePicker()
    private var dobInlineHeightConstraint: NSLayoutConstraint?
    private let genderOptions = ["Male", "Female", "Other"]
    private let locationOptions = [
        "Bengaluru",
        "Chennai",
        "Delhi",
        "Hyderabad",
        "Kolkata",
        "Mumbai",
        "Pune"
    ]
    private let phonePrefix = "+91"
    private var selectedGenderIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E8EEF5")
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ data: ProfileViewData) {
        nameField.text = data.name == "—" ? "" : data.name
        let rawPhone = data.phone == "—" ? "" : data.phone
        phoneField.text = normalizedPhoneDigits(from: rawPhone)
        let genderText = data.gender == "—" ? "" : data.gender
        applyGenderText(genderText)
        dobField.text = data.dateOfBirth == "—" ? "Select Date of Birth" : data.dateOfBirth
        let resolvedAddress = data.address == "—" ? "" : data.address
        let parsedAddress = parseAddressComponents(from: resolvedAddress)
        addressLine1Field.text = parsedAddress.line1
        addressLine2Field.text = parsedAddress.line2
        pinCodeField.text = parsedAddress.pincode
        let resolvedLocation = data.location == "—" ? "" : data.location
        locationField.text = resolvedLocation.isEmpty ? "Select Location" : resolvedLocation
        if let parsed = Self.dateFormatter.date(from: dobField.text) {
            dobPicker.date = parsed
        }
    }

    func setSaving(_ saving: Bool) {
        saveButton.isEnabled = !saving
        saveButton.alpha = saving ? 0.6 : 1.0
    }

    func currentInput() -> ProfileModel.ProfileUpdateInput {
        let resolvedGender: String = {
            let selection = genderField.text
            if selection == "Select Gender" { return "" }
            if selection == "Other" {
                return customGenderField.text
            }
            return selection
        }()
        let digits = normalizedPhoneDigits(from: phoneField.text)
        let normalizedPhone = digits.isEmpty ? "" : "\(phonePrefix)\(digits)"
        let dobValue = dobField.text == "Select Date of Birth" ? "" : dobField.text
        let locationValue = locationField.text == "Select Location" ? "" : locationField.text
        let fullAddress = composeAddress(
            line1: addressLine1Field.text,
            line2: addressLine2Field.text,
            pincode: pinCodeField.text
        )
        return ProfileModel.ProfileUpdateInput(
            name: nameField.text,
            phone: normalizedPhone,
            gender: resolvedGender,
            dateOfBirth: dobValue,
            address: fullAddress,
            location: locationValue
        )
    }

    func isPhoneValidForSave() -> Bool {
        let digits = normalizedPhoneDigits(from: phoneField.text)
        return digits.isEmpty || digits.count == 10
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
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        buildTopBar()
        buildForm()
    }

    private func buildTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: "1E6EF7")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Edit Profile"
        titleLabel.font = UITheme.Typography.sectionTitle
        titleLabel.textColor = UIColor.black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = UITheme.Typography.buttonSmall
        saveButton.backgroundColor = UIColor(hex: "1E6EF7")
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 9, left: 16, bottom: 9, right: 16)
        saveButton.layer.cornerRadius = 20
        saveButton.layer.cornerCurve = .continuous
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

        topBarHeightConstraint = topBar.heightAnchor.constraint(equalToConstant: 44)
        topBarHeightConstraint?.isActive = true
        stackView.addArrangedSubview(topBar)
    }

    func useNativeNavigationChrome() {
        topBar.isHidden = true
        topBarHeightConstraint?.constant = 0
    }

    private func buildForm() {
        let card = makeCardView()
        let formStack = UIStackView()
        formStack.axis = .vertical
        formStack.spacing = 12
        formStack.translatesAutoresizingMaskIntoConstraints = false

        phoneField.keyboardType = .phonePad
        phoneField.setFixedPrefix(phonePrefix)
        phoneField.onTextChanged = { [weak self] text in
            guard let self else { return }
            let digits = self.normalizedPhoneDigits(from: text)
            if digits != text {
                self.phoneField.text = digits
            }
        }

        genderField.onTap = { [weak self] in
            self?.presentGenderMenu()
        }
        customGenderField.isHidden = true

        dobPicker.datePickerMode = .date
        dobPicker.maximumDate = Date()
        if #available(iOS 14.0, *) {
            dobPicker.preferredDatePickerStyle = .inline
        }
        dobPicker.addTarget(self, action: #selector(dobChanged), for: .valueChanged)
        dobField.onTap = { [weak self] in
            self?.setDOBPickerVisible(!(self?.isDOBPickerVisible ?? false))
        }

        dobInlineContainer.translatesAutoresizingMaskIntoConstraints = false
        dobInlineContainer.backgroundColor = UIColor(hex: "F2F6FB")
        dobInlineContainer.layer.cornerRadius = 14
        dobInlineContainer.layer.cornerCurve = .continuous
        dobInlineContainer.clipsToBounds = true
        dobInlineContainer.isHidden = true

        dobPicker.translatesAutoresizingMaskIntoConstraints = false
        dobInlineContainer.addSubview(dobPicker)
        NSLayoutConstraint.activate([
            dobPicker.topAnchor.constraint(equalTo: dobInlineContainer.topAnchor, constant: 8),
            dobPicker.leadingAnchor.constraint(equalTo: dobInlineContainer.leadingAnchor, constant: 8),
            dobPicker.trailingAnchor.constraint(equalTo: dobInlineContainer.trailingAnchor, constant: -8),
            dobPicker.bottomAnchor.constraint(equalTo: dobInlineContainer.bottomAnchor, constant: -8)
        ])
        dobInlineHeightConstraint = dobInlineContainer.heightAnchor.constraint(equalToConstant: 0)
        dobInlineHeightConstraint?.isActive = true

        locationField.onTap = { [weak self] in
            self?.presentLocationMenu()
        }
        pinCodeField.keyboardType = .numberPad
        pinCodeField.onTextChanged = { [weak self] text in
            guard let self else { return }
            let digits = text.filter(\.isNumber)
            let trimmed = String(digits.prefix(6))
            if trimmed != text {
                self.pinCodeField.text = trimmed
            }
        }

        formStack.addArrangedSubview(nameField)
        formStack.addArrangedSubview(phoneField)
        formStack.addArrangedSubview(genderField)
        formStack.addArrangedSubview(customGenderField)
        formStack.addArrangedSubview(dobField)
        formStack.addArrangedSubview(dobInlineContainer)
        formStack.addArrangedSubview(addressLine1Field)
        formStack.addArrangedSubview(addressLine2Field)
        formStack.addArrangedSubview(pinCodeField)
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

    @objc private func backTapped() {
        onBack?()
    }

    @objc private func saveTapped() {
        onSave?()
    }

    @objc private func dobChanged() {
        dobField.text = Self.dateFormatter.string(from: dobPicker.date)
    }

    private func applyGenderText(_ text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            genderField.text = "Select Gender"
            customGenderField.text = ""
            customGenderField.isHidden = true
            return
        }
        if let index = genderOptions.firstIndex(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            selectedGenderIndex = index
            genderField.text = genderOptions[index]
            customGenderField.text = ""
            customGenderField.isHidden = genderOptions[index] != "Other"
        } else {
            selectedGenderIndex = genderOptions.count - 1
            genderField.text = "Other"
            customGenderField.text = normalized
            customGenderField.isHidden = false
        }
    }

    private func normalizedPhoneDigits(from raw: String) -> String {
        var digits = raw.filter(\.isNumber)
        if digits.hasPrefix("91"), digits.count > 10 {
            digits = String(digits.dropFirst(2))
        }
        return String(digits.prefix(10))
    }

    private func presentGenderMenu() {
        guard let host = parentViewController() else { return }
        let alert = UIAlertController(title: "Select Gender", message: nil, preferredStyle: .actionSheet)
        for (index, option) in genderOptions.enumerated() {
            alert.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                guard let self else { return }
                self.selectedGenderIndex = index
                self.genderField.text = option
                if option == "Other" {
                    self.customGenderField.isHidden = false
                } else {
                    self.customGenderField.isHidden = true
                    self.customGenderField.text = ""
                }
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            let anchorRect = genderField.anchorView.convert(genderField.anchorView.bounds, to: self)
            popover.sourceView = self
            popover.sourceRect = CGRect(
                x: anchorRect.midX,
                y: anchorRect.maxY + 8,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = [.up]
        }
        host.present(alert, animated: true)
    }

    private func presentLocationMenu() {
        guard let host = parentViewController() else { return }
        let alert = UIAlertController(title: "Select Location", message: nil, preferredStyle: .actionSheet)
        for option in locationOptions {
            alert.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.locationField.text = option
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            let anchorRect = locationField.anchorView.convert(locationField.anchorView.bounds, to: self)
            popover.sourceView = self
            popover.sourceRect = CGRect(
                x: anchorRect.midX,
                y: anchorRect.maxY + 8,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = [.up]
        }
        host.present(alert, animated: true)
    }

    private var isDOBPickerVisible: Bool {
        !(dobInlineHeightConstraint?.constant == 0)
    }

    private func setDOBPickerVisible(_ visible: Bool) {
        dobInlineContainer.isHidden = !visible
        dobInlineHeightConstraint?.constant = visible ? 330 : 0
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    private func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }

    private func parseAddressComponents(from raw: String) -> (line1: String, line2: String, pincode: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", "", "") }

        var mutable = trimmed
        var pincode = ""
        if let pinRange = mutable.range(of: #"\b\d{6}\b"#, options: .regularExpression) {
            pincode = String(mutable[pinRange])
            mutable.removeSubrange(pinRange)
        }

        let parts = mutable
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.isEmpty {
            return ("", "", pincode)
        }
        if parts.count == 1 {
            return (parts[0], "", pincode)
        }
        return (parts[0], parts[1], pincode)
    }

    private func composeAddress(line1: String, line2: String, pincode: String) -> String {
        let l1 = line1.trimmingCharacters(in: .whitespacesAndNewlines)
        let l2 = line2.trimmingCharacters(in: .whitespacesAndNewlines)
        let pin = String(pincode.filter(\.isNumber).prefix(6))

        var parts: [String] = []
        if !l1.isEmpty { parts.append(l1) }
        if !l2.isEmpty { parts.append(l2) }
        if !pin.isEmpty { parts.append(pin) }
        return parts.joined(separator: "\n")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private final class LabeledTextField: UIView {
    private let titleLabel = UILabel()
    private let textField = UITextField()

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }
    var onTextChanged: ((String) -> Void)?
    var onTap: (() -> Void)?
    var anchorView: UIView { textField }

    func setInputView(_ view: UIView, toolbarTitle: String) {
        textField.inputView = view
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let title = UIBarButtonItem(title: toolbarTitle, style: .plain, target: nil, action: nil)
        title.isEnabled = false
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        toolbar.setItems([title, flex, done], animated: false)
        textField.inputAccessoryView = toolbar
    }

    init(title: String, placeholder: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = UITheme.Typography.meta
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.6)

        textField.placeholder = placeholder
        textField.font = UITheme.Typography.buttonSmall
        textField.textColor = UIColor.black
        textField.backgroundColor = UIColor(hex: "F2F6FB")
        textField.layer.cornerRadius = 12
        textField.setLeftPadding(12)
        textField.setRightPadding(12)
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func doneTapped() {
        textField.resignFirstResponder()
    }

    @objc private func textChanged() {
        onTextChanged?(textField.text ?? "")
    }

    func setFixedPrefix(_ prefix: String) {
        let label = UILabel()
        label.text = "  \(prefix) "
        label.font = UITheme.Typography.buttonSmall
        label.textColor = UIColor.black.withAlphaComponent(0.72)
        label.sizeToFit()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: label.frame.width + 2, height: 44))
        label.center = CGPoint(x: container.bounds.midX, y: container.bounds.midY)
        container.addSubview(label)
        textField.leftView = container
        textField.leftViewMode = .always
    }

    func setDisclosureStyle() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 44))
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = UIColor.black.withAlphaComponent(0.45)
        button.addTarget(self, action: #selector(openMenu), for: .touchUpInside)
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 18),
            button.heightAnchor.constraint(equalToConstant: 18)
        ])
        textField.rightView = container
        textField.rightViewMode = .always
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear
        textField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(openMenu))
        textField.addGestureRecognizer(tap)
    }

    @objc private func openMenu() {
        onTap?()
    }
}

extension LabeledTextField: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard onTap != nil else { return true }
        onTap?()
        return false
    }
}

private final class LabeledSelectionField: UIView {
    private let titleLabel = UILabel()
    private let selectionContainer = UIControl()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let placeholder: String

    var onTap: (() -> Void)?
    var anchorView: UIView { selectionContainer }

    var text: String {
        get { valueLabel.text ?? "" }
        set { applyText(newValue) }
    }

    init(title: String, placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = UITheme.Typography.meta
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.6)

        selectionContainer.backgroundColor = UIColor(hex: "F2F6FB")
        selectionContainer.layer.cornerRadius = 12
        selectionContainer.layer.cornerCurve = .continuous
        selectionContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        selectionContainer.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        valueLabel.font = UITheme.Typography.buttonSmall
        valueLabel.textColor = UIColor.black.withAlphaComponent(0.85)
        valueLabel.numberOfLines = 1
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.tintColor = UIColor.black.withAlphaComponent(0.45)
        chevronView.contentMode = .scaleAspectFit

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionContainer.translatesAutoresizingMaskIntoConstraints = false
        selectionContainer.addSubview(valueLabel)
        selectionContainer.addSubview(chevronView)

        NSLayoutConstraint.activate([
            chevronView.trailingAnchor.constraint(equalTo: selectionContainer.trailingAnchor, constant: -14),
            chevronView.centerYAnchor.constraint(equalTo: selectionContainer.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 18),
            chevronView.heightAnchor.constraint(equalToConstant: 18),

            valueLabel.leadingAnchor.constraint(equalTo: selectionContainer.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: selectionContainer.centerYAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, selectionContainer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyText(placeholder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        onTap?()
    }

    private func applyText(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPlaceholder = trimmed.isEmpty || trimmed.caseInsensitiveCompare(placeholder) == .orderedSame
        valueLabel.text = isPlaceholder ? placeholder : trimmed
        valueLabel.textColor = isPlaceholder
            ? UIColor.black.withAlphaComponent(0.35)
            : UIColor.black.withAlphaComponent(0.9)
    }
}

private extension UITextField {
    func setLeftPadding(_ value: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        leftView = paddingView
        leftViewMode = .always
    }

    func setRightPadding(_ value: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        rightView = paddingView
        rightViewMode = .always
    }
}
