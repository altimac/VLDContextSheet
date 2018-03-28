//
//  VLDContextSheet.h
//
//  Created by Vladimir Angelov on 2/7/14.
//  Copyright (c) 2014 Vladimir Angelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VLDContextSheet;
@class VLDContextSheetItem;
@class VLDContextSheetItemView;

@protocol VLDContextSheetDelegate <NSObject>

-(void)contextSheet:(VLDContextSheet *)contextSheet didHighlightItemView:(VLDContextSheetItemView*)itemView withGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;
-(void)contextSheet:(VLDContextSheet *)contextSheet willUnhighlightItemView:(VLDContextSheetItemView*)itemView withGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;
-(void)contextSheet:(VLDContextSheet *)contextSheet didSelectItemView:(VLDContextSheetItemView*)itemView;

-(void)contextSheetDidCancel:(VLDContextSheet *)contextSheet;


@end

@interface VLDContextSheet : UIView

@property (strong, nonatomic) UILabel *selectedItemTitleLabel; // displays the selected sheet item label
@property (strong, readonly, nonatomic) UIView *backgroundView;

@property (assign, nonatomic) NSInteger radius;
@property (assign, nonatomic) CGFloat rotation;
@property (assign, nonatomic) CGFloat rangeAngle;
@property (assign, nonatomic) CGSize itemSize;
@property (strong, nonatomic) NSArray *items;
@property (assign, nonatomic) id<VLDContextSheetDelegate> delegate;
@property (copy, nonatomic) void (^didSelectItemViewHandler)(VLDContextSheetItemView *itemView);

- (id) initWithItems: (NSArray *) items;
- (id) initWithItems: (NSArray *) items itemSize: (CGSize) itemSize;

- (void) startWithGestureRecognizer: (UIGestureRecognizer *) gestureRecognizer
                             inView: (UIView *) view;

- (void)pauseGestureRecognizerHandling; // does not stop gesture recognizer itself, but removes the VLDContextSheet as a target.
- (void)resumeGestureRecognizerHandling; // adds the VLDContextSheet as a target to the gesture recognizer.

- (void) end;

@end
