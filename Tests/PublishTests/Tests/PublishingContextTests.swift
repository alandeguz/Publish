/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish

final class PublishingContextTests: PublishTestCase {
    @Test func `Section Iteration Order`() async throws {
        let expectedOrder = WebsiteStub.SectionID.allCases
        var actualOrder = [WebsiteStub.SectionID]()

        try await publishWebsite(using: [
            .step(named: "Step") { context in
                context.sections.forEach { section in
                    actualOrder.append(section.id)
                }
            }
        ])

        #expect((expectedOrder) == (actualOrder))
    }
}
