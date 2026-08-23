/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing

func assertErrorThrown<T, E: Error & Equatable>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedError: @autoclosure () -> E
) async {
    await #expect(throws: expectedError()) {
        _ = try await expression()
    }
}
