//
//  DetailViewController.h
//  Cruncher Studio
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController
@property (readonly) IBOutlet UIView *partView;
@property (readonly) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
- (IBAction)addPart:(id)sender;
- (IBAction)zoomToNormal:(id)sender;
@end

