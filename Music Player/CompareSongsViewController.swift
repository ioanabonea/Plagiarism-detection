//
//  CompareSongsViewController.swift
//  Music Player
//
//  Created by Bonea Ioana on 6/19/17.
//  Copyright © 2017 Sem. All rights reserved.
//

import Alamofire
import Foundation
import AVFoundation

class CompareSongsViewController: UIViewController{
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    
    
    
    var firstSongURL: String!
    var secondSongURL: String!
    
    
    let Range = [40,80,120,180,300]
    let fuzz_factor : Double = 2
    
    private var mp3_1:Data?
    private var mp3_2:Data?
    
    private var mp3_hashes_tables:[[Double:Int]] = []
    private var mp3_hash_array:[[Double]] = []
    
    private var players:[AVPlayer] = []
    private var playerSource:[URL] = []
    private var time:[Int] = []
    
    private var no_hashes = 0
    
    private var start1:CMTime!
    private var end1:CMTime!
    private var start2:CMTime!
    private var end2:CMTime!
    
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activityIndicator.color = UIColor.purple
        activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.view.isUserInteractionEnabled = false

        
        getTheMp3(firstSongURL)
        
        print("second song \n")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.mp3_hashes_tables = []
        self.mp3_hash_array = []
        
        self.players = []
        self.playerSource = []
        self.time = []
        
        self.no_hashes = 0
    }
    
    func getTheMp3(_ urlField: String) {
        print(urlField)
        
        if self.no_hashes == 0{
            self.label1.text = "Getting first song..."
        }else{
            self.label2.text = "Getting second song..."
        }
        
        let url = urlField
        
        Alamofire.request( url ).responseJSON{
            response in
            
            print(response.result)
            
            guard let json = response.result.value as? [String:Any] else { return }
            
            guard let link = json["link"] as? String else { return }
            
            guard let seconds = json["length"] as? String else { return }
            
            self.time.append( Int( seconds )! )
            
            Alamofire.request( link ).responseData{
                response in
                
                self.mp3_1 = response.result.value
                
                let saveURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("\(self.no_hashes+1).mp3")
                
                self.playerSource.append( saveURL )
                
                try? response.result.value?.write(to: saveURL, options: .atomicWrite)

                print("fft")
                if self.no_hashes == 0{
                    self.label1.text = "Applying FFT algorithm to first song..."
                }else{
                    self.label2.text = "Applying FFT algorithm to second song..."
                }
                self.tranformBytes(audioData: self.mp3_1!)
                print(response.result)
                
               
            }
            
        }

    }
    
    func findSimilar()
    {
        //let totalTime = self.players[0].currentItem?.duration
        //let seekTime = CMTimeMultiplyByRatio(totalTime!, 50, 100)
        //self.players[0].seek(to: seekTime)
        print("Started to find similar")
        self.view.isUserInteractionEnabled = true

        
        label3.text = "Checking for similarity..."
        
        print("Started to find similar")
        
        var i1:Int = 0, i2:Int = 0
        var j1:Int = 0, j2:Int = 0
        
        var s1:Int = 0, s2:Int = 0
        var e1:Int = 0, e2:Int = 0
        
        for i in 1..<mp3_hashes_tables[0].count{
            if let found = mp3_hashes_tables[1][ mp3_hash_array[0][i] ] {
                for j in i+1..<mp3_hashes_tables[0].count {
                    if let found2 = mp3_hashes_tables[1][ mp3_hash_array[0][j] ]{
                        i1 = i
                        j1 = found
                        i2 = j
                        j2 = found2
                        print("i1",i1)
                        print("i2",i2)
                        print("j1", j1)
                        print("j2", j2)
                        if i1 < i2 && j1 < j2 {

                            s1 = i1
                            s2 = j1
                            e1 = i2
                            e2 = j2
                        }
                    }
                }
            }
        }
        
        
        let start1Proc = Float(s1)/Float(mp3_hashes_tables[0].count)
        let end1Proc = Float(s2)/Float(mp3_hashes_tables[0].count)
        
        let start2Proc = Float(e1)/Float(mp3_hashes_tables[1].count)
        let end2Proc = Float(e2)/Float(mp3_hashes_tables[1].count)
        
        print("start1=", start1Proc)
        print("end1=", end1Proc)
        
        print("start2=", start2Proc)
        print("end2=", end2Proc)
        
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        
        self.start1 = CMTime.init(seconds: Double(time[0]), preferredTimescale: 1000)
        start1 = CMTimeMultiplyByRatio(start1, Int32(start1Proc*1000), 1000)
        self.end1 = CMTime.init(seconds: Double(time[0]), preferredTimescale: 1000)
        end1 = CMTimeMultiplyByRatio(end1, Int32(end1Proc*1000), 1000)
        
        
        self.start2 = CMTime.init(seconds: Double(time[1]), preferredTimescale: 1000)
        start2 = CMTimeMultiplyByRatio(start2, Int32(start2Proc*1000), 1000)
        self.end2 = CMTime.init(seconds: Double(time[1]), preferredTimescale: 1000)
        end2 = CMTimeMultiplyByRatio(end2, Int32(end2Proc*1000), 1000)
        
        //init av players here
        self.players.append( AVPlayer(url: self.playerSource[0] ) )
        self.players.append( AVPlayer(url: self.playerSource[1] ) )
        
        self.players[0].currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        
        //self.players[1].play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        
        guard keyPath == "status" else { return }
        
        print( "=====")
        print( playerItem.status == .readyToPlay ) //true
        print( playerItem.error ) //nil
        print( "=====")
        
        self.players[0].play()
        self.players[0].seek(to: self.start1, toleranceBefore: kCMTimeZero, toleranceAfter:kCMTimeZero)
        
        self.players[0].addBoundaryTimeObserver( forTimes:[NSValue.init(time:self.end1)], queue:nil ){
            print("stoping first player")
            self.players[0].pause()
            
            print("starting second player")
            self.players[1].play()
            self.players[1].seek(to: self.start2)
            
            self.players[1].addBoundaryTimeObserver( forTimes:[NSValue.init(time:self.end2)], queue:nil ){
                print("stoping second player")
                self.players[1].pause()
            }
        }
        
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
            }
            highScores.insert(highScoresAux, at: t)
            points.insert(pointsAux, at: t)
        }
        
        var hashTable:[Double:Int] = [:]
        var hashArray:[Double] = []
        
        for t in 0..<result.count{
            for freq in 40..<300{
                if result[t].count > freq {
                    let mag = log(result[t][freq].abs() + 1)
                    let index = getIndex(freq)
                    //print(mag)
                    if mag > highScores[t][index] {
                        highScores[t][index] = mag
                        points[t][index] = Double(freq)
                    }
                }
            }
            let h : Double = hash(p1: points[t][1], p2: points[t][2], p3: points[t][3], p4: points[t][4])
            hashTable[h] = t
            hashArray.append(h)
            //for k in 0..<result[t].count {
                //print("time ",result[t][k].re,result[t][k].im)
            //}
            //print("hash ",h)
            //print("\n")
        }
        
        self.mp3_hashes_tables.append( hashTable )
        self.mp3_hash_array.append( hashArray )
        
        self.no_hashes = self.no_hashes + 1
        
        if( self.no_hashes == 2 )
        {
            label2.text = "Finished FFT transformation for second song!"
            self.findSimilar()
        }else{
            label1.text = "Finished FFT transformation for first song!"
            self.getTheMp3(self.secondSongURL)
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
        if self.players.count == 2{
            self.players[0].pause()
            self.players[1].pause()
        }
        
        let _ = self.dismiss(animated: true, completion: nil)
    }
    
}
