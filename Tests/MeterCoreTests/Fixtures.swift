import Foundation

enum Fixtures {
    static let fiveReset = Date(timeIntervalSince1970: 1_788_617_400)
    static let sevenReset = Date(timeIntervalSince1970: 1_789_160_400)
    static let captured = Date(timeIntervalSince1970: 1_788_608_892)

    static let samplePayloadJSON = Data("""
    {"session_id":"f9d550b8-b03e-47b2-aa24-76d4af4f8a26",
     "cwd":"/Users/zuixote/Documents/carta_genum/projects/ai-usage-meter",
     "model":{"id":"claude-fable-5-1","display_name":"Fable 5.1"},
     "version":"2.1.261",
     "effort":{"level":"high"},
     "cost":{"total_cost_usd":8.343004900000002,"total_duration_ms":4110311},
     "context_window":{"total_input_tokens":118695,"context_window_size":1000000,
       "used_percentage":12,"remaining_percentage":88},
     "exceeds_200k_tokens":false,
     "rate_limits":{"five_hour":{"used_percentage":21,"resets_at":1788617400},
                    "seven_day":{"used_percentage":4,"resets_at":1789160400}}}
    """.utf8)

    static let noRateLimitsJSON = Data("""
    {"model":{"id":"claude-fable-5-1","display_name":"Fable 5.1"},
     "context_window":{"used_percentage":3}}
    """.utf8)

    static let onlyFiveHourJSON = Data("""
    {"model":{"display_name":"Opus 4.8"},
     "context_window":{"used_percentage":40.6},
     "rate_limits":{"five_hour":{"used_percentage":55.4,"resets_at":1788617400}}}
    """.utf8)
}
