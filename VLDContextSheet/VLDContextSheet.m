//
//  VLDContextSheet.m
//
//  Created by Vladimir Angelov on 2/7/14.
//  Copyright (c) 2014 Vladimir Angelov. All rights reserved.
//

#import "VLDContextSheetItemView.h"
#import "VLDContextSheet.h"
#import "VLDContextSheetItem.h"

typedef struct {
    CGRect rect;
    CGFloat rotation;
} VLDZone;

static const NSInteger VLDTouchDistanceAllowance = 60; // a distance around each item center where we consider the touch to be in the item sensitive area. Typically it defines the radius of a circle  around each item center we consider the item is targeted.
//static const NSInteger VLDZonesCount = 10;
//
//static inline VLDZone VLDZoneMake(CGRect rect, CGFloat rotation) {
//    VLDZone zone;
//
//    zone.rect = rect;
//    zone.rotation = rotation;
//
//    return zone;
//}

static CGFloat VLDVectorDotProduct(CGPoint vector1, CGPoint vector2) { // math reminder: the dot product (produit scalaire in french) is equal to: cos(alpha) * ||v1->|| * ||v2->|| but is also equal to v1.x*v2.x+v1.y*v2.y. It helps know the angle (alpha) between 2 vectors. If cos(alpha) is close to 1, it means the 2 vectors have "very near" (points to the same direction).
    return vector1.x * vector2.x + vector1.y * vector2.y;
}

static CGFloat VLDVectorLength(CGPoint vector) {
    return sqrt(vector.x * vector.x + vector.y * vector.y);
}

@interface VLDContextSheet ()

@property (strong, nonatomic) NSArray *itemViews;
//@property (strong, nonatomic) UIView *centerView;
@property (strong, readwrite, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) VLDContextSheetItemView *selectedItemView;
@property (assign, nonatomic) BOOL openAnimationFinished;
@property (assign, nonatomic) CGPoint touchCenter;
@property (strong, nonatomic) UIGestureRecognizer *starterGestureRecognizer;

@end

@implementation VLDContextSheet {
    
//    VLDZone zones[VLDZonesCount];
}

- (id) initWithFrame: (CGRect) frame {
    return [self initWithItems: nil];
}

- (id) initWithItems: (NSArray *) items {
    return [self initWithItems:items itemSize:CGSizeMake(50, 83)];
}

- (id) initWithItems: (NSArray *) items itemSize: (CGSize) itemSize {
    self = [super initWithFrame: CGRectZero];
    
    if(self) {
        _items = items;
        _itemSize = itemSize;
        _radius = 100;
        _rangeAngle = M_PI / 1.6;
        
        [self createSubviews];
    }
    
    return self;
}

- (void) dealloc {
    [self.starterGestureRecognizer removeTarget: self action: @selector(gestureRecognizedStateObserver:)];
}

-(void)setSelectedItemView:(VLDContextSheetItemView *)selectedItemView
{
    _selectedItemView = selectedItemView;
    _selectedItemTitleLabel.text = selectedItemView.item.title;
    _selectedItemTitleLabel.textColor = selectedItemView.item.isEnabled ? [UIColor whiteColor] : [UIColor colorWithWhite:0.5 alpha:1];
    [self setNeedsLayout];
}

- (void) createSubviews {
//    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
    //        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]; // UIBlurEffectStyleDark, UIBlurEffectStyleLight, UIBlurEffectStyleExtraLight, UIBlurEffectStyleRegular, UIBlurEffectStyleProminent are all too strong :(
//        _backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//    }
//    else {
    _backgroundView = [[UIView alloc] initWithFrame: CGRectZero];
    _backgroundView.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.7];
    [_backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endContextSheetByTap:)]];
//    }
    [self addSubview: self.backgroundView];
    
    _selectedItemTitleLabel = [[UILabel alloc] init];
    _selectedItemTitleLabel.clipsToBounds = YES;
    _selectedItemTitleLabel.font = [UIFont boldSystemFontOfSize:18.];
    _selectedItemTitleLabel.numberOfLines = 3;
    _selectedItemTitleLabel.textAlignment = NSTextAlignmentCenter;
    _selectedItemTitleLabel.layer.cornerRadius = 7;
    _selectedItemTitleLabel.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.4];
    _selectedItemTitleLabel.textColor = [UIColor whiteColor]; // lightGray when enabled==NO
    _selectedItemTitleLabel.alpha = 0.0;
    [self addSubview:_selectedItemTitleLabel];
    
    _itemViews = [[NSMutableArray alloc] init];
    
    for(VLDContextSheetItem *item in _items) {
        VLDContextSheetItemView *itemView = [[VLDContextSheetItemView alloc] initWithFrame:CGRectMake(0, 0, self.itemSize.width, self.itemSize.height)];
        //itemView.titleLabelIsHidden = YES; // use global, big selectedItemTitleLabel instead of per item labels.
        itemView.titleLabelIsAlwaysVisible = YES; // we want the item title to always be visible
        itemView.item = item;
        
        [self addSubview: itemView];
        [(NSMutableArray *) _itemViews addObject: itemView];
    }

//    CGFloat circleDiameter = MIN(self.itemSize.width, self.itemSize.height);
//    _centerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, circleDiameter, circleDiameter)];
//    _centerView.layer.cornerRadius = circleDiameter / 2.0;
//    _centerView.layer.borderWidth = 2;
//    _centerView.layer.borderColor = [UIColor grayColor].CGColor;
//    [self addSubview: _centerView];

}

- (void) layoutSubviews {
    [super layoutSubviews];
        
    self.backgroundView.frame = self.bounds;
    self.selectedItemTitleLabel.preferredMaxLayoutWidth = self.bounds.size.width - 2*10; // 10pt for padding left and right
    
    if(self.selectedItemTitleLabel.text.length > 0) {
        CGSize selectedItemTitleLabelSize = self.selectedItemTitleLabel.intrinsicContentSize;
        selectedItemTitleLabelSize = CGSizeMake(selectedItemTitleLabelSize.width+2*5, selectedItemTitleLabelSize.height+2*4); // 10pt for padding left and right, 8pt for padding top and bottom
        self.selectedItemTitleLabel.frame = CGRectMake((self.frame.size.width - selectedItemTitleLabelSize.width) / 2., 20., selectedItemTitleLabelSize.width, selectedItemTitleLabelSize.height);
    }
}

//- (void) setCenterViewHighlighted: (BOOL) highlighted {
//    _centerView.backgroundColor = highlighted ? [UIColor colorWithWhite: 0.5 alpha: 0.4] : nil;
//}

//- (void) createZones {
//    CGRect screenRect = self.bounds;
//
//    NSInteger rowHeight1 = self.itemSize.height + self.radius;
//
//    zones[0] = VLDZoneMake(CGRectMake(0, 0, 70, rowHeight1), 0.8);
//    zones[1] = VLDZoneMake(CGRectMake(zones[0].rect.size.width, 0, 40, rowHeight1), 0.4);
//
//    zones[2] = VLDZoneMake(CGRectMake(zones[1].rect.origin.x + zones[1].rect.size.width, 0, screenRect.size.width - 2 *(zones[0].rect.size.width + zones[1].rect.size.width), rowHeight1), 0);
//
//    zones[3] = VLDZoneMake(CGRectMake(zones[2].rect.origin.x + zones[2].rect.size.width, 0, zones[1].rect.size.width, rowHeight1),  -zones[1].rotation);
//    zones[4] = VLDZoneMake(CGRectMake(zones[3].rect.origin.x + zones[3].rect.size.width, 0, zones[0].rect.size.width, rowHeight1), -zones[0].rotation);
//
//    NSInteger rowHeight2 = screenRect.size.height - zones[0].rect.size.height;
//
//    zones[5] = VLDZoneMake(CGRectMake(0, zones[0].rect.size.height, zones[0].rect.size.width, rowHeight2), M_PI - zones[0].rotation);
//    zones[6] = VLDZoneMake(CGRectMake(zones[5].rect.size.width, zones[5].rect.origin.y, zones[1].rect.size.width, rowHeight2), M_PI - zones[1].rotation);
//    zones[7] = VLDZoneMake(CGRectMake(zones[6].rect.origin.x + zones[6].rect.size.width, zones[5].rect.origin.y, zones[2].rect.size.width, rowHeight2), M_PI - zones[2].rotation);
//    zones[8] = VLDZoneMake(CGRectMake(zones[7].rect.origin.x + zones[7].rect.size.width, zones[5].rect.origin.y, zones[3].rect.size.width, rowHeight2), M_PI - zones[3].rotation);
//    zones[9] = VLDZoneMake(CGRectMake(zones[8].rect.origin.x + zones[8].rect.size.width, zones[5].rect.origin.y, zones[4].rect.size.width, rowHeight2), M_PI - zones[4].rotation);
//
//    //[self drawZones];
//}
//
///* Only used for testing the touch zones */
//- (void) drawZones {
//    for(int i = 0; i < VLDZonesCount; i++) {
//        UIView *zoneView = [[UIView alloc] initWithFrame: zones[i].rect];
//
//        CGFloat hue = ( arc4random() % 256 / 256.0 );
//        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;
//        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;
//        UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
//
//        zoneView.backgroundColor = color;
//        [self addSubview: zoneView];
//    }
//}

- (void) updateItemView: (UIView *) itemView
          touchDistance: (CGFloat) touchDistance
               animated: (BOOL) animated  {
    
    if(!animated) {
        [self updateItemView: itemView touchDistance: touchDistance];
    }
    else  {        
        [UIView animateWithDuration: 0.4
                              delay: 0
             usingSpringWithDamping: 0.45
              initialSpringVelocity: 7.5
                            options: UIViewAnimationOptionBeginFromCurrentState
                         animations: ^{
                             [self updateItemView: itemView
                                               touchDistance: touchDistance];
                         }
                         completion: nil];
    }
}

- (void) updateItemView: (UIView *) itemView touchDistance: (CGFloat) touchDistance  {
    NSInteger itemIndex = [self.itemViews indexOfObject: itemView];
    CGFloat angle = /*-0.65*/0 + self.rotation + itemIndex * (self.rangeAngle / self.itemViews.count);
    //CGFloat resistanceFactor = 1.0 / (touchDistance > 0 ? 6.0 : 3.0);
    //itemView.center = CGPointMake(self.touchCenter.x + (self.radius + touchDistance * resistanceFactor) * sin(angle), self.touchCenter.y + (self.radius + touchDistance * resistanceFactor) * cos(angle));
    itemView.center = CGPointMake(self.touchCenter.x + self.radius*sin(angle), self.touchCenter.y + self.radius*cos(angle));
    
    CGFloat scale = 1 + 1 * (fabs(touchDistance) / self.radius);
    
    itemView.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void) openItemsFromCenterView {
    self.openAnimationFinished = NO;
    
    for(int i = 0; i < self.itemViews.count; i++) {
        VLDContextSheetItemView *itemView = self.itemViews[i];
        itemView.transform = CGAffineTransformIdentity;
        itemView.center = self.touchCenter;
        if(itemView.isHighlighted) {
            [self.delegate contextSheet:self willUnhighlightItemView:itemView withGestureRecognizer:self.starterGestureRecognizer];
        }
        [itemView setHighlighted: NO animated: NO];
        
        self.selectedItemTitleLabel.alpha = 0.;
        
        [UIView animateWithDuration: 0.5
                              delay: i * 0.01
             usingSpringWithDamping: 0.45
              initialSpringVelocity: 7.5
                            options: 0
                         animations: ^{
                             [self updateItemView: itemView touchDistance: 0.0];
                             
                         }
                         completion: ^(BOOL finished) {
                             self.openAnimationFinished = YES;
                         }];
    }
}

- (void) closeItemsToCenterView {
    [UIView animateWithDuration: 0.25
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         self.alpha = 1.0;
                     }];
    
}

- (void) startWithGestureRecognizer: (UIGestureRecognizer *) gestureRecognizer inView: (UIView *) view {
    [view addSubview: self];
    if ([view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        self.frame = UIEdgeInsetsInsetRect(scrollView.bounds, scrollView.contentInset);
    }
    else {
        self.frame = view.bounds;
    }
    //[self createZones];
    
    self.starterGestureRecognizer = gestureRecognizer;
    
    self.touchCenter = [self.starterGestureRecognizer locationInView: self];
    //self.centerView.center = self.touchCenter;
    self.selectedItemView = nil;
    //[self setCenterViewHighlighted: YES];
    self.rotation = M_PI/*[self rotationForCenter: self.touchCenter]*/;
    
    [self openItemsFromCenterView];
    
    [self resumeGestureRecognizerHandling];
}

- (void)pauseGestureRecognizerHandling
{
    [self.starterGestureRecognizer removeTarget:self action:@selector(gestureRecognizedStateObserver:)];
}

- (void)resumeGestureRecognizerHandling
{
    [self.starterGestureRecognizer addTarget:self action:@selector(gestureRecognizedStateObserver:)];
}


//- (CGFloat) rotationForCenter: (CGPoint) center {
//    for(NSInteger i = 0; i < VLDZonesCount; i++) {
//        VLDZone zone = zones[i];
//        
//        if(CGRectContainsPoint(zone.rect, center)) {
//            return zone.rotation;
//        }
//    }
//    
//    return 0;
//}

- (void) gestureRecognizedStateObserver: (UIGestureRecognizer *) gestureRecognizer {
    if(self.openAnimationFinished && gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self updateItemViewsForGestureRecognizerUpdate:gestureRecognizer];
    }
    else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if(self.selectedItemView && self.selectedItemView.isHighlighted) {
            [self.delegate contextSheet: self didSelectItemView: self.selectedItemView];
            if (self.didSelectItemViewHandler) {
                self.didSelectItemViewHandler(self.selectedItemView);
            }
        }
        else { // user lift finger outside of an item, so he wants to cancel
            [self end];
            [self.delegate contextSheetDidCancel:self];
        }
    }
    else if(gestureRecognizer.state == UIGestureRecognizerStateCancelled) { // also UIGestureRecognizerStateFailed?
        self.selectedItemView = nil;
        [self end];
        [self.delegate contextSheetDidCancel:self];
    }
}

- (CGFloat) signedTouchDistanceForTouchVector: (CGPoint) touchVector itemView: (UIView *) itemView {
    CGFloat touchDistance = VLDVectorLength(touchVector);
    
    CGPoint oldCenter = itemView.center;
    CGAffineTransform oldTransform = itemView.transform;
    
    [self updateItemView: itemView touchDistance: self.radius + VLDTouchDistanceAllowance];
    
    if(!CGRectContainsRect(self.bounds, itemView.frame)) {
        touchDistance = -touchDistance;
    }
    
    itemView.center = oldCenter;
    itemView.transform = oldTransform;
    
    return touchDistance;
}

- (void) updateItemViewsForGestureRecognizerUpdate:(UIGestureRecognizer*)gestureRecognizer {
    CGPoint touchPoint = [gestureRecognizer locationInView: self];
    CGPoint touchVector = {touchPoint.x - self.touchCenter.x, touchPoint.y - self.touchCenter.y};
    VLDContextSheetItemView *itemView = [self itemViewForTouchVector: touchVector];
    CGFloat touchDistance = [self signedTouchDistanceForTouchVector: touchVector itemView: itemView];
    
//    if(fabs(touchDistance) <= VLDTouchDistanceAllowance) {
//        self.centerView.center = CGPointMake(self.touchCenter.x + touchVector.x, self.touchCenter.y + touchVector.y);
//        [self setCenterViewHighlighted: YES];
//    }
//    else {
//        [self setCenterViewHighlighted: NO];
//
//        [UIView animateWithDuration: 0.4
//                              delay: 0
//             usingSpringWithDamping: 0.35
//              initialSpringVelocity: 7.5
//                            options: UIViewAnimationOptionBeginFromCurrentState
//                         animations: ^{
//                             self.centerView.center = self.touchCenter;
//
//                         }
//                         completion: nil];
//    }
    
    BOOL itemViewUpdated = NO;
    if(touchDistance > (self.radius + VLDTouchDistanceAllowance)) { // touch is getting too far from the item, so we have to unhighlight it
        if(itemView.isHighlighted) {
            [self.delegate contextSheet:self willUnhighlightItemView:itemView withGestureRecognizer:gestureRecognizer];
        }
        [itemView setHighlighted: NO animated: YES];
        
        [UIView animateWithDuration: 0.25
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.selectedItemTitleLabel.alpha = 0.;
                         }
                         completion: nil];
        
        // make the item back to its normal size
        [self updateItemView: itemView
               touchDistance: 0.0
                    animated: YES];
        itemViewUpdated = YES;
        
        //self.selectedItemView = nil;
        //
        //return;
    }
    
    // unhighlight selectedItemView
    if(itemView != self.selectedItemView) {
        if(self.selectedItemView && self.selectedItemView.isHighlighted) {
            [self.delegate contextSheet:self willUnhighlightItemView:self.selectedItemView withGestureRecognizer:gestureRecognizer];
        }
        [self.selectedItemView setHighlighted: NO animated: YES];
        
        [UIView animateWithDuration: 0.25
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.selectedItemTitleLabel.alpha = 0.;
                         }
                         completion: nil];
        
        [self updateItemView: self.selectedItemView
               touchDistance: 0.0
                    animated: YES];
        
        if(itemViewUpdated == NO) {
            [self updateItemView: itemView
                   touchDistance: touchDistance
                        animated: YES];
        }
        
        [self bringSubviewToFront: itemView];
    }
    else if(itemViewUpdated == NO) {
        [self updateItemView: itemView
               touchDistance: touchDistance
                    animated: YES];
    }
    
    // touch distance is in range to target the itemView
    if(itemView != nil && (fabs(touchDistance) > (self.radius-VLDTouchDistanceAllowance/2.) &&  fabs(touchDistance) < (self.radius+VLDTouchDistanceAllowance/2.))) {
        if(itemView.isHighlighted == NO) {
            [itemView setHighlighted: YES animated: YES];
            [self.delegate contextSheet:self didHighlightItemView:itemView withGestureRecognizer:gestureRecognizer];
            
            [UIView animateWithDuration: 0.25
                                  delay: 0.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 if(_displaysSelectedItemTitleLabelAtTop == YES) {
                                     self.selectedItemTitleLabel.alpha = 1.;
                                 }
                             }
                             completion: nil];
        }
    }
    
    self.selectedItemView = itemView;
}

- (VLDContextSheetItemView *) itemViewForTouchVector: (CGPoint) touchVector  {
    CGFloat maxCosOfAngle = -2;
    VLDContextSheetItemView *resultItemView = nil;
    
    for(int i = 0; i < self.itemViews.count; i++) {
        VLDContextSheetItemView *itemView = self.itemViews[i];
        CGPoint itemViewVector = {
            itemView.center.x - self.touchCenter.x,
            itemView.center.y - self.touchCenter.y
        };
        
        // math reminder: the dot product (produit scalaire in french) is equal to: cos(alpha) * ||v1->|| * ||v2->|| but is also equal to v1.x*v2.x+v1.y*v2.y. It helps know the angle (alpha) between 2 vectors. If cos(alpha) is close to 1, it means the 2 vectors have "very near" (points to the same direction).
        CGFloat cosOfAngle = VLDVectorDotProduct(itemViewVector, touchVector) / (VLDVectorLength(itemViewVector)*VLDVectorLength(touchVector));
        
        // so here we basically are looking for the itemViewVector that is the "most near" touchVector.
#define MINIMUM_COS_ANGLE_THRESHOLD 0.55
        if(cosOfAngle > maxCosOfAngle && cosOfAngle >= MINIMUM_COS_ANGLE_THRESHOLD) { // AH: i've added a "cosOfAngle > X filter" because I want the user to be pointing to the itemView quite correctly (itemView should only appear selected if it's correctly pointed to)
            maxCosOfAngle = cosOfAngle;
            resultItemView = itemView;
        }
    }

    return resultItemView;
}

- (void) end {
    [self.starterGestureRecognizer removeTarget: self action: @selector(gestureRecognizedStateObserver:)];
    // [self.starterGestureRecognizer removeTarget:nil action:NULL]; // can be usefull to remove all targets for any action
    
    [self closeItemsToCenterView];
}

-(void)endContextSheetByTap:(id)sender // user tapped in the background view, so he wants to cancel
{
    [self end];
    [self.delegate contextSheetDidCancel:self];
}

@end
