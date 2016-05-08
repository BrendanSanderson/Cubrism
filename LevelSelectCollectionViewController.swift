//
//  LevelSelectCollectionViewController.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/25/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit
class LevelSelectCollectionViewController: UICollectionViewController {
//    init() {
//        super.init(nibName: "LevelSelectCollectionViewController", bundle: nil)
//    }
    var pageControl = UIPageControl()
    var homeView = HomeViewController()
    override func loadView() {
        self.view = UIView(frame: UIScreen.mainScreen().bounds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        flowLayout.minimumLineSpacing = self.view.frame.width * 0.05
        flowLayout.minimumInteritemSpacing = self.view.frame.width * 0.05
        flowLayout.sectionInset = UIEdgeInsets(top: self.view.frame.height * 0.3, left: self.view.frame.width * 0.2, bottom: self.view.frame.height * 0.3, right: self.view.frame.width * 0.2)
        self.collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: flowLayout)
        addBackgrounds()
        
        self.collectionView!.showsHorizontalScrollIndicator = false;
        self.collectionView!.pagingEnabled = true;
        self.collectionView!.delegate = self;
        self.collectionView!.dataSource = self;
        
        
        self.view.addSubview(self.collectionView!)
        
        //self.collectionView!.backgroundColor = UIColor(patternImage: UIImage(named:  String(format: "background%i", 1))!)
        self.collectionView!.backgroundColor = UIColor.clearColor()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.registerClass(LevelCell.self, forCellWithReuseIdentifier: "Cell")
         //self.collectionView!.registerNib(UINib(nibName:"LevelCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        // Do any additional setup after loading the view.
        
        let w = self.view.frame.size.width
        let h = self.view.frame.size.height
        let frame = CGRectMake(0, h - 60, w, 60)
        self.pageControl = UIPageControl(frame: frame)
        
        self.pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        self.pageControl.numberOfPages = 5;
        self.pageControl.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        self.view.addSubview(self.pageControl)
        
        
        let backImage = UIImageView(frame: CGRect(x: w * 0.9 , y: w * 0.05, width: w * 0.05, height: w * 0.05))
        backImage.image = UIImage(named: "backButton")
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(LevelSelectCollectionViewController.back(_:)))
        backImage.userInteractionEnabled = true
        backImage.addGestureRecognizer(tapGestureRecognizer)
        self.view.addSubview(backImage)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func back(img: AnyObject)
    {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 10
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! LevelCell
        cell.backgroundColor = UIColor.blueColor()
        cell.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        
        cell.imageView.image = UIImage(named: "background\((indexPath.section + 1))Cell")
        cell.cellLabel = UILabel(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        cell.cellLabel.textAlignment = .Center
        cell.cellLabel.text = "\((indexPath.row + 1))"
        
        if (indexPath.section * 10) + indexPath.item > (NSUserDefaults.standardUserDefaults().objectForKey("LevelCompleted") as! Int){
            let bottomImage = UIImage(named: "background\((indexPath.section + 1))Cell")
            let topImage = UIImage(named: "lockedCell")
            
            let size = CGSizeMake(topImage!.size.width, topImage!.size.height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            
            [bottomImage!.drawInRect(CGRectMake(0, 0, size.width, size.height))];
            [topImage!.drawInRect(CGRectMake(0,0,size.width, size.height))];
            
            
            let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            cell.imageView.image = newImage
        }
        cell.addSubview(cell.imageView)
        cell.addSubview(cell.cellLabel)
        moveBackgroundsToBack()
        return cell
        // Configure the cell
    
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 4
        {
            homeView.floorView.min = UInt32(1)
            homeView.floorView.max = UInt32(1)
            homeView.floorView.level = Player.level
            self.dismissViewControllerAnimated(false, completion: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("GoToLevelFloorViewController",  object: nil)
        }
        else if indexPath.item <= (NSUserDefaults.standardUserDefaults().objectForKey("LevelCompleted") as! Int){
            
        if let path = NSBundle.mainBundle().pathForResource("levels", ofType: "plist"), dict = NSArray(contentsOfFile: path){
            let level = dict[indexPath.item] as? NSDictionary
            
            homeView.floorView.min = UInt32(((level?.valueForKey("min")) as? Int)!)
            homeView.floorView.max = UInt32(((level?.valueForKey("max")) as? Int)!)
            homeView.floorView.level = ((level?.valueForKey("level")) as? Int)!
            
            self.dismissViewControllerAnimated(false, completion: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("GoToLevelFloorViewController",  object: nil)
        }
        }
        
    }
    
    
    
    func collectionView(collectionView: UICollectionView,
                                   layout collectionViewLayout: UICollectionViewLayout,
                                          sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSize(width: collectionView.bounds.size.width * 0.08, height: collectionView.bounds.size.height * 0.15)
        //return collectionView.bounds.size
    }
    func pageControlChanged(sender: UIPageControl)
    {
    
        let pageControl = sender
        let pageWidth = self.collectionView!.frame.size.width
        let scrollTo = CGPointMake(pageWidth * CGFloat(pageControl.currentPage), 0);
        self.collectionView?.setContentOffset(scrollTo, animated: true)
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageWidth = self.collectionView!.frame.size.width
        self.pageControl.currentPage = Int(self.collectionView!.contentOffset.x / pageWidth)
//        }
    }

    func addBackgrounds()
    {
        let w = self.view.frame.size.width
        let h = self.view.frame.size.height
        let imageView1 = UIImageView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        imageView1.image = UIImage(named: "background1")
        
        let imageView2 = UIImageView(frame: CGRect(x: w, y: 0, width: w, height: h))
        imageView2.image = UIImage(named: "background2")
        
        let imageView3 = UIImageView(frame: CGRect(x: 2.0 * w, y: 0, width: w, height: h))
        imageView3.image = UIImage(named: "background3")
        let imageView4 = UIImageView(frame: CGRect(x: 3.0 * w, y: 0, width: w, height: h))
        imageView4.image = UIImage(named: "background3")
        
        
        let imageView5 = UIImageView(frame: CGRect(x: 4.0 * w, y: 0, width: w, height: h))
        imageView5.image = UIImage(named: "background1")
        
        self.collectionView?.addSubview(imageView1)
        self.collectionView?.addSubview(imageView2)
        self.collectionView?.addSubview(imageView3)
        self.collectionView?.addSubview(imageView4)
        self.collectionView?.addSubview(imageView5)
        
    }
    func moveBackgroundsToBack()
    {
        for i in 0 ..< self.collectionView!.subviews.count
        {
            if ((self.collectionView?.subviews[i].isKindOfClass(UIImageView)) != nil)
            {
                self.collectionView?.sendSubviewToBack((self.collectionView?.subviews[i])!)
            }
        }
    }
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
}
