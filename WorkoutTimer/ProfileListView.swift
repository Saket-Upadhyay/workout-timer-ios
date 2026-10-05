//
//  ProfileListView.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileListView: View {
    let store: ProfileStore
    var onSelect: (WorkoutProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var exportDocument: ProfileBackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Group {
                if store.profiles.isEmpty {
                    ContentUnavailableView(
                        "No Saved Profiles",
                        systemImage: "folder",
                        description: Text("Save your current workout sequence as a profile to see it here.")
                    )
                } else {
                    List {
                        ForEach(store.profiles) { profile in
                            Button {
                                onSelect(profile)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.name)
                                        .font(.headline)
                                    Text("\(profile.exercises.count) exercise\(profile.exercises.count == 1 ? "" : "s")" + (profile.rounds > 1 ? " · \(profile.rounds) rounds" : ""))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export to Files / iCloud Drive", systemImage: "square.and.arrow.up") {
                            exportDocument = ProfileBackupDocument(data: store.exportData() ?? Data())
                            isExporting = true
                        }
                        Button("Import from Files / iCloud Drive", systemImage: "square.and.arrow.down") {
                            isImporting = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "WorkoutProfiles"
            ) { _ in
                exportDocument = nil
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                guard let url = try? result.get() else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    store.importProfiles(from: data)
                }
            }
        }
    }
}

#Preview {
    ProfileListView(
        store: ProfileStore(),
        onSelect: { _ in }
    )
}
