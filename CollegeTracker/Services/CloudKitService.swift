// CloudKitService.swift
import CloudKit
import SwiftUI
import Combine

class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    /// Matches PRODUCT_BUNDLE_IDENTIFIER in the Xcode project (`edu.asu.jwang875.CollegeTracker`).
    /// Counselor CKShare APIs below are unused in v1 — sharing is deferred, do not fake it with local UUIDs.
    static let containerIdentifier = "iCloud.edu.asu.jwang875.CollegeTracker"
    private let container = CKContainer(identifier: CloudKitService.containerIdentifier)


    @Published var iCloudAvailable = false

    private init() {
        checkiCloudStatus()
    }

    func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.iCloudAvailable = status == .available
            }
        }
    }

    // Create a share for a student's record zone (counselor use)
    func createShare(for studentName: String) async throws -> CKShare {
        let zoneID = CKRecordZone.ID(zoneName: "Student-\(studentName)", ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await container.privateCloudDatabase.save(zone)

        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "\(studentName)'s College Applications"
        share.publicPermission = .readOnly

        _ = try await container.privateCloudDatabase.save(share)
        return share
    }

    // Present the CloudKit sharing UI
    @MainActor
    func presentSharingController(share: CKShare, from view: UIView) {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadOnly, .allowPrivate]
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(controller, animated: true)
        }
    }
}
