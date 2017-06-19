//
//  CompareSongsViewController.swift
//  Music Player
//
//  Created by Bonea Ioana on 6/19/17.
//  Copyright © 2017 Sem. All rights reserved.
//

import Alamofire
import Foundation

class CompareSongsViewController: UIViewController{
    
    var firstSongURL: String!
    var secondSongURL: String!
    
    
    let Range = [40,80,120,180,300]
    let fuzz_factor : Double = 2
    
    private var mp3_1:Data?
    private var mp3_2:Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        getTheMp3(firstSongURL)
//        getTheMp3(se)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getTheMp3(_ urlField: String) {
        print(urlField)
        
        let url = urlField
        
        Alamofire.request( url ).responseJSON{
            response in
            
            print(response.result)
            
            guard let json = response.result.value as? [String:Any] else { return }
            
            guard let link = json["link"] as? String else { return }
            
            
            Alamofire.request( link ).responseData{
                response in
                
                self.mp3_1 = response.result.value

                print("fft",self.tranformBytes(audioData: self.mp3_1!))
                print(response.result)
            }
            
        }

    }
    
    
    func readSoundFileSamples(_ filePath: String) -> Data {
        // Get raw PCM data from the track
        let assetURL = URL(fileURLWithPath: filePath)
        var data = Data()
        let sampleRate: UInt32 = 44100
        // 16k sample/sec
        let bitDepth: UInt16 = 16
        // 16 bit/sample/channel
        let channels: UInt16 = 1
        // 2 channel/sample (stereo)
        let opts = [String: Any]()
        let asset = AVURLAsset(url: assetURL, options: opts)
        let reader = try? AVAssetReader(asset: asset)
        let settings: [String: Any] = [
            AVFormatIDKey : Int(kAudioFormatLinearPCM),
            AVSampleRateKey : Int(Float(sampleRate)),
            AVLinearPCMBitDepthKey : Int(bitDepth),
            AVLinearPCMIsNonInterleaved : Int(false),
            AVLinearPCMIsFloatKey : Int(false),
            AVLinearPCMIsBigEndianKey : Int(true)
        ]
        
        print(asset)
        print(asset.tracks)
        
        let output = AVAssetReaderTrackOutput(track: (asset.tracks[0]), outputSettings: settings)
        reader?.add(output)
        reader?.startReading()
        // read the samples from the asset and append them subsequently
        var counter = 0
        while reader?.status != .completed {
            counter += 1
            //print(counter)
            //print("status",reader?.status.rawValue)
            let buffer: CMSampleBuffer? = output.copyNextSampleBuffer()
            if buffer == nil {
                continue
            }
            let blockBuffer: CMBlockBuffer = CMSampleBufferGetDataBuffer(buffer!)!
            let size: size_t = CMBlockBufferGetDataLength(blockBuffer)
            let outBytes = malloc(size)
            CMBlockBufferCopyDataBytes(blockBuffer, 0, size, outBytes!)
            CMSampleBufferInvalidate(buffer!)
            let i8 = outBytes?.assumingMemoryBound(to: UInt8.self)
            let i8buff = UnsafeBufferPointer(start: i8, count: size)
            data.append(Array(i8buff), count: size)
            free(outBytes)
        }
        reader?.cancelReading()
        return data
        
    }
    
    func bitReverse(_ n : Int,_ bits : Int) -> Int {
        
        var nn = n
        var reverseN : Int = n
        var count : Int = bits - 1
        
        nn >>= 1
        while nn > 0{
            reverseN = (reverseN << 1 ) | (nn & 1)
            count -= 1
            nn >>= 1
        }
        
        return ((reverseN << count ) & ((1 << bits) - 1))
        
    }
    
    func transformFFT(_ x: [Complex] ) -> [Complex]{
        
        var xx = x
        let bits : Int = Int (log(Double(x.count)) / log(2.0))
        var even : Complex
        var odd : Complex
        
        for j in 1..<x.count/2{
            
            let swapPos = bitReverse(j,bits)
            let temp : Complex = x[j]
            xx[j] = xx[swapPos]
            xx[swapPos] = temp
        }
        
        var N : Int = 2
        while N <= xx.count{
            var i : Int = 0
            while i < xx.count{
                for k : Int in 0 ..< N/2 {
                    let evenIndex : Int = i + k
                    let oddIndex : Int = i + k + (N/2)
                    even = x[evenIndex]
                    odd = x[oddIndex]
                    
                    let term : Double = (-2.0 * Double.pi * Double(k)) / Double(N)
                    let exp : Complex = Complex(cos(term),sin(term)).times(odd)
                    
                    xx[evenIndex] = even.plus(exp)
                    xx[oddIndex] = even.minus(exp)
                }
                i += N
            }
            N = N << 1
        }
        
        return xx
    }
    
    func tranformBytes(audioData : Data ){
        let totalSize = audioData.count
        let chunkSize = 4096
        let sampleChunkSize = totalSize/chunkSize //chunk size
        
        var result: [[Complex]] = []
        
        //print(audioData)
        //print(totalSize)
        for j in 0..<sampleChunkSize{
            var complexArray : [Complex] = []
            
            for i in 0..<chunkSize{
                complexArray.append(Complex(Double(audioData[j * chunkSize + i]),0))
            }
            
            result.insert(transformFFT(complexArray), at: j)
            
        }
        
        getFrequencyWithMagnitude(result: result)
    }
    
    func getIndex(_ freq : Int) -> Int {
        var i = 0
        while Range[i] < freq{
            i += 1
        }
        return i
        
    }
    
    func getFrequencyWithMagnitude( result : [[Complex]] ){
        
        var highScores : [[Double]] = []
        var points : [[Double]] = []
        
        for t in 0..<result.count{
            var highScoresAux: [Double] = []
            var pointsAux : [Double] = []
            for freq in 40..<300{
                let index =  getIndex(freq)
                highScoresAux.insert(0, at: index)
                pointsAux.insert(0, at: index)
                //                if freq < result[t].count && (result[t][freq].re > 0.0 && result[t][freq].im > 0.0) {
                //                    print("im",result[t][freq].im)
                //                    print("re",result[t][freq].re)
                //                }
            }
            highScores.insert(highScoresAux, at: t)
            points.insert(pointsAux, at: t)
        }
        
        for t in 0..<result.count{
            for freq in 40..<300{
                if result[t].count > freq {
                    let mag = log(result[t][freq].abs() + 1)
                    let index = getIndex(freq)
                    print(mag)
                    if mag > highScores[t][index] {
                        highScores[t][index] = mag
                        points[t][index] = Double(freq)
                    }
                }
            }
            let h : Double = hash(p1: points[t][1], p2: points[t][2], p3: points[t][3], p4: points[t][4])
            for k in 0..<result[t].count {
                print("time ",result[t][k].re,result[t][k].im)
            }
            print("hash ",h)
            print("\n")
        }
        
    }
    
    func hash( p1 : Double, p2 : Double, p3 : Double, p4 : Double) -> Double{
        
        let var4 = (p4 - (p4.truncatingRemainder(dividingBy: fuzz_factor))) * 100000000
        let var3 = (p3 - (p3.truncatingRemainder(dividingBy: fuzz_factor))) * 100000
        let var2 = (p2 - (p2.truncatingRemainder(dividingBy: fuzz_factor))) * 100
        let var1 = p1 - (p1.truncatingRemainder(dividingBy: fuzz_factor))
        
        return var1 + var2 + var3 + var4
        
    }
    
    @IBAction func backAction(_ sender: Any){
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
}
