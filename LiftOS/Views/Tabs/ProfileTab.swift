import SwiftUI
import SwiftData
import AuthenticationServices

struct ProfileTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                if let profile {
                    signedInSection(profile)
                } else {
                    signInSection
                }

                unitsSection
                restTimerSection
                exerciseLibrarySection
                aboutSection
            }
            .navigationTitle("Profile")
        }
    }

    private func signedInSection(_ profile: UserProfile) -> some View {
        Section {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                    Text(profile.displayName ?? "Lifter")
                        .font(.headline)
                    if profile.appleUserID != nil {
                        Text("Signed in with Apple")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var signInSection: some View {
        Section {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                handleSignInResult(result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
        } header: {
            Text("Account")
        } footer: {
            Text("Sign in to prepare for future cloud sync features.")
        }
    }

    private var unitsSection: some View {
        Section("Units") {
            Picker("Weight", selection: weightUnitBinding) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
        }
    }

    private var restTimerSection: some View {
        Section("Rest Timer") {
            Picker("Default Rest", selection: restSecondsBinding) {
                Text("60s").tag(60)
                Text("90s").tag(90)
                Text("120s").tag(120)
                Text("150s").tag(150)
                Text("180s").tag(180)
                Text("240s").tag(240)
                Text("300s").tag(300)
            }
        }
    }

    private var exerciseLibrarySection: some View {
        Section {
            NavigationLink {
                // TODO: ExerciseLibraryView
                Text("Exercise Library")
            } label: {
                Label("Exercise Library", systemImage: "dumbbell.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weightUnitBinding: Binding<WeightUnit> {
        Binding(
            get: { profile?.weightUnit ?? .lbs },
            set: { newValue in
                ensureProfile().weightUnit = newValue
            }
        )
    }

    private var restSecondsBinding: Binding<Int> {
        Binding(
            get: { profile?.defaultRestSeconds ?? 120 },
            set: { newValue in
                ensureProfile().defaultRestSeconds = newValue
            }
        )
    }

    @discardableResult
    private func ensureProfile() -> UserProfile {
        if let profile { return profile }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let profile = ensureProfile()
            profile.appleUserID = credential.user
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    profile.displayName = name
                }
            }
        case .failure:
            break
        }
    }
}

#Preview {
    ProfileTab()
        .modelContainer(.preview)
}
