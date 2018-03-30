//
//  VLDContextSheetItem.h
//
//  Created by Vladimir Angelov on 2/9/14.
//  Copyright (c) 2014 Vladimir Angelov. All rights reserved.
//

@import UIKit;

@class VLDContextSheetItem;

@interface VLDContextSheetItemView : UIView

@property (strong, nonatomic) VLDContextSheetItem *item;
@property (readonly, nonatomic) BOOL isHighlighted;
@property (assign, nonatomic) BOOL titleLabelIsHidden; // NO by default. Always hide the label associated with the view. Incompatible with titleLabelIsAlwaysVisible==YES
@property (assign, nonatomic) BOOL titleLabelIsAlwaysVisible; // NO by default. Should the label be visible only when the item is highlighted (NO) or even when the item is non highlighted (YES). Incompatible with titleLabelIsHidden==YES

- (void) setHighlighted: (BOOL) highlighted animated: (BOOL) animated;

@end
