import Testing
@testable import LightWeight

struct MuscleGroupSectionTests {
    @Test
    func sectionsFollowDisplayOrderAndKeepItemOrder() {
        // Given
        let items = [("Sentadilla", MuscleGroup.legs), ("Press", .chest), ("Zancada", .legs)]

        // When
        let sections = MuscleGroupSection.sections(of: items.map(\.0)) { name in
            items.first { $0.0 == name }!.1
        }

        // Then
        #expect(sections.map(\.group) == [.chest, .legs])
        #expect(sections.last?.items == ["Sentadilla", "Zancada"])
    }

    @Test
    func noItemsMeansNoSections() {
        let sections = MuscleGroupSection<String>.sections(of: []) { _ in .other }

        #expect(sections.isEmpty)
    }
}
