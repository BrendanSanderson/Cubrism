//
//  LevelSelectCollectionViewController.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/25/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit
class LevelSelectCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
//    init() {
//        super.init(nibName: "LevelSelectCollectionViewController", bundle: nil)
//    }
    var pageControl = UIPageControl()
    var homeView = HomeViewController()
    private let numberOfWorlds = 5
    private var backgroundViews = [UIImageView]()
    private var backImageView = UIImageView()
    private var lastLayoutSize = CGSize.zero
    override func loadView() {
        self.view = UIView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: flowLayout)
        addBackgrounds()
        
        self.collectionView!.showsHorizontalScrollIndicator = false;
        self.collectionView!.isPagingEnabled = true;
        self.collectionView!.delegate = self;
        self.collectionView!.dataSource = self;
        
        
        self.view.addSubview(self.collectionView!)
        
        //self.collectionView!.backgroundColor = UIColor(patternImage: UIImage(named:  String(format: "background%i", 1))!)
        self.collectionView!.backgroundColor = UIColor.clear
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(LevelCell.self, forCellWithReuseIdentifier: "Cell")
         //self.collectionView!.registerNib(UINib(nibName:"LevelCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        // Do any additional setup after loading the view.
        
        self.pageControl = UIPageControl()
        
        self.pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: UIControl.Event.valueChanged)
        
        self.pageControl.numberOfPages = numberOfWorlds;
        self.pageControl.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
        self.view.addSubview(self.pageControl)
        
        
        backImageView.image = UIImage(named: "backButton")
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(LevelSelectCollectionViewController.back(_:)))
        backImageView.isUserInteractionEnabled = true
        backImageView.addGestureRecognizer(tapGestureRecognizer)
        self.view.addSubview(backImageView)
        layoutLevelSelectViews()
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutLevelSelectViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if targetEnvironment(macCatalyst)
        becomeFirstResponder()
        Player.entity.stopControls()
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func back(_ img: AnyObject)
    {
        self.dismiss(animated: false, completion: nil)
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

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return numberOfWorlds
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 10
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! LevelCell
        cell.backgroundColor = UIColor.blue
        cell.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        
        cell.imageView.image = UIImage(named: "background\((indexPath.section + 1))Cell")
        cell.cellLabel = UILabel(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        cell.cellLabel.textAlignment = .center
        cell.cellLabel.text = "\((indexPath.row + 1))"
        
        if !isLevelUnlocked(at: indexPath, completedLevel: UserDefaults.standard.object(forKey: "LevelCompleted") as! Int) {
            let bottomImage = UIImage(named: "background\((indexPath.section + 1))Cell")
            let topImage = UIImage(named: "lockedCell")
            
            let size = CGSize(width: topImage!.size.width, height: topImage!.size.height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            
            bottomImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height));
            topImage!.draw(in: CGRect(x: 0,y: 0,width: size.width, height: size.height));
            
            
            let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            cell.imageView.image = newImage
        }
        cell.addSubview(cell.imageView)
        cell.addSubview(cell.cellLabel)
        moveBackgroundsToBack()
        return cell
        // Configure the cell
    
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
//        if indexPath.section == 4
//        {
//            homeView.floorView.min = UInt32(1)
//            homeView.floorView.max = UInt32(1)
//            homeView.floorView.level = Player.level
//            self.dismiss(animated: false, completion: nil)
//            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToLevelFloorViewController"),  object: nil)
//        }
        if isLevelUnlocked(at: indexPath, completedLevel: UserDefaults.standard.object(forKey: "LevelCompleted") as! Int) {
            
        if let path = Bundle.main.path(forResource: "levels", ofType: "plist"), let dict = NSArray(contentsOfFile: path){
            #if targetEnvironment(macCatalyst)
            Player.entity.stopControls()
            #endif
            let level = dict[indexPath.item] as? NSDictionary
            
            homeView.floorView.min = UInt32(((level?.value(forKey: "min")) as? Int)!)
            homeView.floorView.max = UInt32(((level?.value(forKey: "max")) as? Int)!)
            homeView.floorView.level = ((level?.value(forKey: "level")) as? Int)!
//            if (Constants.dev == true && ((level?.value(forKey: "level")) as? Int)! == 10)
//            {
//                homeView.floorView.min = 1
//                homeView.floorView.max = 1
//            }
            homeView.floorView.world = indexPath.section + 1
            
            self.dismiss(animated: false) {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToLevelFloorViewController"), object: nil)
            }
        }
        }
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: collectionView.bounds.size.width * 0.08, height: collectionView.bounds.size.height * 0.15)
        //return collectionView.bounds.size
    }
    @objc func pageControlChanged(_ sender: UIPageControl)
    {
    
        let pageControl = sender
        let pageWidth = self.collectionView!.frame.size.width
        let scrollTo = CGPoint(x: pageWidth * CGFloat(pageControl.currentPage), y: 0);
        self.collectionView?.setContentOffset(scrollTo, animated: true)
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = self.collectionView!.frame.size.width
        self.pageControl.currentPage = Int(self.collectionView!.contentOffset.x / pageWidth)
//        }
    }

    func levelNumber(for indexPath: IndexPath) -> Int {
        return (indexPath.section * 10) + indexPath.item
    }

    func isLevelUnlocked(at indexPath: IndexPath, completedLevel: Int) -> Bool {
        return levelNumber(for: indexPath) <= completedLevel
    }

    #if targetEnvironment(macCatalyst)
    override var canBecomeFirstResponder : Bool {
        return true
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        Player.entity.stopControls()
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        Player.entity.stopControls()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        Player.entity.stopControls()
    }
    #endif

    func addBackgrounds()
    {
        for world in 1...numberOfWorlds {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "background\(world)")
            backgroundViews.append(imageView)
            self.collectionView?.addSubview(imageView)
        }
        
    }
    func moveBackgroundsToBack()
    {
        for backgroundView in backgroundViews {
            self.collectionView?.sendSubviewToBack(backgroundView)
        }
    }

    private func layoutLevelSelectViews() {
        let w = self.view.bounds.size.width
        let h = self.view.bounds.size.height
        if w <= 0 || h <= 0 {
            return
        }
        let sizeChanged = self.view.bounds.size != lastLayoutSize

        self.collectionView?.frame = self.view.bounds
        self.pageControl.frame = CGRect(x: 0, y: h - 60, width: w, height: 60)

        let backSize = min(w, h) * 0.08
        backImageView.frame = CGRect(x: w - backSize - (w * 0.05), y: h * 0.08, width: backSize, height: backSize)

        for (index, imageView) in backgroundViews.enumerated() {
            imageView.frame = CGRect(x: CGFloat(index) * w, y: 0, width: w, height: h)
        }

        if sizeChanged, let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            let cellSize = CGSize(width: w * 0.08, height: h * 0.15)
            let columns = CGFloat(4)
            let rows = CGFloat(3)
            let lineSpacing = w * 0.05
            let interitemSpacing = w * 0.05
            let horizontalInset = max(0, (w - (columns * cellSize.width) - ((columns - 1) * lineSpacing)) / 2)
            let verticalInset = max(0, (h - (rows * cellSize.height) - ((rows - 1) * interitemSpacing)) / 2)

            flowLayout.minimumLineSpacing = lineSpacing
            flowLayout.minimumInteritemSpacing = interitemSpacing
            flowLayout.sectionInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
            flowLayout.invalidateLayout()
        }

        let contentOffset = CGPoint(x: w * CGFloat(pageControl.currentPage), y: 0)
        if self.collectionView?.contentOffset != contentOffset {
            self.collectionView?.contentOffset = contentOffset
        }
        lastLayoutSize = self.view.bounds.size
        moveBackgroundsToBack()
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
