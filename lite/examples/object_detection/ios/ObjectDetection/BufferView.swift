//
//  BufferView.swift
//  ObjectDetection
//
//  Created by Gabriel Lopez on 11/9/22.
//

import AVFoundation
import UIKit

class BufferView: UIView {

  var previewLayer: AVSampleBufferDisplayLayer {
    guard let layer = layer as? AVSampleBufferDisplayLayer else {
      fatalError("Layer expected is of type AVSampleBufferDisplayLayer")
    }

    return layer
  }

  override class var layerClass: AnyClass {
    return AVSampleBufferDisplayLayer.self
  }

}
