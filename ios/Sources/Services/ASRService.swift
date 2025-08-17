import Foundation
import AVFoundation

protocol ASRServiceProtocol {
    func start(session: AVAudioSession, onText: @escaping (String) -> Void)
    func stop(completion: @escaping (String) -> Void)
}

final class StubASRService: ASRServiceProtocol {
    func start(session: AVAudioSession, onText: @escaping (String) -> Void) {
        // TODO: WhisperKit / Vosk-iOS のストリーミング/バッチに置換
        onText("")
    }
    func stop(completion: @escaping (String) -> Void) {
        completion("")
    }
}

// WhisperKit の例（概念レベル）
// import WhisperKit
// final class WhisperASRService: ASRServiceProtocol { ... }

