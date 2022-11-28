/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

extension XCTestCase {

    /// An helper method to migrate deprecated recordFailure(:) XCTestCase method to record(:)
    func recordFailure(description: String,
                       issueType: XCTIssue.IssueType = .uncaughtException,
                       filePath: String = #file,
                       lineNumber: Int = #line) {

        let location = XCTSourceCodeLocation(filePath: filePath, lineNumber: lineNumber)
        let context = XCTSourceCodeContext(location: location)
        let issue = XCTIssue(type: issueType,
                             compactDescription: description,
                             detailedDescription: nil,
                             sourceCodeContext: context,
                             associatedError: nil,
                             attachments: [])
        record(issue)
    }
}
