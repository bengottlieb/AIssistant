import Foundation
import Testing
@testable import Internal

struct AgentDiscoveryTests {
    @Test
    func claudeAgentsExcludeUserSkills() async throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try writeSkill(at: tempDir, folderName: "agent-skill", name: "Agent Skill")

        let items = try await ClaudeCodeScanner(category: .agents, baseDirectory: tempDir).scan()
        #expect(!items.contains { $0.name == "Agent Skill" })
    }

    @Test
    func claudeSkillsIncludeUserSkills() async throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try writeSkill(at: tempDir, folderName: "skill-one", name: "Skill One")

        let items = try await ClaudeCodeScanner(category: .skills, baseDirectory: tempDir).scan()
        #expect(items.contains { $0.name == "Skill One" })
    }

    @Test
    func codexAgentsExcludeUserSkills() async throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try writeSkill(at: tempDir, folderName: "codex-agent", name: "Codex Agent")

        let items = try await CodexScanner(category: .agents, baseDirectory: tempDir).scan()
        #expect(!items.contains { $0.name == "Codex Agent" })
    }

    @Test
    func codexSkillsIncludeUserSkills() async throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try writeSkill(at: tempDir, folderName: "codex-skill", name: "Codex Skill")

        let items = try await CodexScanner(category: .skills, baseDirectory: tempDir).scan()
        #expect(items.contains { $0.name == "Codex Skill" })
    }
}

private func makeTempDirectory() throws -> URL {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    return tempDir
}

private func writeSkill(at baseDirectory: URL, folderName: String, name: String) throws {
    let skillsDir = baseDirectory.appending(path: "skills")
    let skillFolder = skillsDir.appending(path: folderName)
    try FileManager.default.createDirectory(at: skillFolder, withIntermediateDirectories: true)

    let content = """
    ---
    name: \(name)
    description: Test content
    ---
    Test body
    """
    try content.write(to: skillFolder.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)
}
