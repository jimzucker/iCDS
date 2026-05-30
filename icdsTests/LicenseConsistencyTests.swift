//
//  LicenseConsistencyTests.swift
//  icdsTests
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//
//  Locks in Apache 2.0 as the canonical iCDS source license and enforces the
//  ISDA CDS Standard Model Public Licence §4(b) attribution wording in-app.
//  Fails if any user-visible license declaration drifts — header comments,
//  README license sections, the in-app InfoView body text, the consolidated
//  licenses page, subtree LICENSE files, and the third-party NOTICES file.
//  Companion test on the Flutter side: flutter/test/license_consistency_test.dart.
//

import XCTest

final class LicenseConsistencyTests: XCTestCase {

    private static let headerLine = "Licensed under the Apache License, Version 2.0 — see LICENSE in project root."
    private static let userVisibleLabel = "Licensed under the Apache License, Version 2.0"
    private static let licenseURL = "https://www.apache.org/licenses/LICENSE-2.0"

    // ISDA CDS Standard Model Public Licence §4(b) — exact required attribution
    // for any externally-distributed derivative work, naming the version of the
    // model on which the derivative is based. We pin "1.8.3" deliberately;
    // bumping the bundled model means bumping this string too.
    private static let isdaAttribution = "This application is based on the ISDA CDS Standard Model (version 1.8.3), developed and supported in collaboration with Markit Group Ltd."
    private static let licensesPageURL = "https://jimzucker.github.io/iCDS/licenses"

    // Resolve the project root from this file's location: icdsTests/LicenseConsistencyTests.swift
    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // icdsTests/
            .deletingLastPathComponent()  // project root
    }

    private func read(_ relative: String) throws -> String {
        let url = projectRoot.appendingPathComponent(relative)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func assertContains(_ haystack: String, _ needle: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(haystack.contains(needle), "Expected to find \"\(needle)\"", file: file, line: line)
    }

    private func assertFileExists(_ relative: String, file: StaticString = #filePath, line: UInt = #line) {
        let url = projectRoot.appendingPathComponent(relative)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path),
                      "Expected file at \(relative)", file: file, line: line)
    }

    // MARK: - LICENSE files

    func testRootLicenseIsApache2() throws {
        let license = try read("LICENSE")
        XCTAssertTrue(license.contains("Apache License"), "LICENSE missing 'Apache License'")
        XCTAssertTrue(license.contains("Version 2.0"), "LICENSE missing 'Version 2.0'")
        XCTAssertTrue(license.contains("www.apache.org/licenses"), "LICENSE missing apache.org URL")
    }

    func testSubtreeLicenseFilesExist() {
        // For source-tree redistribution: each redistributable subtree carries
        // a LICENSE so downstream consumers always get a license alongside the
        // code they grab.
        assertFileExists("icds/LICENSE")
        assertFileExists("icds/isdamodel/LICENSE")
        assertFileExists("Licenses/ISDA_CDS_Standard_Model_Public_Licence_1.0.txt")
    }

    func testIsdaSubtreeLicenseMatchesCanonical() throws {
        // ISDA §4(a) requires that copies of the model retain notices "in their
        // original locations." We ship the full licence text alongside the
        // bundled C source so any subtree copy is self-contained.
        let canonical = try read("Licenses/ISDA_CDS_Standard_Model_Public_Licence_1.0.txt")
        let inSubtree = try read("icds/isdamodel/LICENSE")
        XCTAssertEqual(canonical, inSubtree,
                       "icds/isdamodel/LICENSE drifted from the canonical ISDA licence text")
    }

    // MARK: - Swift header comments

    func testEverySwiftSourceHasApacheHeader() throws {
        let dirs = ["icds", "icdsTests", "icdsUITests"]
        var checked = 0
        var missing: [String] = []

        for dir in dirs {
            let dirURL = projectRoot.appendingPathComponent(dir)
            let enumerator = FileManager.default.enumerator(
                at: dirURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            while let url = enumerator?.nextObject() as? URL {
                guard url.pathExtension == "swift" else { continue }
                // Skip the isdamodel C library directory (no Swift files in there
                // anyway, but defensive).
                if url.pathComponents.contains("isdamodel") { continue }
                checked += 1
                let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                let header = content.split(separator: "\n").prefix(12).joined(separator: "\n")
                if !header.contains(Self.headerLine) {
                    missing.append(url.lastPathComponent)
                }
            }
        }

        XCTAssertGreaterThan(checked, 10, "Sanity: expected more than 10 .swift files")
        XCTAssertTrue(missing.isEmpty,
                      "Files missing Apache 2.0 header line: \(missing.joined(separator: ", "))")
    }

    // MARK: - In-app Info screen (user-visible)

    func testInfoViewExposesApacheLicenseLabelAndURL() throws {
        let info = try read("icds/InfoView.swift")
        assertContains(info, Self.userVisibleLabel)
        assertContains(info, Self.licenseURL)
    }

    func testInfoViewIncludesIsdaSection4bAttribution() throws {
        // ISDA §4(b): the exact sentence (with the bundled model version and the
        // Markit Group Ltd. attribution) must appear at the app's top level.
        let info = try read("icds/InfoView.swift")
        assertContains(info, Self.isdaAttribution)
        assertContains(info, "ISDA CDS Standard Model Public Licence 1.0")
        assertContains(info, "© 2009 JPMorgan Chase Bank, N.A.")
    }

    func testInfoViewLinksToLicensesPage() throws {
        // The Info tab must surface a link to the consolidated /licenses page so
        // users can reach the full third-party notices in one tap.
        let info = try read("icds/InfoView.swift")
        assertContains(info, Self.licensesPageURL)
        assertContains(info, "Licenses & Acknowledgements")
    }

    // MARK: - Consolidated licenses page + third-party notices

    func testLicensesMarkdownExistsAndCoversAppAndIsda() throws {
        assertFileExists("licenses.md")
        let body = try read("licenses.md")
        // App license
        assertContains(body, "Apache License, Version 2.0")
        // ISDA — both the license name and the §4(b) attribution sentence
        assertContains(body, "ISDA CDS Standard Model Public Licence 1.0")
        assertContains(body, Self.isdaAttribution)
    }

    func testNoticesMarkdownExistsAndCoversBundledComponents() throws {
        assertFileExists("NOTICES.md")
        let body = try read("NOTICES.md")
        assertContains(body, "ISDA CDS Standard Model")
        // Flutter dep table — at minimum the load-bearing entries
        for pkg in ["http", "intl", "ffi", "shared_preferences",
                    "plugin_platform_interface", "url_launcher",
                    "in_app_review", "cupertino_icons", "cronet_http"] {
            assertContains(body, pkg)
        }
    }

    // MARK: - README and store-listing docs

    func testRootReadmeLicenseSection() throws {
        let readme = try read("README.md")
        assertContains(readme, "Apache License, Version 2.0")
        assertContains(readme, "LICENSE")
    }

    func testAppStoreDocsMentionApache2() throws {
        // Glob every versioned app_store_description file so future bumps
        // (3.3.0, 3.4.0, …) are automatically covered.
        let docsDir = projectRoot.appendingPathComponent("docs")
        let descs = (try FileManager.default.contentsOfDirectory(atPath: docsDir.path))
            .filter { $0.hasPrefix("app_store_description_") && $0.hasSuffix(".txt") }
        XCTAssertFalse(descs.isEmpty, "No app_store_description_*.txt files found in docs/")
        for name in descs {
            let body = try read("docs/\(name)")
            XCTAssertTrue(body.contains("Apache 2.0"),
                          "\(name) missing 'Apache 2.0' reference")
        }

        let appStoreSubmission = try read("docs/APP_STORE_SUBMISSION.md")
        assertContains(appStoreSubmission, "Apache 2.0")
    }

    func testPlayStoreDocMentionsApache2() throws {
        let playStore = try read("PLAY_STORE_SUBMISSION.md")
        assertContains(playStore, "Apache 2.0")
    }
}
