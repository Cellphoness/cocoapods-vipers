import Curry

//脚本里的模板

extension VIPERBinderHelper {
/** Injection VIPERBinderHelper autoCreateBinder init **/
}


extension VIPERParams {

/** Injection VIPERParams class **/

}

extension VIPERs {

/** Injection VIPERs extension **/

    /// 第三方账号绑定 1
    // func thirdPartyBind() -> Self {
    //     return .thirdPartyBind
    // }

    /// 第三方账号绑定参数 参数列表 2
    /// - Parameters:
    ///   - id: 页面id
    ///   - path: 路径
    /// - Returns: 参数返回值
    // func thirdPartyBindParams(id: Int, path: String) -> VIPERParams.thirdPartyBind {
    //     return VIPERParams.thirdPartyBind(id: id, path: path)
    // }

    // /// 第三方账号绑定参数 柯里化 3
    // var thirdPartyBindCurry: (Int) -> (String) -> VIPERParams.thirdPartyBind {
    //     return curry(thirdPartyBindParams)
    // }
}

// Useage:
//VIPERs.function.thirdPartyBindParams(id: 1, path: "2")
//VIPERs.function.thirdPartyBindCurry(1)("2")
