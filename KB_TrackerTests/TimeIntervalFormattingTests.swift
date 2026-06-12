// TimeIntervalFormattingTests.swift
// KB_TrackerTests

import Testing
import Foundation
@testable import KB_Tracker

struct TimeIntervalFormattingTests {

    // MARK: - TimeInterval.formattedMinutesSecondsPadded

    @Test func zero() { #expect(TimeInterval(0).formattedMinutesSecondsPadded == "00:00") }
    @Test func subMinute() { #expect(TimeInterval(45).formattedMinutesSecondsPadded == "00:45") }
    @Test func exactMinute() { #expect(TimeInterval(60).formattedMinutesSecondsPadded == "01:00") }
    @Test func overAnHour() { #expect(TimeInterval(3661).formattedMinutesSecondsPadded == "61:01") }

    // MARK: - Int.formattedMinutesSecondsPadded (new extension)

    @Test func intZero() { #expect(Int(0).formattedMinutesSecondsPadded == "00:00") }
    @Test func intSubMinute() { #expect(Int(45).formattedMinutesSecondsPadded == "00:45") }
    @Test func intNegativeClampsToZero() { #expect(Int(-5).formattedMinutesSecondsPadded == "00:00") }
    @Test func intExactMinute() { #expect(Int(60).formattedMinutesSecondsPadded == "01:00") }
    @Test func intOverAnHour() { #expect(Int(3661).formattedMinutesSecondsPadded == "61:01") }
}
