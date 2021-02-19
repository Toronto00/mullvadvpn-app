//
//  ProblemReportSubmissionOverlayView.swift
//  MullvadVPN
//
//  Created by pronebird on 12/02/2021.
//  Copyright © 2021 Mullvad VPN AB. All rights reserved.
//

import UIKit
import Foundation

class ProblemReportSubmissionOverlayView: UIView {

    var editButtonAction: (() -> Void)?
    var retryButtonAction: (() -> Void)?

    enum State {
        case sending
        case sent(_ email: String)
        case failure(Error)

        var title: String? {
            switch self {
            case .sending:
                return NSLocalizedString("Sending...", comment: "")
            case .sent:
                return NSLocalizedString("Sent", comment: "")
            case .failure:
                return NSLocalizedString("Failed to send", comment: "")
            }
        }

        var body: String? {
            switch self {
            case .sending:
                return nil
            case .sent(let email):
                return String.localizedStringWithFormat("Thanks! We will look into this. If needed we will contact you on %@", email)
            case .failure(let error):
                return error.localizedDescription
            }
        }
    }

    var state: State = .sending {
        didSet {
            transitionToState(self.state)
        }
    }

    let activityIndicator: SpinnerActivityIndicatorView = {
        let indicator = SpinnerActivityIndicatorView(style: .large)
        indicator.tintColor = .white
        return indicator
    }()
    let statusImageView = StatusImageView(style: .success)

    let titleLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 32)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        return textLabel
    }()

    let bodyLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 17)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        return textLabel
    }()

    /// Footer stack view that contains action buttons
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.editMessageButton, self.tryAgainButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 18

        return stackView
    }()

    private lazy var editMessageButton: AppButton = {
        let button = AppButton(style: .default)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Edit message", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(handleEditButton), for: .touchUpInside)
        return button
    }()

    private lazy var tryAgainButton: AppButton = {
        let button = AppButton(style: .success)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Try again", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(handleRetryButton), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubviews()
        transitionToState(state)

        layoutMargins = UIEdgeInsets(top: 8, left: 24, bottom: 24, right: 24)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        // Add a spacer view that's used to push the bodyLabel from the bottom when buttons stack
        // when it's not visible.
        let spacerView = UIView()

        // Set low hugging and compression constants to make that view eager to shrink or grow
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        for subview in [spacerView, titleLabel, bodyLabel, activityIndicator, statusImageView, buttonsStackView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            statusImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 32),
            statusImageView.centerXAnchor.constraint(equalTo: centerXAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: statusImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: statusImageView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: statusImageView.bottomAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            bodyLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1),
            bodyLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            buttonsStackView.topAnchor.constraint(greaterThanOrEqualTo: bodyLabel.bottomAnchor, constant: 18),

            buttonsStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            spacerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            spacerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            spacerView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            spacerView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor),
        ])
    }

    private func transitionToState(_ state: State) {
        titleLabel.text = state.title
        bodyLabel.text = state.body

        switch state {
        case .sending:
            activityIndicator.startAnimating()
            statusImageView.isHidden = true
            buttonsStackView.isHidden = true

        case .sent:
            activityIndicator.stopAnimating()
            statusImageView.style = .success
            statusImageView.isHidden = false
            buttonsStackView.isHidden = true

        case .failure:
            activityIndicator.stopAnimating()
            statusImageView.style = .failure
            statusImageView.isHidden = false
            buttonsStackView.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func handleEditButton() {
        editButtonAction?()
    }

    @objc private func handleRetryButton() {
        retryButtonAction?()
    }
}
