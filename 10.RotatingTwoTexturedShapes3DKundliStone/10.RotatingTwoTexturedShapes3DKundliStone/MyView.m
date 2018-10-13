//
//  MyView.m
//  3.TriangleOrtho
//
//  Created by Vaibhav Zodge on 07/06/18.
//  Copyright © 2018 Vaibhav Zodge. All rights reserved.
//

#import "MyView.h"

enum
{
    VVZ_ATTRIBUTE_VERTEX = 0,
    VVZ_ATTRIBUTE_COLOR,
    VVZ_ATTRIBUTE_NORMAL,
    VVZ_ATTRIBUTE_TEXTURE0,
};

@implementation MyView
{
    EAGLContext *eaglContext; //opengl context
    
    GLuint defaultFramebuffer; // frame buffer bind
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    id displayLink; //CADisplayLink *displayLink
    NSInteger animationFrameInterval;
    BOOL isAnimating;
    
    GLuint vertextShaderObject;
    GLuint fragmentShaderObject;
    GLuint shaderProgramObject;
    
    GLuint vao_triangle;
    GLuint vbo_triangle_position;
    GLuint vbo_triangle_tex_cords;

    GLuint vao_quad;
    GLuint vbo_quad_position;
    GLuint vbo_quad_tex_cords;
    
    GLuint triangle_texture;
    GLuint quad_texture;
    
    GLuint mvpUniform;
    GLuint texture_sample_uniform;
    
    GLfloat angleRotate;
    
    vmath::mat4 perspectiveProjectionMatrix;
}

-(GLuint)loadTextureFromBMPFile:(NSString *)texFileName :(NSString *)extension
{
    NSString *textureFileNameWithPath=[[NSBundle mainBundle]pathForResource:texFileName ofType:extension];
    
    UIImage *bmpImage=[[UIImage alloc]initWithContentsOfFile:textureFileNameWithPath];
    if (!bmpImage)
    {
        NSLog(@"can't find %@", textureFileNameWithPath);
        return(0);
    }
    
    CGImageRef cgImage=bmpImage.CGImage;
    
    int w = (int)CGImageGetWidth(cgImage);
    int h = (int)CGImageGetHeight(cgImage);
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    void* pixels = (void *)CFDataGetBytePtr(imageData);
    
    GLuint bmpTexture;
    glGenTextures(1, &bmpTexture);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1); // set 1 rather than default 4, for better performance
    glBindTexture(GL_TEXTURE_2D, bmpTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 w,
                 h,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 pixels);
    
    // Create mipmaps for this texture for better image quality
    glGenerateMipmap(GL_TEXTURE_2D);
    
    CFRelease(imageData);
    return(bmpTexture);
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
        
        
        //**************************************** Vertex shader **********************************************
        vertextShaderObject = glCreateShader(GL_VERTEX_SHADER);
        
        const GLchar *vertexShaderSourceCode =
        "#version 300 es"\
        "\n"\
        "in vec4 vPosition;"\
        "in vec2 vTextureCord;"\
        "out vec2 outTextureCord;"\
        "uniform mat4 u_mvp_matrix;"\
        "void main(void)" \
        "{" \
        "gl_Position=u_mvp_matrix * vPosition;"\
        "outTextureCord=vTextureCord;"\
        "}";
        
        glShaderSource(vertextShaderObject, 1, (const GLchar **)&vertexShaderSourceCode, NULL);
        
        //******************* Compile Vertex shader
        glCompileShader(vertextShaderObject);
        
        GLint iInfoLogLength = 0;
        GLint iShaderCompiledStatus = 0;
        char *szInfoLog = NULL;
        glGetShaderiv(vertextShaderObject, GL_COMPILE_STATUS, &iShaderCompiledStatus);
        if (iShaderCompiledStatus == GL_FALSE)
        {
            glGetShaderiv(vertextShaderObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
            if (iInfoLogLength > 0)
            {
                szInfoLog = (char *)malloc(iInfoLogLength);
                if (szInfoLog != NULL)
                {
                    GLsizei written;
                    glGetShaderInfoLog(vertextShaderObject, iInfoLogLength, &written, szInfoLog);
                    printf("***** Vertex Shader Compilation Log : %s\n", szInfoLog);
                    free(szInfoLog);
                    [self release];
                }
            }
        }
        
        //**************************************** Fragment shader **********************************************
        fragmentShaderObject = glCreateShader(GL_FRAGMENT_SHADER);
        
        const GLchar *fragmentShaderSourceCode =
        "#version 300 es"\
        "\n"\
        "precision highp float;" \
        "in vec2 outTextureCord;"\
        "uniform sampler2D u_texture_sampler;"
        "out vec4 FragColor;"\
        "void main(void)" \
        "{" \
        "vec3 tex=vec3(texture(u_texture_sampler,outTextureCord));"
        "FragColor=vec4(tex,1.0f);"\
        "}";
        
        glShaderSource(fragmentShaderObject, 1, (const GLchar **)&fragmentShaderSourceCode, NULL);
        
        //******************* Compile fragment shader
        
        glCompileShader(fragmentShaderObject);
        glGetShaderiv(fragmentShaderObject, GL_COMPILE_STATUS, &iShaderCompiledStatus);
        if (iShaderCompiledStatus == GL_FALSE)
        {
            glGetShaderiv(fragmentShaderObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
            if (iInfoLogLength > 0)
            {
                szInfoLog = (char *)malloc(iInfoLogLength);
                if (szInfoLog != NULL)
                {
                    GLsizei written;
                    glGetShaderInfoLog(fragmentShaderObject, iInfoLogLength, &written, szInfoLog);
                    printf("***** Fragment Shader Compilation Log : %s\n", szInfoLog);
                    free(szInfoLog);
                    
                }
            }
        }
        
        //**************************************** Shader program attachment **********************************************
        // Code from sir
        
        shaderProgramObject = glCreateProgram();
        
        // attach vertex shader to shader program
        glAttachShader(shaderProgramObject, vertextShaderObject);
        
        // attach fragment shader to shader program
        glAttachShader(shaderProgramObject, fragmentShaderObject);
        
        glBindAttribLocation(shaderProgramObject, VVZ_ATTRIBUTE_VERTEX, "vPosition");
        glBindAttribLocation(shaderProgramObject, VVZ_ATTRIBUTE_TEXTURE0, "vTextureCord");


        
        //**************************************** Link Shader program **********************************************
        glLinkProgram(shaderProgramObject);
        GLint iShaderProgramLinkStatus = 0;
        glGetProgramiv(shaderProgramObject, GL_LINK_STATUS, &iShaderProgramLinkStatus);
        if (iShaderProgramLinkStatus == GL_FALSE)
        {
            glGetProgramiv(shaderProgramObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
            if (iInfoLogLength>0)
            {
                szInfoLog = (char *)malloc(iInfoLogLength);
                if (szInfoLog != NULL)
                {
                    GLsizei written;
                    glGetProgramInfoLog(shaderProgramObject, iInfoLogLength, &written, szInfoLog);
                    printf("Shader Program Link Log : %s\n", szInfoLog);
                    free(szInfoLog);
                    [self release];
                }
            }
        }
        
        //**************************************** END Link Shader program **********************************************
        
        mvpUniform = glGetUniformLocation(shaderProgramObject,"u_mvp_matrix");
        texture_sample_uniform=glGetUniformLocation(shaderProgramObject, "u_texture_sampler");
        
        triangle_texture=[self loadTextureFromBMPFile:@"Stone" :@"bmp"];
        quad_texture=[self loadTextureFromBMPFile:@"Vijay_Kundali" :@"bmp"];
        
        //**************************************** Triangle **********************************************

        const GLfloat triangleVertices[] =
        {
            0, 1, 0,    // front-top
            -1, -1, 1,  // front-left
            1, -1, 1,   // front-right
            
            0, 1, 0,    // right-top
            1, -1, 1,   // right-left
            1, -1, -1,  // right-right
            
            0, 1, 0,    // back-top
            1, -1, -1,  // back-left
            -1, -1, -1, // back-right
            
            0, 1, 0,    // left-top
            -1, -1, -1, // left-left
            -1, -1, 1   // left-right

        };
        
        glGenVertexArrays(1, &vao_triangle);
        glBindVertexArray(vao_triangle);
        
        glGenBuffers(1, &vbo_triangle_position);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_triangle_position);
        glBufferData(GL_ARRAY_BUFFER, sizeof(triangleVertices), triangleVertices, GL_STATIC_DRAW);
        
        glVertexAttribPointer(VVZ_ATTRIBUTE_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        
        glEnableVertexAttribArray(VVZ_ATTRIBUTE_VERTEX);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);


        const GLfloat triangleTexCords[] =
        {
            0.5f, 1.0f, // front-top
            0.0f, 0.0f, // front-left
            1.0f, 0.0f, // front-right
            
            0.5f, 1.0f, // right-top
            1.0f, 0.0f, // right-left
            0.0f, 0.0f, // right-right
            
            0.5f, 1.0f, // back-top
            1.0f, 0.0f, // back-left
            0.0f, 0.0f, // back-right
            
            0.5f, 1.0f, // left-top
            0.0f, 0.0f, // left-left
            1.0f, 0.0f, // left-right

        };
        
        glBindVertexArray(vao_triangle);
        
        glGenBuffers(1, &vbo_triangle_tex_cords);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_triangle_tex_cords);
        glBufferData(GL_ARRAY_BUFFER, sizeof(triangleTexCords), triangleTexCords, GL_STATIC_DRAW);
        
        glVertexAttribPointer(VVZ_ATTRIBUTE_TEXTURE0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
        
        glEnableVertexAttribArray(VVZ_ATTRIBUTE_TEXTURE0);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        //*************************************************
        
        //**************************************** Triangle **********************************************
        
        const GLfloat quadVertices[] =
        {
            1.0f, 1.0f,-1.0f,  // top-right of top
            -1.0f, 1.0f,-1.0f, // top-left of top
            -1.0f, 1.0f, 1.0f, // bottom-left of top
            1.0f, 1.0f, 1.0f,  // bottom-right of top
            
            // bottom surface
            1.0f,-1.0f, 1.0f,  // top-right of bottom
            -1.0f,-1.0f, 1.0f, // top-left of bottom
            -1.0f,-1.0f,-1.0f, // bottom-left of bottom
            1.0f,-1.0f,-1.0f,  // bottom-right of bottom
            
            // front surface
            1.0f, 1.0f, 1.0f,  // top-right of front
            -1.0f, 1.0f, 1.0f, // top-left of front
            -1.0f,-1.0f, 1.0f, // bottom-left of front
            1.0f,-1.0f, 1.0f,  // bottom-right of front
            
            // back surface
            1.0f,-1.0f,-1.0f,  // top-right of back
            -1.0f,-1.0f,-1.0f, // top-left of back
            -1.0f, 1.0f,-1.0f, // bottom-left of back
            1.0f, 1.0f,-1.0f,  // bottom-right of back
            
            // left surface
            -1.0f, 1.0f, 1.0f, // top-right of left
            -1.0f, 1.0f,-1.0f, // top-left of left
            -1.0f,-1.0f,-1.0f, // bottom-left of left
            -1.0f,-1.0f, 1.0f, // bottom-right of left
            
            // right surface
            1.0f, 1.0f,-1.0f,  // top-right of right
            1.0f, 1.0f, 1.0f,  // top-left of right
            1.0f,-1.0f, 1.0f,  // bottom-left of right
            1.0f,-1.0f,-1.0f,  // bottom-right of right
        };
        
        glGenVertexArrays(1, &vao_quad);
        glBindVertexArray(vao_quad);
        
        glGenBuffers(1, &vbo_quad_position);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_quad_position);
        glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices), quadVertices, GL_STATIC_DRAW);
        
        glVertexAttribPointer(VVZ_ATTRIBUTE_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        
        glEnableVertexAttribArray(VVZ_ATTRIBUTE_VERTEX);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        
        const GLfloat quadTexCords[] =
        {
            0.0f,0.0f,
            1.0f,0.0f,
            1.0f,1.0f,
            0.0f,1.0f,
            
            0.0f,0.0f,
            1.0f,0.0f,
            1.0f,1.0f,
            0.0f,1.0f,
            
            0.0f,0.0f,
            1.0f,0.0f,
            1.0f,1.0f,
            0.0f,1.0f,
            
            0.0f,0.0f,
            1.0f,0.0f,
            1.0f,1.0f,
            0.0f,1.0f,
            
            0.0f,0.0f,
            1.0f,0.0f,
            1.0f,1.0f,
            0.0f,1.0f,
            
            0.0f,0.0f,
            1.0f,0.0f,
            1.0f,1.0f,
            0.0f,1.0f,

        };
        
        glBindVertexArray(vao_quad);
        
        glGenBuffers(1, &vbo_quad_tex_cords);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_quad_tex_cords);
        glBufferData(GL_ARRAY_BUFFER, sizeof(quadTexCords), quadTexCords, GL_STATIC_DRAW);
        
        glVertexAttribPointer(VVZ_ATTRIBUTE_TEXTURE0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
        
        glEnableVertexAttribArray(VVZ_ATTRIBUTE_TEXTURE0);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        
        //*************************************************
        
        
        //glShadeModel(GL_SMOOTH);
        
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
        // glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
        //glEnable(GL_CULL_FACE);
        
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        
        perspectiveProjectionMatrix = vmath::mat4::identity();

        
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
    [self updateAngle];
    
    [EAGLContext setCurrentContext:eaglContext];
    
    glBindFramebuffer(GL_FRAMEBUFFER,defaultFramebuffer);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    glUseProgram(shaderProgramObject);
    
    vmath::mat4 modelViewMatrix = vmath::mat4::identity();
    vmath::mat4 modelViewProjectionMatrix = vmath::mat4::identity();
    vmath::mat4 rotationMatric = vmath::mat4::identity();

    
    modelViewMatrix=vmath::translate(-1.5f, 0.0f, -5.0f);
    rotationMatric=vmath::rotate(angleRotate, 0.0f, 1.0f,0.0f);
    modelViewMatrix=modelViewMatrix*rotationMatric;
    
    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix;
    
    glUniformMatrix4fv(mvpUniform, 1, GL_FALSE, modelViewProjectionMatrix);
    
    glBindVertexArray(vao_triangle);
    glBindTexture(GL_TEXTURE_2D, triangle_texture);
    
    glDrawArrays(GL_TRIANGLES, 0,12);
    glBindVertexArray(0);

    
    modelViewMatrix = vmath::mat4::identity();
    modelViewProjectionMatrix = vmath::mat4::identity();
    rotationMatric=vmath::mat4::identity();
    
    modelViewMatrix=vmath::translate(1.5f, 0.0f, -5.0f);
    
    rotationMatric=vmath::rotate(angleRotate, 1.0f, 0.0f,0.0f);
    modelViewMatrix=modelViewMatrix*rotationMatric;
    
    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix;
    
    glUniformMatrix4fv(mvpUniform, 1, GL_FALSE, modelViewProjectionMatrix);
    
    glBindVertexArray(vao_quad);
    glBindTexture(GL_TEXTURE_2D, quad_texture);
    
    glDrawArrays(GL_TRIANGLE_FAN,0,4);
    glDrawArrays(GL_TRIANGLE_FAN,4,4);
    glDrawArrays(GL_TRIANGLE_FAN,8,4);
    
    glDrawArrays(GL_TRIANGLE_FAN,12,4);
    glDrawArrays(GL_TRIANGLE_FAN,16,4);
    glDrawArrays(GL_TRIANGLE_FAN,20,4);
    
    
    glBindVertexArray(0);
    glUseProgram(0);
    
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
    
    GLfloat fWidth = (GLfloat)width;
    GLfloat fHeight = (GLfloat)height;
    
    perspectiveProjectionMatrix = vmath::perspective(45, fWidth/fHeight, 0.1f, 100.0f);

//    if (width <= height)
//        orthoGraphicProjectionMatrix = vmath::ortho(-100.0f, 100.0f, (-100.0f * (fHeight / fWidth)), (100.0f * (fHeight / fWidth)), -100.0f, 100.0f);
//    else
//        orthoGraphicProjectionMatrix = vmath::ortho((-100.0f * (fWidth / fHeight)), (100.0f * (fWidth / fHeight)), -100.0f, 100.0f, -100.0f, 100.0f);
//
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        printf("Failed To Create Complete Framebuffer Object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
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

-(void)updateAngle
{
    angleRotate=angleRotate+1.0f;
    if(angleRotate>360.0f)
        angleRotate=0.0f;
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
