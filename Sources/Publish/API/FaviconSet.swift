/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// An extended representation of a website's "favicon" (a small icon typically
/// displayed along the website's title in various browser UIs).
public struct FaviconSet {
    
    public var ico: Path?
    public var svg: Path?
    public var appleTouchIcon: AppleTouchIcon?
    
    public struct AppleTouchIcon {
        let path: Path
        let size: Int
    }
    
}
