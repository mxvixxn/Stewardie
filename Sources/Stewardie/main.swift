import AppKit
import Darwin

final class SingleInstanceLock {
    private let fileDescriptor: Int32

    init?(identifier: String) {
        let lockPath = NSTemporaryDirectory() + "\(identifier).lock"
        fileDescriptor = open(lockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)

        guard fileDescriptor >= 0 else {
            return nil
        }

        guard flock(fileDescriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(fileDescriptor)
            return nil
        }
    }

    deinit {
        flock(fileDescriptor, LOCK_UN)
        close(fileDescriptor)
    }
}

guard let singleInstanceLock = SingleInstanceLock(identifier: StewardieConstants.bundleIdentifier) else {
    exit(0)
}

let application = NSApplication.shared
let delegate = AppDelegate()

application.delegate = delegate
application.run()

_ = singleInstanceLock
