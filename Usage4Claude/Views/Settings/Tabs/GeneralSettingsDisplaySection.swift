//
//  GeneralSettingsDisplaySection.swift
//  Usage4Claude
//
//  Created by Claude Code on 2025-12-02.
//  Copyright © 2025 f-is-h. All rights reserved.
//

import SwiftUI

/// 通用设置页的"显示设置"卡片：菜单栏图标样式 + 显示内容（图标/百分比）开关
/// 从 GeneralSettingsView 拆出，便于保持单文件体量可控
struct GeneralSettingsDisplaySection: View {
    @ObservedObject private var settings = UserSettings.shared
    @State private var menuBarProfileNameDraft = ""

    var body: some View {
        SettingCard(
            icon: "gauge.with.dots.needle.0percent",
            iconColor: .blue,
            title: L.SettingsGeneral.displaySection,
            hint: L.SettingsGeneral.menubarHint
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // 图标样式选择
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.SettingsGeneral.menubarTheme)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Picker("", selection: $settings.iconStyleMode) {
                        ForEach(IconStyleMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .focusable(false)

                    // 描述文字
                    if !settings.iconStyleMode.description.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(settings.iconStyleMode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 20)
                    }
                }

                Divider()

                // 显示内容选择
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.SettingsGeneral.displayContent)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        Toggle(isOn: Binding(
                            get: { settings.iconDisplayMode == .iconOnly || settings.iconDisplayMode == .both },
                            set: { showIcon in
                                let showPercentage = settings.iconDisplayMode == .percentageOnly || settings.iconDisplayMode == .both
                                if showIcon && showPercentage {
                                    settings.iconDisplayMode = .both
                                } else if showIcon {
                                    settings.iconDisplayMode = .iconOnly
                                } else {
                                    settings.iconDisplayMode = .percentageOnly
                                }
                            }
                        )) {
                            Text(L.Display.showIcon)
                        }
                        .toggleStyle(.checkbox)
                        .focusable(false)
                        .disabled(settings.iconDisplayMode == .iconOnly)

                        Toggle(isOn: Binding(
                            get: { settings.iconDisplayMode == .percentageOnly || settings.iconDisplayMode == .both },
                            set: { showPercentage in
                                let showIcon = settings.iconDisplayMode == .iconOnly || settings.iconDisplayMode == .both
                                if showIcon && showPercentage {
                                    settings.iconDisplayMode = .both
                                } else if showPercentage {
                                    settings.iconDisplayMode = .percentageOnly
                                } else {
                                    settings.iconDisplayMode = .iconOnly
                                }
                            }
                        )) {
                            Text(L.Display.showPercentage)
                        }
                        .toggleStyle(.checkbox)
                        .focusable(false)
                        .disabled(settings.iconDisplayMode == .percentageOnly)
                    }
                }

                // 多账户菜单栏选择（有 2 个及以上 Claude 账户或 Codex 账户时显示）
                if settings.claudeAccounts.count > 1 || settings.hasValidCodexCredentials || !settings.codexAccounts.isEmpty {
                    Divider()

                    menuBarAccountsSection
                }
            }
        }
    }

    // MARK: - 多账户菜单栏选择

    @ViewBuilder
    private var menuBarAccountsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.SettingsGeneral.menubarAccounts)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Picker("", selection: Binding(
                    get: { settings.activeMenuBarAccountProfileId },
                    set: { profileId in
                        guard let profileId,
                              let profile = settings.menuBarAccountProfiles.first(where: { $0.id == profileId }) else { return }
                        settings.applyMenuBarAccountProfile(profile)
                        menuBarProfileNameDraft = profile.name
                    }
                )) {
                    ForEach(settings.menuBarAccountProfiles) { profile in
                        Text(profile.name).tag(Optional(profile.id))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 180)

                TextField("Profile name", text: $menuBarProfileNameDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        renameActiveMenuBarProfile()
                    }
                    .onChange(of: menuBarProfileNameDraft) { _ in
                        renameActiveMenuBarProfile()
                    }

                Button {
                    settings.createMenuBarAccountProfile()
                    menuBarProfileNameDraft = settings.activeMenuBarAccountProfile?.name ?? ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("New profile")

                Button {
                    if let profile = settings.activeMenuBarAccountProfile {
                        settings.deleteMenuBarAccountProfile(profile)
                        menuBarProfileNameDraft = settings.activeMenuBarAccountProfile?.name ?? ""
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(settings.menuBarAccountProfiles.count <= 1)
                .help("Delete profile")
            }
            .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(settings.claudeAccounts) { account in
                    Toggle(isOn: menuBarAccountBinding(for: account)) {
                        Text(account.displayName)
                    }
                    .toggleStyle(.checkbox)
                    .focusable(false)
                }

                ForEach(settings.codexAccounts) { account in
                    Toggle(isOn: menuBarCodexAccountBinding(for: account)) {
                        Label {
                            Text(account.displayName)
                        } icon: {
                            Image(systemName: "terminal.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .focusable(false)
                }
            }
            .padding(.leading, 20)

            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text(L.SettingsGeneral.menubarAccountsHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 20)

            // 每个账户显示的圆环样式（菜单栏与弹窗共用）
            Text(L.SettingsGeneral.menubarAccountsStyle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            Picker("", selection: $settings.multiAccountShowWeekly) {
                Text(L.SettingsGeneral.menubarAccountsStyleFiveHour).tag(false)
                Text(L.SettingsGeneral.menubarAccountsStyleBoth).tag(true)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            .focusable(false)
            .padding(.leading, 20)
        }
        .onAppear {
            menuBarProfileNameDraft = settings.activeMenuBarAccountProfile?.name ?? ""
        }
        .onChange(of: settings.activeMenuBarAccountProfileId) { _ in
            menuBarProfileNameDraft = settings.activeMenuBarAccountProfile?.name ?? ""
        }
    }

    /// 某个账户是否显示在菜单栏的绑定
    private func menuBarAccountBinding(for account: Account) -> Binding<Bool> {
        Binding(
            get: { settings.menuBarAccountIds.contains(account.id) },
            set: { isOn in
                if isOn {
                    settings.menuBarAccountIds.insert(account.id)
                } else {
                    settings.menuBarAccountIds.remove(account.id)
                }
            }
        )
    }

    /// 某个 Codex 账户是否显示在菜单栏的绑定
    private func menuBarCodexAccountBinding(for account: Account) -> Binding<Bool> {
        Binding(
            get: { settings.menuBarCodexAccountIds.contains(account.id) },
            set: { isOn in
                if isOn {
                    settings.menuBarCodexAccountIds.insert(account.id)
                } else {
                    settings.menuBarCodexAccountIds.remove(account.id)
                }
            }
        )
    }

    private func renameActiveMenuBarProfile() {
        guard let profile = settings.activeMenuBarAccountProfile else { return }
        settings.renameMenuBarAccountProfile(profile, to: menuBarProfileNameDraft)
    }
}
