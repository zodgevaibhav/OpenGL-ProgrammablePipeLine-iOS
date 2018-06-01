//
//  MyView.m
//  Window
//
//  Created by Vaibhav Zodge on 01/06/18.
//  Copyright © 2018 Vaibhav Zodge. All rights reserved.
//

#import "MyView.h"

@implementation MyView

{
    NSString *centralText;
}

- (id)initWithFrame:(CGRect)frameRect{
    
    self=[super initWithFrame:frameRect];
    if(self)
    {
        [self setBackgroundColor:[UIColor whiteColor]];
        centralText=@"Hello OpenGL !!!";
        
        UITapGestureRecognizer *singleTapGestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onSingleTap:)];
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];
        [singleTapGestureRecognizer setNumberOfTouchesRequired:1]; // if touch by single fingure
        [singleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:singleTapGestureRecognizer];
        
        UITapGestureRecognizer *doubleTapGestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTap:)];
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
        [doubleTapGestureRecognizer setNumberOfTouchesRequired:1]; // if touch by single fingure
        [doubleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:doubleTapGestureRecognizer];

        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        UISwipeGestureRecognizer *swipeGestureRecognizer=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(onSwipe:)];
        [self addGestureRecognizer:swipeGestureRecognizer];

        UILongPressGestureRecognizer *longPressGestureRecognizer=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(onLongPress:)];
        [self addGestureRecognizer:longPressGestureRecognizer];

    }
    return(self);
}

- (void)drawRect:(CGRect)rect
{
    
    //for black backgroun
    UIColor *fillColor=[UIColor blackColor];
    [fillColor set];
    UIRectFill(rect);
    
    // Dictionary is a collecion of data consist of key-object pairs. Dictionaries can be mutable and immutable. Mutable dictionaries can be dynamically modified.
    
    //dictionaryWithObjectsAndKeys is method wich allow to set some entries initially
    NSDictionary *dictionaryForTextAttributes=[NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIFont fontWithName:@"Helvetica" size:24], NSFontAttributeName,
                                               [UIColor greenColor], NSForegroundColorAttributeName,
                                               nil];
    
    //CGSize is structure which describes a width and height
    CGSize textSize=[centralText sizeWithAttributes:dictionaryForTextAttributes];
    
    //CGPoint is structure which describes an X,Y points
    CGPoint point;
    point.x=(rect.size.width/2)-(textSize.width/2);
    point.y=(rect.size.height/2)-(textSize.height/2)+12;
    
    [centralText drawAtPoint:point withAttributes:dictionaryForTextAttributes];
}

// All the events will by default sent to window and not the view that we are working on. So we need to make responder chain and set responder
-(BOOL)acceptsFirstResponder
{
    return(YES);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   
}

-(void)onSingleTap:(UITapGestureRecognizer *)gr
{
    centralText = @"Single Tap...";
    [self setNeedsDisplay]; // on event we need to repaint the view, this methods request to repaint
}

-(void)onDoubleTap:(UITapGestureRecognizer *)gr
{
    centralText = @"Double Tap...";
    [self setNeedsDisplay]; // on event we need to repaint the view, this methods request to repaint
    
}

-(void)onSwipe:(UISwipeGestureRecognizer *)gr
{
    [self release];
    exit(0);
}

-(void)onLongPress:(UILongPressGestureRecognizer *)gr
{
    centralText = @"Long Press...";
    [self setNeedsDisplay]; // on event we need to repaint the view, this methods request to repaint
    
}

- (void)dealloc
{
    [super dealloc];
}

@end
