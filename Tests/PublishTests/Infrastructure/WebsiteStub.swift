/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Publish
import Plot

class WebsiteStub {
    enum SectionID: String, WebsiteSectionID {
        case one, two, three, customRawValue = "custom-raw-value"
    }

    var url = URL(string: "https://swiftbysundell.com")!
    var name = "WebsiteName"
    var description = "Description"
    var language = Language.english
    var locale: Locale? { .init(identifier: "en_US") }
    var themeColor: String? = nil
    var imagePath: Path? = nil
    var twitterUsername: String? = nil
    var faviconPath: Path? = nil
    var faviconSet: FaviconSet? = nil
    var tagHTMLConfig: TagHTMLConfiguration? = .default

    required init() {}

    func title(for sectionID: WebsiteStub.SectionID) -> String {
        sectionID.rawValue
    }
}

extension WebsiteStub {
    final class WithItemMetadata<ItemMetadata: WebsiteItemMetadata>: WebsiteStub, Website {}

    final class WithPodcastMetadata: WebsiteStub, Website {
        struct ItemMetadata: PodcastCompatibleWebsiteItemMetadata {
            var podcast: PodcastEpisodeMetadata?
        }
    }

    final class WithoutItemMetadata: WebsiteStub, Website {
        struct ItemMetadata: WebsiteItemMetadata {}
    }
}
