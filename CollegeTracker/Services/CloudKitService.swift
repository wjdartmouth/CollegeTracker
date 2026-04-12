// CloudKitService.swift
import CloudKit
import SwiftUI

class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    private let container = CKContainer(identifier: "iCloud.com.yourname.collegetracker")

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
