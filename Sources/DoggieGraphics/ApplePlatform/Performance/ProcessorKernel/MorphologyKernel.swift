//
//  MorphologyKernel.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if canImport(CoreImage) && canImport(MetalPerformanceShaders)

extension CIImage {
    
    @available(macOS 10.13, iOS 10.0, tvOS 10.0, *)
    private class AreaMinKernel: CIImageProcessorKernel {
        
        override class func formatForInput(at input: Int32) -> CIFormat {
            return .BGRA8
        }
        
        override class var outputFormat: CIFormat {
            return .BGRA8
        }
        
        override class var synchronizeInputs: Bool {
            return false
        }
        
        override class func roi(forInput input: Int32, arguments: [String: Any]?, outputRect: CGRect) -> CGRect {
            guard let radius = arguments?["radius"] as? Size else { return outputRect }
            let insetX = -ceil(abs(radius.width))
            let insetY = -ceil(abs(radius.height))
            return outputRect.insetBy(dx: CGFloat(insetX), dy: CGFloat(insetY))
        }
        
        override class func process(with inputs: [CIImageProcessorInput]?, arguments: [String: Any]?, output: CIImageProcessorOutput) throws {
            
            guard let commandBuffer = output.metalCommandBuffer else { return }
            guard let source = inputs?[0].metalTexture else { return }
            guard let source_region = inputs?[0].region else { return }
            guard let destination = output.metalTexture else { return }
            guard let radius = arguments?["radius"] as? Size else { return }
            
            let kernelWidth = Int(round(abs(radius.width))) << 1 + 1
            let kernelHeight = Int(round(abs(radius.height))) << 1 + 1
            
            let kernel = MPSImageAreaMin(device: commandBuffer.device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
            kernel.offset.x = Int(output.region.minX - source_region.minX)
            kernel.offset.y = Int(output.region.minY - source_region.minY)
            
            kernel.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: destination)
        }
    }
    
    @available(macOS 10.13, iOS 10.0, tvOS 10.0, *)
    open func areaMin(_ radius: Size) -> CIImage? {
        
        if extent.isEmpty { return .empty() }
        
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            
            let areaMin = CIFilter.morphologyRectangleMinimum()
            areaMin.width = Float(abs(radius.width) * 2)
            areaMin.height = Float(abs(radius.height) * 2)
            areaMin.inputImage = self
            
            return areaMin.outputImage
            
        } else {
            
            let extent = self.extent.insetBy(dx: CGFloat(-ceil(abs(radius.width))), dy: CGFloat(-ceil(abs(radius.height))))
            
            let _extent = extent.isInfinite ? extent : extent.insetBy(dx: .random(in: -1..<0), dy: .random(in: -1..<0))
            
            guard var rendered = try? AreaMinKernel.apply(withExtent: _extent, inputs: [self], arguments: ["radius": radius]) else { return nil }
            
            if !extent.isInfinite {
                rendered = rendered.cropped(to: extent)
            }
            
            return rendered
        }
    }
}

extension CIImage {
    
    @available(macOS 10.13, iOS 10.0, tvOS 10.0, *)
    private class AreaMaxKernel: CIImageProcessorKernel {
        
        override class func formatForInput(at input: Int32) -> CIFormat {
            return .BGRA8
        }
        
        override class var outputFormat: CIFormat {
            return .BGRA8
        }
        
        override class var synchronizeInputs: Bool {
            return false
        }
        
        override class func roi(forInput input: Int32, arguments: [String: Any]?, outputRect: CGRect) -> CGRect {
            guard let radius = arguments?["radius"] as? Size else { return outputRect }
            let insetX = -ceil(abs(radius.width))
            let insetY = -ceil(abs(radius.height))
            return outputRect.insetBy(dx: CGFloat(insetX), dy: CGFloat(insetY))
        }
        
        override class func process(with inputs: [CIImageProcessorInput]?, arguments: [String: Any]?, output: CIImageProcessorOutput) throws {
            
            guard let commandBuffer = output.metalCommandBuffer else { return }
            guard let source = inputs?[0].metalTexture else { return }
            guard let source_region = inputs?[0].region else { return }
            guard let destination = output.metalTexture else { return }
            guard let radius = arguments?["radius"] as? Size else { return }
            
            let kernelWidth = Int(round(abs(radius.width))) << 1 + 1
            let kernelHeight = Int(round(abs(radius.height))) << 1 + 1
            
            let kernel = MPSImageAreaMax(device: commandBuffer.device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
            kernel.offset.x = Int(output.region.minX - source_region.minX)
            kernel.offset.y = Int(output.region.minY - source_region.minY)
            
            kernel.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: destination)
        }
    }
    
    @available(macOS 10.13, iOS 10.0, tvOS 10.0, *)
    open func areaMax(_ radius: Size) -> CIImage? {
        
        if extent.isEmpty { return .empty() }
        
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            
            let areaMax = CIFilter.morphologyRectangleMaximum()
            areaMax.width = Float(abs(radius.width) * 2)
            areaMax.height = Float(abs(radius.height) * 2)
            areaMax.inputImage = self
            
            return areaMax.outputImage
            
        } else {
            
            let extent = self.extent.insetBy(dx: CGFloat(-ceil(abs(radius.width))), dy: CGFloat(-ceil(abs(radius.height))))
            
            let _extent = extent.isInfinite ? extent : extent.insetBy(dx: .random(in: -1..<0), dy: .random(in: -1..<0))
            
            guard var rendered = try? AreaMaxKernel.apply(withExtent: _extent, inputs: [self], arguments: ["radius": radius]) else { return nil }
            
            if !extent.isInfinite {
                rendered = rendered.cropped(to: extent)
            }
            
            return rendered
        }
    }
}

#endif
