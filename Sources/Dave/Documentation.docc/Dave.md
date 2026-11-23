# ``Dave``

Discord Audio/Video End-to-End Encryption (DAVE) protocol support in DiscordAudioKit.

## Overview

The `Dave` module implements Discord's DAVE protocol. It provides ``DaveSession``, a Swift 6 actor that manages MLS group keys, coordinates transitions with the Discord Voice Gateway, and encrypts outbound media frames using AES-128-GCM.

Within DiscordAudioKit, `Dave` works directly with the `Audio` module: 20ms Opus frames produced by `OpusPacketStream` are passed directly to ``DaveSession/encrypt(frame:ssrc:)`` before UDP transmission.

## Topics

### Guides

- <doc:GettingStarted>
- <doc:IntegratingWithAVoiceLibrary>
- <doc:ProtocolFlow>

### Core Types

- ``DaveSession``
- ``DaveOutgoing``
- ``DaveProtocolVersion``
- ``DaveConfiguration``
- ``DaveCodec``
- ``DaveError``
- ``DaveLogLevel``
- ``setDaveLogSink(_:)``
