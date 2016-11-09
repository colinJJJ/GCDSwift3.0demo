//
//  ViewController.swift
//  GCDTest
//
//  Created by ColinJ on 2016/11/7.
//  Copyright © 2016年 ColinJ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let queue = DispatchQueue(label: "第一条线程")
    let queue1 = DispatchQueue(label: "第二条线程", qos: DispatchQoS.default, attributes: .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem, target: nil)
    var myTimer:DispatchSourceTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.GCDTest1()
//        self.GCDTest2()
//        self.GCDTest3()
//        self.GCDTest4()
//        self.GCDTest5()
//        self.GCDTest6()
//        self.GCDTest7()
//        self.GCDTest8()
//        self.GCDTest9()
        self.GCDTest10()

}
    func GCDTest1() -> Void {
        queue.sync {
            for i in 0...10 {
                print("i = \(i)" + "\(Thread.current)");
            }
        }
        queue.async {
            for i in 0...10 {
                print("i = \(i) -------------\(Thread.current)");
            }
        }
    }
    
    func GCDTest2() -> Void {
        DispatchQueue.global().async {
            for i in 0...10 {
                print("i = \(i) +++++++++++++ \(Thread.current)");
            }
            DispatchQueue.main.async {
                print(Thread.current)
            }
        }
    }
    
    func GCDTest3() -> Void {
        queue1.async {  //任务1
            for _ in 0...10{
                print("1111111")
            }
        }
        queue1.async {  //任务2
            for _ in 0...10{
                print("222222")
            }
        }
        // barrier 会等待上面执行完毕再执行下面的，会阻塞当前线程
//        queue.async(flags: DispatchWorkItemFlags.barrier) { //NO.1
//                    print("=======")
//        }
        queue1.async(group: nil, qos: .default, flags: .barrier) { //NO.2
            print("=======")
        }
        queue1.async {
            print("ok")
        }
    }
    
    func GCDTest4() {
        //主队列
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            print("主队列延时提交的任务")
        }
        
        //指定队列
        queue1.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
            print("我的队列延时提交的任务")
        })
    }
    
    func GCDTest5() {
        //初始化信号量, 计数为三
        let mySemaphore = DispatchSemaphore(value: 3)
        for i in 0...5 {
            print(i)
            let _ = mySemaphore.wait()  //获取信号量，信号量减1，为0时候就等待,会阻碍当前线程
//            let _ = mySemaphore.wait(timeout: DispatchTime.now() + 2.0) //阻碍时等两秒信号量还是为0时将不再等待, 继续执行下面的代码
            queue1.async {
                for j in 0...3 {
                    print("有限资源\(j)------\(i)")
                    sleep(UInt32(3.0))
                }
                print("-------------------")
                
                    mySemaphore.signal()
                
            }  
            
        }  
        
    }
    
    func GCDTest6() -> Void {
        let mySemaphore = DispatchSemaphore.init(value: 5)
        for i in 0...10 {
            NSLog("----i:%d----", i)
            mySemaphore.wait()  //获取信号量，信号量减1，为0时候就等待,会阻碍当前线程
            queue1.async {
                for j in 0...4 {
                    NSLog("%d++++j:%d",i, j)
                }
                mySemaphore.signal()  //释放信号量，信号量加1
            }
        }
    }
    
    func GCDTest7()  {
        //      秒               毫秒                      微秒                      纳秒
        //  1 seconds = 1000 milliseconds = 1000,000 microseconds = 1000,000,000 nanoseconds
        myTimer = DispatchSource.makeTimerSource(flags: [], queue: queue1)
        myTimer?.scheduleRepeating(deadline: .now(), interval: .seconds(1) ,leeway:.milliseconds(100))
        
        myTimer?.setEventHandler {
            print("fff")
        }
        myTimer?.resume()
//        myTimer?.cancel()
//        myTimer?.activate()
    }
    
    func GCDTest8() {
        let group = DispatchGroup()
        queue1.async(group: group, qos: .default, flags: [], execute: {
            for _ in 0...10 {
                print("耗时任务一")
            }
        })
        queue1.async(group: group, qos: .default, flags: [], execute: {
            for _ in 0...10 {
                print("耗时任务二")
            }
        })
        //执行完上面的两个耗时操作, 回到myQueue队列中执行下一步的任务
        group.notify(queue: queue1) {
            print("回到该队列中执行")  
        }
    }
    
    func GCDTest9() {
        let group = DispatchGroup()
        queue1.async(group: group, qos: .default, flags: [], execute: {
            for _ in 0...10 {
                
                print("耗时任务一")
            }
        })
        queue1.async(group: group, qos: .default, flags: [], execute: {
            for _ in 0...10 {
                
                print("耗时任务二")
                sleep(UInt32(3))
            }
        })
        //等待上面任务执行，会阻塞当前线程，超时就执行下面的，上面的继续执行。可以无限等待 .distantFuture
        let result = group.wait(timeout: .now() + 2.0)
        switch result {
        case .success:
            print("不超时, 上面的两个任务都执行完")
        case .timedOut:
            print("超时了, 上面的任务还没执行完执行这了")  
        }  
        
        print("接下来的操作")
    }
    
    func GCDTest10() {
        let group = DispatchGroup()
        group.enter()//把该任务添加到组队列中执行
        queue1.async(group: group, qos: .default, flags: [], execute: {
            for _ in 0...10 {
                print("耗时任务一")
            }
            group.leave()//执行完之后从组队列中移除
        })
        group.enter()//把该任务添加到组队列中执行
        queue1.async(group: group, qos: .default, flags: [], execute: {
            for _ in 0...10 {
                print("耗时任务二")
            }
            group.leave()//执行完之后从组队列中移除
        })
        //当上面所有的任务执行完之后通知
        group.notify(queue: .main) {   
            print("所有的任务执行完了")  
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

