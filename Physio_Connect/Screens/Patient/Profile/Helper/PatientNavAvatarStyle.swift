//
//  PatientNavAvatarStyle.swift
//  Physio_Connect
//
//  Created by user@8 on 02/02/26.
//

import UIKit

enum PatientNavAvatarStyle {
    private static let imageCache = NSCache<NSString, UIImage>()
    private static let stateLock = NSLock()
    private static var expectedAvatarByButton: [ObjectIdentifier: String] = [:]
    private static var expectedAvatarByItem: [ObjectIdentifier: String] = [:]
    private static var signedURLCache: [String: (url: URL, expiry: Date)] = [:]
    private static let avatarItemDiameter: CGFloat = 30

    static func updateProfileButton(_ button: UIButton, urlString: String?) {
        let placeholder = UIImage(systemName: "person.circle")
        let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        stateLock.lock()
        expectedAvatarByButton[ObjectIdentifier(button)] = raw
        stateLock.unlock()

        guard !raw.isEmpty else {
            configure(button, image: placeholder)
            return
        }

        if let cachedImage = imageCache.object(forKey: raw as NSString) {
            configure(button, image: cachedImage.withRenderingMode(.alwaysOriginal))
            return
        }

        // Keep current image while refreshing to avoid flicker during tab switches.
        if button.currentImage == nil {
            configure(button, image: placeholder)
        }

        if let cachedSigned = cachedSignedURL(for: raw) {
            ImageLoader.shared.load(cachedSigned) { image in
                applyLoadedImage(
                    image,
                    placeholder: placeholder,
                    raw: raw,
                    button: button
                )
            }
            return
        }

        let finalURL = URL(string: raw)
        if let finalURL {
            ImageLoader.shared.load(finalURL) { image in
                if let image {
                    applyLoadedImage(image, placeholder: placeholder, raw: raw, button: button)
                    return
                }
                loadFromSignedURLIfPossible(raw: raw, placeholder: placeholder, button: button)
            }
            return
        }

        loadFromSignedURLIfPossible(raw: raw, placeholder: placeholder, button: button)
    }

    static func updateProfileItem(_ item: UIBarButtonItem, urlString: String?) {
        let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        stateLock.lock()
        expectedAvatarByItem[ObjectIdentifier(item)] = raw
        stateLock.unlock()

        guard !raw.isEmpty else {
            configure(item, image: nil)
            return
        }

        if let cachedImage = imageCache.object(forKey: raw as NSString) {
            configure(item, image: cachedImage.withRenderingMode(.alwaysOriginal))
            return
        }

        if item.image == nil {
            configure(item, image: nil)
        }
        PhysioService.shared.loadProfileImage(pathOrUrl: raw, version: nil) { image in
            applyLoadedImageToItem(
                image,
                placeholder: nil,
                raw: raw,
                item: item
            )
        }
    }

    private static func loadFromSignedURLIfPossible(raw: String, placeholder: UIImage?, button: UIButton) {
        guard let ref = storageReference(from: raw) else {
            DispatchQueue.main.async {
                if isExpected(raw: raw, button: button) {
                    configure(button, image: placeholder)
                }
            }
            return
        }
        Task {
            guard let signed = try? await SupabaseManager.shared.client.storage
                .from(ref.bucket)
                .createSignedURL(path: ref.path, expiresIn: 3600)
            else {
                await MainActor.run {
                    if isExpected(raw: raw, button: button) {
                        configure(button, image: placeholder)
                    }
                }
                return
            }

            cacheSignedURL(signed, for: raw)
            ImageLoader.shared.load(signed) { image in
                applyLoadedImage(
                    image,
                    placeholder: placeholder,
                    raw: raw,
                    button: button
                )
            }
        }
    }

    private static func loadFromSignedURLIfPossible(raw: String, placeholder: UIImage?, item: UIBarButtonItem) {
        guard let ref = storageReference(from: raw) else {
            DispatchQueue.main.async {
                if isExpected(raw: raw, item: item) {
                    configure(item, image: placeholder)
                }
            }
            return
        }
        Task {
            guard let signed = try? await SupabaseManager.shared.client.storage
                .from(ref.bucket)
                .createSignedURL(path: ref.path, expiresIn: 3600)
            else {
                await MainActor.run {
                    if isExpected(raw: raw, item: item) {
                        configure(item, image: placeholder)
                    }
                }
                return
            }

            cacheSignedURL(signed, for: raw)
            ImageLoader.shared.load(signed) { image in
                applyLoadedImageToItem(
                    image,
                    placeholder: placeholder,
                    raw: raw,
                    item: item
                )
            }
        }
    }

    private static func configure(_ button: UIButton, image: UIImage?) {
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = button.bounds.width > 0 ? button.bounds.width / 2 : 18
        button.clipsToBounds = true
    }

    private static func applyLoadedImage(_ image: UIImage?, placeholder: UIImage?, raw: String, button: UIButton) {
        DispatchQueue.main.async {
            guard isExpected(raw: raw, button: button) else { return }
            if let image, isLikelyAvatarPhoto(image) {
                imageCache.setObject(image, forKey: raw as NSString)
                configure(button, image: image.withRenderingMode(.alwaysOriginal))
            } else {
                configure(button, image: placeholder)
            }
        }
    }

    private static func applyLoadedImageToItem(_ image: UIImage?, placeholder: UIImage?, raw: String, item: UIBarButtonItem) {
        DispatchQueue.main.async {
            guard isExpected(raw: raw, item: item) else { return }
            if let image {
                imageCache.setObject(image, forKey: raw as NSString)
                configure(item, image: image.withRenderingMode(.alwaysOriginal))
            } else {
                configure(item, image: placeholder)
            }
        }
    }

    private static func isExpected(raw: String, button: UIButton) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return expectedAvatarByButton[ObjectIdentifier(button)] == raw
    }

    private static func isExpected(raw: String, item: UIBarButtonItem) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return expectedAvatarByItem[ObjectIdentifier(item)] == raw
    }

    private static func configure(_ item: UIBarButtonItem, image: UIImage?) {
        if let image {
            item.image = makeCircularAvatarImage(from: image, diameter: avatarItemDiameter)
                .withRenderingMode(.alwaysOriginal)
            item.tintColor = .clear
            return
        }
        let fallback = UIImage(
            systemName: "person.crop.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: avatarItemDiameter * 0.62, weight: .regular)
        )
        item.image = fallback
        item.tintColor = UIColor.secondaryLabel
    }

    private static func makeCircularAvatarImage(from image: UIImage, diameter: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter), format: format)
        return renderer.image { context in
            let outerRect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: outerRect)

            let ringWidth: CGFloat = 2
            let innerRect = outerRect.insetBy(dx: ringWidth, dy: ringWidth)
            UIBezierPath(ovalIn: innerRect).addClip()

            let sourceSize = image.size
            let scale = max(innerRect.width / sourceSize.width, innerRect.height / sourceSize.height)
            let drawSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
            let drawOrigin = CGPoint(
                x: innerRect.midX - drawSize.width / 2,
                y: innerRect.midY - drawSize.height / 2
            )
            image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
        }
    }

    private static func makeAvatarPlaceholderImage(diameter: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter), format: format)
        return renderer.image { context in
            let outerRect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            UIColor.white.withAlphaComponent(0.95).setFill()
            context.cgContext.fillEllipse(in: outerRect)

            let ringWidth: CGFloat = 2
            let innerRect = outerRect.insetBy(dx: ringWidth, dy: ringWidth)
            UIColor.systemGray5.setFill()
            context.cgContext.fillEllipse(in: innerRect)

            let config = UIImage.SymbolConfiguration(pointSize: diameter * 0.45, weight: .semibold)
            let symbol = UIImage(systemName: "person.fill", withConfiguration: config)?
                .withTintColor(UIColor.systemGray, renderingMode: .alwaysOriginal)
            if let symbol {
                let symbolSize = CGSize(width: diameter * 0.5, height: diameter * 0.5)
                let symbolRect = CGRect(
                    x: innerRect.midX - symbolSize.width / 2,
                    y: innerRect.midY - symbolSize.height / 2,
                    width: symbolSize.width,
                    height: symbolSize.height
                )
                symbol.draw(in: symbolRect)
            }
        }
    }

    private static func isLikelyAvatarPhoto(_ image: UIImage) -> Bool {
        guard image.size.width >= 8, image.size.height >= 8 else { return false }

        // Symbol/vector/template images often have no cgImage and should not be treated as profile photos.
        guard let cgImage = image.cgImage else { return false }
        let width = 12
        let height = 12
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return true }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var alphaCount = 0
        var luminances: [CGFloat] = []
        var saturations: [CGFloat] = []
        var quantizedColors = Set<Int>()
        luminances.reserveCapacity(width * height)
        saturations.reserveCapacity(width * height)

        for index in stride(from: 0, to: pixels.count, by: 4) {
            let r = CGFloat(pixels[index]) / 255.0
            let g = CGFloat(pixels[index + 1]) / 255.0
            let b = CGFloat(pixels[index + 2]) / 255.0
            let a = CGFloat(pixels[index + 3]) / 255.0
            if a > 0.08 { alphaCount += 1 }
            if a > 0.08 {
                // Quantize channels to detect flat/icon-like images with very low color diversity.
                let rq = Int((r * 255.0).rounded()) / 24
                let gq = Int((g * 255.0).rounded()) / 24
                let bq = Int((b * 255.0).rounded()) / 24
                quantizedColors.insert((rq << 8) | (gq << 4) | bq)
            }
            let luminance = (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
            luminances.append(luminance)
            let maxChannel = max(r, max(g, b))
            let minChannel = min(r, min(g, b))
            let saturation = maxChannel > 0 ? (maxChannel - minChannel) / maxChannel : 0
            saturations.append(saturation)
        }

        let coverage = CGFloat(alphaCount) / CGFloat(width * height)
        guard coverage > 0.20 else { return false }
        // Icons/solid placeholders are usually low-diversity. Photos should have richer color spread.
        if quantizedColors.count < 10 { return false }

        let mean = luminances.reduce(0, +) / CGFloat(luminances.count)
        let variance = luminances.reduce(0) { partial, value in
            let diff = value - mean
            return partial + (diff * diff)
        } / CGFloat(luminances.count)
        let meanSaturation = saturations.reduce(0, +) / CGFloat(saturations.count)

        if variance < 0.0012 { return false }
        if variance < 0.0006 && mean < 0.12 {
            return false
        }
        if mean < 0.22 && meanSaturation < 0.18 {
            return false
        }
        return true
    }

    private static func cachedSignedURL(for raw: String) -> URL? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let cached = signedURLCache[raw], cached.expiry > Date() else {
            signedURLCache.removeValue(forKey: raw)
            return nil
        }
        return cached.url
    }

    private static func cacheSignedURL(_ url: URL, for raw: String) {
        stateLock.lock()
        signedURLCache[raw] = (url, Date().addingTimeInterval(55 * 60))
        stateLock.unlock()
    }

    private static func storageReference(from raw: String) -> (bucket: String, path: String)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let range = trimmed.range(of: "/storage/v1/object/public/") {
            let tail = String(trimmed[range.upperBound...])
            let parts = tail.split(separator: "/", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            return (bucket: parts[0], path: parts[1])
        }

        let parts = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/", maxSplits: 1)
            .map(String.init)
        guard parts.count == 2 else { return nil }
        return (bucket: parts[0], path: parts[1])
    }
}
