//
//  MyView.m
//  2.OpenGLBlankBlueWindow
//
//  Created by Vaibhav Zodge on 03/06/18.
//  Copyright © 2018 Vaibhav Zodge. All rights reserved.
//




#import "MyView.h"

@implementation MyView
{
    EAGLContext *eaglContext; //opengl context
    
    GLuint defaultFramebuffer; // frame buffer bind
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    id displayLink; //CADisplayLink *displayLink
    NSInteger animationFrameInterval;
    BOOL isAnimating;
}


-(id)initWithFrame:(CGRect)frame;
{
    
    self=[super initWithFrame:frame];
    
    if(self)
    {
        CAEAGLLayer *eaglLayer=(CAEAGLLayer *)super.layer; //super, give me  animation layer
        //super.layer  , this . Syntax called property Syntax
        // it can be written ad [super layer]
        // properties are in Objective C are by default get and set methods. We dont need to explicitly mention get but need to mention for set.
        //layer is nothing but pixelFormatAttribute
        
        eaglLayer.opaque=YES;  //[eaglLayer setOpaque:YES]
        eaglLayer.drawableProperties=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE],
                                      kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
        //retain backing means, do you want to retain the property, we say no ad we are animation
        //color format is 32  rgba8
        
        eaglContext=[[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3]; // create opengl context of version OpenGLES 3
        if(eaglContext==nil)
        {
            [self release];
            return(nil);
        }
        [EAGLContext setCurrentContext:eaglContext]; //set opengl context with current context
        //setCurrentContext is static method
        
        //************************ Frame buffer creation
        
        glGenFramebuffers(1,&defaultFramebuffer); // generate frame buffer
        glBindFramebuffer(GL_FRAMEBUFFER,defaultFramebuffer);
        //outer circle of buffer creation done, draw by sir
        
        // rendering api to store so created buffer called renderer buffer
        glGenRenderbuffers(1,&colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER,colorRenderbuffer);
        //inner circle draw by sir for color buffer (or depth buffer)
        
        //context what are you going to store in render buffer? GL_RENDERBUFFER
        //From where will you get data, fromDrawable
        [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        //attach colorRenderBuffer to a specific point (receptor). Where should I store color buffer (small circle) in frame buffer (big circle)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER,colorRenderbuffer);
        
        
        //*************** enable depth (or set depth buffer in frame buffer)
        GLint backingWidth;
        GLint backingHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH,&backingWidth);// get width of render buffer, it gives by cgl/agl
        glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_HEIGHT,&backingHeight);
        
        glGenRenderbuffers(1,&depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER,depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER,GL_DEPTH_COMPONENT16,backingWidth,backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,depthRenderbuffer);
        
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER)!=GL_FRAMEBUFFER_COMPLETE)
        {
            printf("Failed To Create Complete Framebuffer Object %x\n",glCheckFramebufferStatus(GL_FRAMEBUFFER));
            glDeleteFramebuffers(1,&defaultFramebuffer);
            glDeleteRenderbuffers(1,&colorRenderbuffer);
            glDeleteRenderbuffers(1,&depthRenderbuffer);
            [self release] ;
            return(nil);
        }
        
        printf("Renderer : %s | GL Version : %s | GLSL Version : %s\n",glGetString(GL_RENDERER),glGetString(GL_VERSION),glGetString(GL_SHADING_LANGUAGE_VERSION));
        
        // hard coded initializations
        isAnimating=NO;
        animationFrameInterval=60; // default since iOS 8.2, frame per second. Before 8.2 it was 30. It set to 60 because HD's frame rate is 60
        
        // *************************** shader program start
        
        
        
        
        //*****************************************************
        // clear color
        glClearColor(0.0f,0.0f,1.0f,1.0f); // blue
        
        // GESTURE RECOGNITION
        // Tap gesture code
        UITapGestureRecognizer *singleTapGestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onSingleTap:)];
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];
        [singleTapGestureRecognizer setNumberOfTouchesRequired:1]; // touch of 1 finger
        [singleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:singleTapGestureRecognizer];
        
        UITapGestureRecognizer *doubleTapGestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTap:)];
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
        [doubleTapGestureRecognizer setNumberOfTouchesRequired:1]; // touch of 1 finger
        [doubleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:doubleTapGestureRecognizer];
        
        // this will allow to differentiate between single tap and double tap
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        
        // swipe gesture
        UISwipeGestureRecognizer *swipeGestureRecognizer=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(onSwipe:)];
        [self addGestureRecognizer:swipeGestureRecognizer];
        
        // long-press gesture
        UILongPressGestureRecognizer *longPressGestureRecognizer=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(onLongPress:)];
        [self addGestureRecognizer:longPressGestureRecognizer];
    }
    return(self);
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

+(Class)layerClass
{
    // code
    return([CAEAGLLayer class]); //return class which indicates we want to do animation
    //core animation embedded Apple GL(opengl es)
    //this method will called by super class, and ultimately it called by Cocoa Touch and ultimately iOS
}

-(void)drawView:(id)sender
{
    [EAGLContext setCurrentContext:eaglContext];
    
    glBindFramebuffer(GL_FRAMEBUFFER,defaultFramebuffer);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    glBindRenderbuffer(GL_RENDERBUFFER,colorRenderbuffer);
    [eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)layoutSubviews  // equivalent to resize() function
{
    GLint width;
    GLint height;
    
    
    // after resize window, we need to remove frame buffer and create new frame buffer with new Width and height
    glBindRenderbuffer(GL_RENDERBUFFER,colorRenderbuffer);
    [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH,&width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_HEIGHT,&height);
    
    glGenRenderbuffers(1,&depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER,depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER,GL_DEPTH_COMPONENT16,width,height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,depthRenderbuffer);
    
    
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        printf("Failed To Create Complete Framebuffer Object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glViewport(0,0,width,height);

    // ortho or perspective code below
    
    [self drawView:nil]; // in webgl, Android,iphone resize does not call paint implicitly so we need to call it explicitly.
}

-(void)startAnimation // uset defined function. Need to declare thid in MyView.h
{
    if (!isAnimating)
    {
        displayLink=[NSClassFromString(@"CADisplayLink")displayLinkWithTarget:self selector:@selector(drawView:)];
        //NSClassFromString is like reflection, get class from literal name
        [displayLink setPreferredFramesPerSecond:animationFrameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];// register to message/run loop
        //tracking mode, event tracking mode, intrupts mode, and default mode
        isAnimating=YES;
    }
}

-(void)stopAnimation // uset defined function. Need to declare thid in MyView.h
{
    if(isAnimating)
    {
        [displayLink invalidate];// stop the display and take out of run loop
        displayLink=nil;
        
        isAnimating=NO;
    }
}

// to become first responder
-(BOOL)acceptsFirstResponder
{
    // code
    return(YES);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)onSingleTap:(UITapGestureRecognizer *)gr
{
    
}

-(void)onDoubleTap:(UITapGestureRecognizer *)gr
{
    
}

-(void)onSwipe:(UISwipeGestureRecognizer *)gr
{
    // code
    [self release];
    exit(0);
}

-(void)onLongPress:(UILongPressGestureRecognizer *)gr
{
    
}

- (void)dealloc
{
    // code
    if(depthRenderbuffer)
    {
        glDeleteRenderbuffers(1,&depthRenderbuffer);
        depthRenderbuffer=0;
    }
    
    if(colorRenderbuffer)
    {
        glDeleteRenderbuffers(1,&colorRenderbuffer);
        colorRenderbuffer=0;
    }
    
    if(defaultFramebuffer)
    {
        glDeleteFramebuffers(1,&defaultFramebuffer);
        defaultFramebuffer=0;
    }
    
    if([EAGLContext currentContext]==eaglContext)
    {
        [EAGLContext setCurrentContext:nil];
    }
    [eaglContext release];
    eaglContext=nil;
    
    [super dealloc];
}

@end
