/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// An extended representation of a website's "favicons" (a small icon typically
/// displayed along the website's title in various browser UIs).
public struct FaviconSet {
    
    public var ico: Path?
    public var svg: Path?
    public var appleTouchIcon: AppleTouchIcon?
    
    public init(ico: Path? = nil,
                svg: Path? = nil,
                appleTouchIcon: AppleTouchIcon? = nil) {
        self.ico = ico
        self.svg = svg
        self.appleTouchIcon = appleTouchIcon
    }
    
    public struct AppleTouchIcon {
        let path: Path
        let size: Int
        
        public init(path: Path, size: Int) {
            self.path = path
            self.size = size
        }
    }
    
}
