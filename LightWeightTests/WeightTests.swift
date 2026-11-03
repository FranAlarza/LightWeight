import Testing
@testable import LightWeight

struct WeightTests {
    @Test
    func poundsConvertToKilograms() {
        // Given
        let weight = Weight(value: 100, unit: .pounds)

        // When
        let kilograms = weight.kilograms

        // Then
        #expect(abs(kilograms - 45.359237) < 0.000_001)
    }

    @Test
    func conversionRoundTripKeepsValue() {
        // Given
        let weight = Weight(value: 45, unit: .pounds)

        // When
        let roundTrip = weight.converted(to: .kilograms).converted(to: .pounds)

        // Then
        #expect(abs(roundTrip.value - 45) < 0.000_001)
        #expect(roundTrip.unit == .pounds)
    }

    @Test
    func convertingToSameUnitIsIdentity() {
        let weight = Weight(value: 82.5, unit: .kilograms)

        #expect(weight.converted(to: .kilograms) == weight)
    }
}
