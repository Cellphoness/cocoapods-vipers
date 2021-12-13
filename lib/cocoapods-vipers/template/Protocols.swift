import UIKit

// MARK: VIPERs Enum
public enum VIPERs: String {
    public typealias RawValue = String
/** Injection VIPERS case **/
}

public struct VIPERBinderHelper {

    public static func initBinder(shouldObserveForAppLaunch: Bool = true) {

        // initAllBinder
/** Injection VIPERBinderHelper call init function **/

        if shouldObserveForAppLaunch {
            Router.observeForAppLaunch()
        }
    }
}