// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import AVFoundation

// MARK: CameraFeedManagerDelegate Declaration
protocol CameraFeedManagerDelegate: AnyObject {

  /**
   This method delivers the pixel buffer of the current frame seen by the device's camera.
   */
  func didOutput(pixelBuffer: CVPixelBuffer)

}

/**
 This class manages all camera related functionality
 */
class CameraFeedManager: NSObject {

  private let previewView: BufferView
  private var assetReader: AVAssetReader?
  private var assetReaderTrackOutput: AVAssetReaderTrackOutput?

  // MARK: CameraFeedManagerDelegate
  weak var delegate: CameraFeedManagerDelegate?

  // MARK: Initializer
  init(previewView: BufferView) {
    self.previewView = previewView
    super.init()

    self.previewView.previewLayer.videoGravity = .resizeAspect
    configLocalVideo()
  }

    func configLocalVideo() {
        guard let videoUrl = Bundle.main.url(forResource: "basketball-1", withExtension: "mp4") else {
            fatalError("Could not find local video.")
        }

        let videoAsset = AVAsset(url: videoUrl)

        do {
            assetReader = try AVAssetReader(asset: videoAsset)
        } catch {
            fatalError("Could not create asset reader.")
        }

        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            fatalError("No video track found.")
        }

        let assetReaderTrackOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
        )

        self.assetReaderTrackOutput = assetReaderTrackOutput

        guard let reader = assetReader, reader.canAdd(assetReaderTrackOutput) else {
            fatalError("Cannot add assetReaderTrackOutput")
        }

        reader.add(assetReaderTrackOutput)

        do {
            let timebase = try CMTimebase(sourceClock: CMClockGetHostTimeClock())
            try timebase.setTime(CMTime.zero)
            try timebase.setRate(1.0)
            previewView.previewLayer.controlTimebase = timebase
        } catch {
            print("Could not configure controlTimebase.")
        }
    }

    func beginReading() {
        guard let reader = assetReader else {
            fatalError("assetReader unexpectedly nil.")
        }

        guard reader.startReading() else {
            fatalError(reader.error?.localizedDescription ?? "unknown reader error")
        }

        //let videoQueue = DispatchQueue(label: "video read")

        previewView.previewLayer.requestMediaDataWhenReady(on: DispatchQueue.main) { [weak self] in
            guard let self = self else {
                return
            }

            while self.previewView.previewLayer.isReadyForMoreMediaData {
                if let sampleBuffer = self.assetReaderTrackOutput?.copyNextSampleBuffer() {
                    self.previewView.previewLayer.enqueue(sampleBuffer)

                    let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)

                    guard let imagePixelBuffer = pixelBuffer else {
                      return
                    }

                    // Delegates the pixel buffer to the ViewController.
                    self.delegate?.didOutput(pixelBuffer: imagePixelBuffer)
                } else if self.assetReader?.status == .completed {
                    print("Asset Reader Completed")
                    self.previewView.previewLayer.stopRequestingMediaData()
                    self.assetReader?.cancelReading()
                    break
                } else {
                    print("Asset Reader Status: \(self.assetReader!.status)\n\n\n")
                    print("Asset Reader Error: \(self.assetReader?.error?.localizedDescription ?? "no error")")
                }
            }
        }
    }

    func stopReading() {
        previewView.previewLayer.stopRequestingMediaData()

        guard let reader = assetReader else {
            fatalError("assetReader unexpectedly nil.")
        }

        reader.cancelReading()
    }

}
